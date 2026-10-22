import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// 검출된 명함 사각형 (정규화 0~1, Vision 좌표계: 좌하단 원점).
class CardQuad {
  final List<double> pts; // x0,y0,x1,y1,x2,y2,x3,y3 (TL,TR,BR,BL)
  final double confidence;
  const CardQuad(this.pts, this.confidence);

  double get cx => (pts[0] + pts[2] + pts[4] + pts[6]) / 4;
  double get cy => (pts[1] + pts[3] + pts[5] + pts[7]) / 4;
  double get w => ((pts[2] - pts[0]).abs() + (pts[4] - pts[6]).abs()) / 2;
  double get h => ((pts[7] - pts[1]).abs() + (pts[5] - pts[3]).abs()) / 2;

  bool similar(CardQuad o, {double tol = 0.03}) =>
      (cx - o.cx).abs() < tol && (cy - o.cy).abs() < tol && (w - o.w).abs() < tol * 1.5 && (h - o.h).abs() < tol * 1.5;
}

/// 플랫폼 비전 엔진. iOS: Apple Vision (ios/Runner/VisionPlugin.swift). Android: 2단계-B에서 ML Kit Kotlin 채널.
abstract final class Vision {
  static const _ch = MethodChannel('bizkeep/vision');
  static bool get supported => Platform.isIOS;

  /// 카메라 프레임에서 명함 사각형 검출. 없으면 null.
  static Future<CardQuad?> detectRect(CameraImage img) async {
    if (!supported || img.planes.isEmpty) return null;
    final p = img.planes.first;
    final r = await _ch.invokeMethod<List<Object?>>('detectRect', {
      'bytes': p.bytes, 'width': img.width, 'height': img.height, 'bytesPerRow': p.bytesPerRow,
    });
    if (r == null || r.length < 9) return null;
    final d = r.map((e) => (e as num).toDouble()).toList();
    return CardQuad(d.sublist(0, 8), d[8]);
  }

  /// 촬영 사진을 명함 영역으로 원근 보정 크롭 (같은 경로 덮어씀). 실패 시 null.
  static Future<String?> cropCard(String path, CardQuad? q) async {
    if (!supported) return null;
    return _ch.invokeMethod<String>('cropCard', {'path': path, 'quad': q?.pts});
  }

  static Future<String> recognizeText(String path) async {
    if (!supported) return '';
    return (await _ch.invokeMethod<String>('recognizeText', {'path': path})) ?? '';
  }
}

/// (Android 전용) 텍스트 블록 안정성으로 자동 촬영 — 2단계-B 에서 ML Kit 채널로 교체.
class TextStability {
  int _stable = 0;
  Uint8List? _lastSig;
  bool push(Uint8List? sig) {
    if (sig == null) { _stable = 0; _lastSig = null; return false; }
    if (_lastSig != null && _lastSig!.length == sig.length) {
      _stable++;
    } else {
      _stable = 0;
    }
    _lastSig = sig;
    return _stable >= 3;
  }
}
