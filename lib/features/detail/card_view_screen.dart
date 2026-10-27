import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/actions.dart';
import '../../core/image_paths.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/contact_repo.dart';
import '../list/widgets.dart';

/// 명함 이미지 전체 화면. 핀치 줌, 앞/뒷면 스와이프.
class CardViewScreen extends ConsumerStatefulWidget {
  const CardViewScreen({super.key, required this.contactId});
  final String contactId;
  @override
  ConsumerState<CardViewScreen> createState() => _CardViewScreenState();
}

class _CardViewScreenState extends ConsumerState<CardViewScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(contactsProvider).value?.where((x) => x.id == widget.contactId).firstOrNull ??
        ref.watch(myCardsProvider).value?.where((x) => x.id == widget.contactId).firstOrNull;
    if (c == null) return const Scaffold(backgroundColor: Color(0xFF0B0C10));
    final images = [c.imageFront, c.imageBack].whereType<String>().map(ImagePaths.resolve).toList();
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: Stack(children: [
        Positioned.fill(
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1, maxScale: 4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    // 꾹 누르면 바로 공유 (내 명함과 동일)
                    onLongPress: () => _share(context, images),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(File(images[i]), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: pad.top + 6, left: 12, right: 12,
          child: Row(children: [
            _GlassIcon(icon: Icons.close_rounded, label: '닫기', onTap: () => Navigator.pop(context)),
            Expanded(
              child: Column(children: [
                Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                Text([c.company, c.title].where((s) => s.isNotEmpty).join(' · '), style: const TextStyle(color: Color(0xFF9AA0AA), fontSize: 12)),
              ]),
            ),
            _GlassIcon(icon: Icons.download_rounded, label: '사진에 저장', onTap: () => _save(context, images[_page.clamp(0, images.length - 1)])),
            const SizedBox(width: 8),
            _GlassIcon(icon: Icons.ios_share_rounded, label: '공유', onTap: () => _share(context, images)),
          ]),
        ),
        Positioned(
          left: 20, right: 20, bottom: pad.bottom + 24,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (images.length > 1)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6, height: 6,
                    decoration: BoxDecoration(color: i == _page ? Colors.white : Colors.white30, borderRadius: BorderRadius.circular(3)),
                  ),
              ]),
            const SizedBox(height: 16),
            if (c.isMine)
              _GlassBar(icon: Icons.ios_share_rounded, label: '공유 · 저장', onTap: () => _share(context, images))
            else
            Row(children: [
              Expanded(
                child: _GlassBar(
                  icon: Icons.notes_rounded, label: '상세 정보',
                  onTap: () => Navigator.pop(context, 'detail'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: c.primaryPhone.isEmpty ? null : () => Act.call(c.primaryPhone),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(color: C.call, borderRadius: BorderRadius.circular(27), boxShadow: [BoxShadow(color: C.call.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 10))]),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.call, color: Colors.white, size: 18), SizedBox(width: 8),
                      Text('전화', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Text(images.length > 1 ? '두 손가락으로 확대 · 꾹 누르면 공유 · 옆으로 넘기면 뒷면' : '두 손가락으로 확대 · 꾹 누르면 공유', style: const TextStyle(color: Color(0xFF9AA0AA), fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

Future<void> _share(BuildContext context, List<String> images) {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : (box.localToGlobal(Offset.zero) & box.size);
  return Act.shareImages(images, origin: origin);
}

Future<void> _save(BuildContext context, String path) async {
  final ok = await Act.saveToPhotos(path);
  if (!context.mounted) return;
  Toast.show(context, ok ? '사진에 저장했어요' : '저장할 수 없어요 (사진 권한 확인)', icon: ok ? Icons.check_rounded : Icons.error_outline_rounded);
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true, label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      );
}

class _GlassBar extends StatelessWidget {
  const _GlassBar({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(27), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
