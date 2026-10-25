import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/image_paths.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/ocr_parser.dart';
import 'image_io.dart';
import 'vision.dart';

/// 명함 촬영. 프레임 안에서 명함 윤곽(사각형)이 검출되고 0.75초 안정되면 셔터 없이 자동 촬영.
/// 촬영 → 원근 보정 크롭 → OCR → 즉시 저장 → 상세 (확인 단계 없음). 수동 셔터는 백업.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});
  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> with WidgetsBindingObserver {
  CameraController? _cam;
  bool _busy = false;
  bool _capturing = false;
  bool _flash = false;
  String? _error;

  CardQuad? _last;
  int _stable = 0;
  static const _needStable = 3;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  /// 안내 프레임 비율. 한국 90×50(1.8)·86×54(1.6)·일본 91×55(1.65) 모두 들어오게 1.7. 실제 크롭은 Vision 검출 사각형 기준.
  static const guideAspect = 1.7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    if (_initializing) return;
    _initializing = true;
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (mounted) setState(() => _error = '이 기기엔 카메라가 없어요\n(시뮬레이터에선 직접 입력을 써 주세요)');
        return;
      }
      final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      final cam = CameraController(back, ResolutionPreset.high, enableAudio: false,
          imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21);
      await cam.initialize();
      await cam.setFlashMode(FlashMode.off);
      await cam.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted) { cam.dispose(); return; }
      setState(() => _cam = cam);
      if (Vision.supported) await cam.startImageStream(_onFrame);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.code == 'CameraAccessDenied'
          ? '카메라 권한이 필요해요.\n설정 → BizKeep → 카메라를 켜 주세요.'
          : '카메라를 열 수 없어요 (${e.code})');
    } catch (_) {
      if (mounted) setState(() => _error = '카메라를 열 수 없어요');
    } finally {
      _initializing = false;
    }
  }

  bool _initializing = false;

  /// 홈으로 나가면(paused) 카메라를 완전히 놓고, 돌아오면(resumed) 새로 연다.
  /// inactive(제어센터·알림 등 잠깐 가려짐)에서는 건드리지 않는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final cam = _cam;
      _cam = null;
      _last = null;
      _stable = 0;
      if (mounted) setState(() {});
      cam?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cam == null && !_initializing && !_capturing) _init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cam?.dispose();
    super.dispose();
  }

  // ---- 실시간: 4fps 사각형 검출, 3프레임 연속 안정 → 자동 촬영 ----
  Future<void> _onFrame(CameraImage img) async {
    if (_busy || _capturing) return;
    final now = DateTime.now();
    if (now.difference(_lastFrame).inMilliseconds < 250) return;
    _lastFrame = now;
    _busy = true;
    try {
      final q = await Vision.detectRect(img);
      if (q != null && _last != null && q.similar(_last!)) {
        _stable++;
      } else {
        _stable = 0;
      }
      _last = q;
      if (mounted) setState(() {});
      if (q != null && _stable >= _needStable) {
        _stable = 0;
        unawaited(_capture(auto: true));
      }
    } catch (_) {
      // 프레임 하나 실패는 무시
    } finally {
      _busy = false;
    }
  }

  // ---- 촬영 → 크롭 → OCR → 즉시 저장 ----
  Future<void> _capture({required bool auto}) async {
    final cam = _cam;
    if (cam == null || _capturing || !cam.value.isInitialized) return;
    _capturing = true;
    final quad = _last;
    setState(() => _flash = true);
    HapticFeedback.mediumImpact();
    try {
      if (cam.value.isStreamingImages) await cam.stopImageStream();
      final shot = await cam.takePicture();
      final id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);

      // 1) 원본을 cards/ 로 옮기고 네이티브 원근 보정 크롭 (실패 시 가이드 영역 크롭)
      final dir = await ImageIo.cardsDir();
      final front = '${dir.path}/${id}_front.jpg';
      await File(shot.path).copy(front);
      final cropped = await Vision.cropCard(front, quad);
      SavedImages saved;
      if (cropped != null) {
        saved = await ImageIo.makeThumb(front, '${dir.path}/${id}_thumb.jpg');
      } else {
        if (!mounted) return;
        final rect = _guideRelativeRect(context, cam);
        saved = await ImageIo.processAndSave(await File(front).readAsBytes(), rect, id);
      }

      // 2) OCR (네이티브, ~0.3s)
      final ocrLines = await Vision.recognizeLines(saved.front);
      final ocrText = OcrLine.mergeRows(ocrLines).map((l) => l.text).join('\n');
      final parsed = const OcrParser().parseLines(ocrLines);

      // 3) 즉시 저장
      final c = await ref.read(repoProvider).create(
            name: parsed.name, company: parsed.company, department: parsed.department, title: parsed.title,
            phoneMobile: parsed.phoneMobile, phoneOffice: parsed.phoneOffice, fax: parsed.fax, email: parsed.email,
            address: parsed.address, website: parsed.website,
            imageFront: ImagePaths.toStored(saved.front), thumb: ImagePaths.toStored(saved.thumb), ocrRaw: ocrText, source: 'camera',
            lowConfidence: parsed.lowConfidence.toList(),
          );
      HapticFeedback.heavyImpact();
      if (mounted) Navigator.pop(context, c.id);
    } catch (e) {
      if (!mounted) return;
      setState(() { _flash = false; _capturing = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('촬영에 실패했어요. 다시 맞춰 주세요.')));
      if (Vision.supported && !cam.value.isStreamingImages) await cam.startImageStream(_onFrame);
    }
  }

  Rect _guideRelativeRect(BuildContext context, CameraController cam) {
    final screen = MediaQuery.sizeOf(context);
    final camAspect = cam.value.aspectRatio;
    final previewW = screen.width, previewH = previewW * camAspect;
    final scale = math.max(screen.width / previewW, screen.height / previewH);
    final shownW = previewW * scale, shownH = previewH * scale;
    final offX = (shownW - screen.width) / 2, offY = (shownH - screen.height) / 2;
    final g = _guideRect(screen);
    return Rect.fromLTRB(((g.left + offX) / shownW).clamp(0, 1), ((g.top + offY) / shownH).clamp(0, 1),
        ((g.right + offX) / shownW).clamp(0, 1), ((g.bottom + offY) / shownH).clamp(0, 1));
  }

  static Rect _guideRect(Size screen) {
    final w = screen.width - 40;
    final h = w / guideAspect;
    return Rect.fromLTWH(20, screen.height * 0.36 - h / 2, w, h);
  }

  @override
  Widget build(BuildContext context) {
    final cam = _cam;
    final screen = MediaQuery.sizeOf(context);
    final guide = _guideRect(screen);
    final pad = MediaQuery.paddingOf(context);
    final found = _last != null;
    final locking = found && _stable > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: Stack(fit: StackFit.expand, children: [
        if (cam != null && cam.value.isInitialized)
          FittedBox(fit: BoxFit.cover, child: SizedBox(width: screen.width, height: screen.width * cam.value.aspectRatio, child: CameraPreview(cam))),
        CustomPaint(painter: _MaskPainter(guide, color: Colors.black.withValues(alpha: 0.55))),
        Positioned.fromRect(rect: guide, child: _Corners(color: locking ? C.accent : (found ? Colors.white : Colors.white60), thick: locking)),
        if (_flash) Container(color: Colors.white.withValues(alpha: 0.85)),
        Positioned(
          top: pad.top + 6, left: 12, right: 12,
          child: Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white), tooltip: '닫기')]),
        ),
        Positioned(
          top: guide.bottom + 22, left: 20, right: 20,
          child: Column(children: [
            Text(
              _error ?? (_capturing ? '저장하는 중…' : locking ? '그대로 계세요' : found ? '조금만 더 맞춰 주세요' : '명함을 프레임 안에 놓아 주세요'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 6),
            if (_error == null)
              Text(Vision.supported ? '맞추면 자동으로 찍혀요' : '아래 버튼으로 찍어 주세요', style: const TextStyle(color: Color(0xFF9AA0AA), fontSize: 13)),
          ]),
        ),
        Positioned(
          left: 0, right: 0, bottom: pad.bottom + 28,
          child: Center(
            child: Semantics(
              button: true, label: '직접 촬영',
              child: GestureDetector(
                onTap: (_capturing || cam == null) ? null : () => _capture(auto: false),
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                  child: Center(child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: cam == null ? Colors.white38 : Colors.white))),
                ),
              ),
            ),
          ),
        ),
        if (_capturing)
          const Positioned(left: 0, right: 0, bottom: 120, child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))),
      ]),
    );
  }
}

