import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/actions.dart';
import '../../core/calldir.dart';
import '../../data/backup.dart';
import '../list/widgets.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(contactsProvider).value?.length ?? 0;
    final status = ref.watch(callDirStatusProvider).value ?? 'unknown';
    final enabled = status == 'enabled';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.bg, surfaceTintColor: Colors.transparent, elevation: 0, centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: C.ink, size: 20), tooltip: '뒤로'),
        title: const Text('설정', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: C.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _Group(title: '알림', children: [
            _Toggle(
              title: '수신 전화 식별',
              sub: enabled ? '켜짐 · $total명의 번호에 이름 표시' : (status == 'unsupported' ? '이 기기에선 지원되지 않아요' : '설정 > 전화 > 통화 차단 및 발신자 확인에서 켜 주세요'),
              value: enabled,
              enabled: status != 'unsupported',
              onChanged: (_) async {
                await CallDir.openSettings();
                ref.invalidate(callDirStatusProvider);
              },
            ),
            const _Toggle(title: '문자 발신자 식별', sub: 'iOS에서는 지원되지 않아요', value: false, enabled: false, last: true),
          ]),
          const SizedBox(height: 22),
          _Group(title: '데이터', children: [
            _Action(icon: Icons.download_rounded, title: '내려받기', sub: '명함 $total명 · 사진·CSV 포함 zip', onTap: () => _export(context, ref)),
            _Action(icon: Icons.upload_rounded, title: '가져오기', sub: '내려받은 zip 선택 · 같은 명함은 최신 쪽 유지', onTap: () => _import(context, ref)),
            const _Toggle(title: '명함 원본 이미지 보관', sub: '끄면 텍스트만 저장', value: true, enabled: false, last: true),
          ]),
          const SizedBox(height: 22),
          _Group(title: '정보', children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.line, width: 1),
                  ),
                  child: const _MiniIcon(),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('BizKeep 0.1.0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.ink)),
                    SizedBox(height: 2),
                    Text('명함을 간편하게 저장하고 관리하자 - BTS', style: TextStyle(fontSize: 13, color: C.inkMuted)),
                  ]),
                ),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : (box.localToGlobal(Offset.zero) & box.size);
    _busy(context, '백업 파일 만드는 중…');
    try {
      final file = await Backup.export(ref.read(dbProvider));
      if (!context.mounted) return;
      Navigator.pop(context); // busy
      await Act.shareFile(file.path, origin: origin);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      Toast.show(context, '백업에 실패했어요', icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    final path = picked.isEmpty ? null : picked.first.path;
    if (path == null || !context.mounted) return;
    _busy(context, '가져오는 중…');
    final r = await Backup.import(ref.read(dbProvider), ref.read(repoProvider), path);
    if (!context.mounted) return;
    Navigator.pop(context);
    if (r.error != null) {
      Toast.show(context, r.error!, icon: Icons.error_outline_rounded);
    } else {
      Toast.show(context, '추가 ${r.added} · 갱신 ${r.updated} · 건너뜀 ${r.skipped}');
    }
  }

  void _busy(BuildContext context, String text) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: C.ink)),
          ]),
        ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.inkMuted))),
        Container(
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(R.box), boxShadow: rowShadow),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ]);
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.title, required this.sub, required this.value, this.enabled = true, this.last = false, this.onChanged});
  final String title;
  final String sub;
  final bool value;
  final bool enabled;
  final bool last;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: C.ink)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 13, color: C.inkMuted)),
            ]),
          ),
          Switch.adaptive(value: value, onChanged: enabled ? (onChanged ?? (_) {}) : null, activeTrackColor: C.call),
        ]),
      );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.title, required this.sub, required this.onTap});
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          height: 60, padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
          child: Row(children: [
            Icon(icon, color: C.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: C.ink)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 13, color: C.inkMuted)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: C.inkFaint),
          ]),
        ),
      );
}

/// 설정 화면용 미니 앱 아이콘 (시안 B — 명함 스택)
class _MiniIcon extends StatelessWidget {
  const _MiniIcon();
  @override
  Widget build(BuildContext context) => const CustomPaint(size: Size(48, 48), painter: _MiniIconPainter());
}

/// 앱 아이콘(뷰파인더 변주)의 축소판: 네이비 브래킷 + 파란 명함.
class _MiniIconPainter extends CustomPainter {
  const _MiniIconPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 180; // 아이콘 원본 좌표계(180) → 위젯
    final stroke = Paint()
      ..color = C.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * k
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(34 * k, 64 * k)..lineTo(34 * k, 48 * k)..arcToPoint(Offset(48 * k, 34 * k), radius: Radius.circular(14 * k))..lineTo(64 * k, 34 * k)
      ..moveTo(116 * k, 34 * k)..lineTo(132 * k, 34 * k)..arcToPoint(Offset(146 * k, 48 * k), radius: Radius.circular(14 * k))..lineTo(146 * k, 64 * k)
      ..moveTo(146 * k, 116 * k)..lineTo(146 * k, 132 * k)..arcToPoint(Offset(132 * k, 146 * k), radius: Radius.circular(14 * k))..lineTo(116 * k, 146 * k)
      ..moveTo(64 * k, 146 * k)..lineTo(48 * k, 146 * k)..arcToPoint(Offset(34 * k, 132 * k), radius: Radius.circular(14 * k))..lineTo(34 * k, 116 * k);
    canvas.drawPath(path, stroke);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(52 * k, 66 * k, 76 * k, 48 * k), Radius.circular(8 * k)), Paint()..color = C.accent);
    void line(double x, double y, double w, double h, double a) =>
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x * k, y * k, w * k, h * k), Radius.circular(h * k / 2)), Paint()..color = Colors.white.withValues(alpha: a));
    line(62, 76, 16, 6, 0.7);
    line(62, 88, 44, 5, 1);
    line(62, 99, 30, 4, 0.5);
  }

  @override
  bool shouldRepaint(_MiniIconPainter old) => false;
}
