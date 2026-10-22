import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(contactsProvider).value?.length ?? 0;
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
            _Toggle(title: '수신 전화 식별', sub: '3단계에서 켜져요 · 현재 $total명', value: false, enabled: false),
            const _Toggle(title: '문자 발신자 식별', sub: 'iOS에서는 지원되지 않아요', value: false, enabled: false, last: true),
          ]),
          const SizedBox(height: 22),
          _Group(title: '데이터', children: [
            _Action(icon: Icons.download_rounded, title: '내려받기', sub: '명함 이미지 포함 · zip 파일', onTap: () => _soon(context)),
            _Action(icon: Icons.upload_rounded, title: '가져오기', sub: '다른 기기에서 내려받은 파일 일괄 등록', onTap: () => _soon(context)),
            const _Toggle(title: '명함 원본 이미지 보관', sub: '끄면 텍스트만 저장', value: true, enabled: false, last: true),
          ]),
          const SizedBox(height: 22),
          _Group(title: '정보', children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(14)),
                  child: const _MiniIcon(),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('BizKeep 0.1.0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.ink)),
                    SizedBox(height: 2),
                    Text('명함을 찍어두면 바로 찾고 바로 거는 업무 연락처', style: TextStyle(fontSize: 13, color: C.inkMuted)),
                  ]),
                ),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  void _soon(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('4단계에서 추가돼요'), behavior: SnackBarBehavior.floating));
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
  const _Toggle({required this.title, required this.sub, required this.value, this.enabled = true, this.last = false});
  final String title;
  final String sub;
  final bool value;
  final bool enabled;
  final bool last;
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
          Switch.adaptive(value: value, onChanged: enabled ? (_) {} : null, activeTrackColor: C.call),
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
  Widget build(BuildContext context) => Stack(children: [
        for (final (i, color) in [C.accent, const Color(0xFF7FA3FF), Colors.white].indexed)
          Positioned(
            left: 11.0 - i * 2.5, top: 11.0 + i * 5,
            child: Transform.rotate(
              angle: -0.1,
              child: Container(width: 26, height: 17, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            ),
          ),
      ]);
}