class _MaskPainter extends CustomPainter {
  _MaskPainter(this.hole, {required this.color});
  final Rect hole;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(14)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = color);
  }
  @override
  bool shouldRepaint(_MaskPainter old) => old.hole != hole || old.color != color;
}

class _Corners extends StatelessWidget {
  const _Corners({required this.color, required this.thick});
  final Color color;
  final bool thick;
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _CornerPainter(color, thick ? 4 : 3));
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.color, this.stroke);
  final Color color;
  final double stroke;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = color..strokeWidth = stroke..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    const len = 26.0, r = 14.0;
    void corner(Offset o, double sx, double sy) {
      canvas.drawLine(o + Offset(sx * r, 0), o + Offset(sx * len, 0), p);
      canvas.drawLine(o + Offset(0, sy * r), o + Offset(0, sy * len), p);
      canvas.drawArc(Rect.fromCenter(center: o + Offset(sx * r, sy * r), width: 2 * r, height: 2 * r),
          sx > 0 ? (sy > 0 ? math.pi : math.pi / 2) : (sy > 0 ? -math.pi / 2 : 0), math.pi / 2, false, p);
    }
    corner(Offset.zero, 1, 1);
    corner(Offset(s.width, 0), -1, 1);
    corner(Offset(0, s.height), 1, -1);
    corner(Offset(s.width, s.height), -1, -1);
  }
  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color || old.stroke != stroke;
}
