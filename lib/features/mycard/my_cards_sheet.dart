import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/actions.dart';
import '../../core/image_paths.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db.dart';
import '../capture/capture_screen.dart';
import '../capture/image_io.dart';
import '../detail/card_view_screen.dart';

/// 내 명함 시트 (보조 화면). 여러 장 등록, 옆으로 넘겨 보기, 꾹 누르면 공유(저장·복사·에어드롭).
class MyCardsSheet extends ConsumerStatefulWidget {
  const MyCardsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: C.ink.withValues(alpha: 0.42),
        builder: (_) => const MyCardsSheet(),
      );

  @override
  ConsumerState<MyCardsSheet> createState() => _MyCardsSheetState();
}

class _MyCardsSheetState extends ConsumerState<MyCardsSheet> {
  final _page = PageController(viewportFraction: 0.92);
  int _idx = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(myCardsProvider).value ?? const <Contact>[];
    final bottom = MediaQuery.paddingOf(context).bottom;
    final w = MediaQuery.sizeOf(context).width;
    final cardH = (w - 40) / 1.7; // 가이드 프레임 비율과 동일
    if (_idx >= cards.length) _idx = cards.isEmpty ? 0 : cards.length - 1;
    final current = cards.isEmpty ? null : cards[_idx];

    return Container(
      decoration: const BoxDecoration(color: C.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
      padding: EdgeInsets.only(bottom: 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFD5D8DE), borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
            child: Row(children: [
              Text('내 명함', style: Theme.of(context).textTheme.headlineMedium),
              if (cards.length > 1) ...[
                const SizedBox(width: 8),
                Text('${_idx + 1}/${cards.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.inkMuted)),
              ],
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: C.inkMuted), tooltip: '닫기'),
            ]),
          ),
          const SizedBox(height: 8),
          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(children: [
                Container(
                  height: cardH,
                  decoration: BoxDecoration(
                    color: C.surfaceAlt, borderRadius: BorderRadius.circular(R.box),
                    border: Border.all(color: C.line, width: 1.5),
                  ),
                  child: const Center(child: Icon(Icons.badge_outlined, size: 40, color: C.inkFaint)),
                ),
                const SizedBox(height: 14),
                const Text('내 명함을 등록해 두면 바로 꺼내 보여줄 수 있어요', style: TextStyle(fontSize: 14, color: C.inkMuted)),
              ]),
            )
          else
            SizedBox(
              height: cardH,
              child: PageView.builder(
                controller: _page,
                itemCount: cards.length,
                onPageChanged: (i) => setState(() => _idx = i),
                itemBuilder: (_, i) => _CardPage(card: cards[i], onTap: () => _view(cards[i]), onLong: () => _share(cards[i])),
              ),
            ),
          if (cards.length > 1) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < cards.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _idx ? 18 : 6, height: 6,
                  decoration: BoxDecoration(color: i == _idx ? C.ink : C.inkFaint, borderRadius: BorderRadius.circular(3)),
                ),
            ]),
          ],
          if (current != null) ...[
            const SizedBox(height: 6),
            const Text('꾹 누르면 저장·복사·전송', style: TextStyle(fontSize: 12, color: C.inkFaint)),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              if (current != null) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _share(current),
                    style: FilledButton.styleFrom(backgroundColor: C.ink, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                    label: const Text('공유', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _add,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF0F2F5), foregroundColor: C.ink, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: Text(current == null ? '내 명함 등록' : '추가', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              if (current != null) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 52, height: 52,
                  child: FilledButton(
                    onPressed: () => _delete(current),
                    style: FilledButton.styleFrom(backgroundColor: C.dangerTint, foregroundColor: C.danger, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Icon(Icons.delete_outline_rounded, size: 22),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  List<String> _paths(Contact c) => [c.imageFront, c.imageBack].whereType<String>().map(ImagePaths.resolve).toList();

  void _view(Contact c) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CardViewScreen(contactId: c.id), fullscreenDialog: true));
  }

  Future<void> _share(Contact c) {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : (box.localToGlobal(Offset.zero) & box.size);
    return Act.shareImages(_paths(c), origin: origin);
  }

  Future<void> _add() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('명함 촬영'), onTap: () => Navigator.pop(ctx, 'camera')),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('앨범에서 선택'), subtitle: const Text('명함 디자인 파일·캡처도 돼요'), onTap: () => Navigator.pop(ctx, 'album')),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (!mounted || choice == null) return;
    String? id;
    if (choice == 'camera') {
      id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const CaptureScreen(mine: true), fullscreenDialog: true));
    } else {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000, maxHeight: 2000);
      if (x == null) return;
      final key = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      final saved = await ImageIo.saveFull(await x.readAsBytes(), key);
      final c = await ref.read(repoProvider).create(
            name: '내 명함', imageFront: ImagePaths.toStored(saved.front), thumb: ImagePaths.toStored(saved.thumb), source: 'mine', isMine: true,
          );
      id = c.id;
    }
    if (id != null && mounted) {
      // 새로 추가된 카드(맨 뒤)로 이동
      final n = (ref.read(myCardsProvider).value?.length ?? 1);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _page.hasClients) _page.animateToPage(n - 1, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });
    }
  }

  Future<void> _delete(Contact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('내 명함 삭제'),
        content: const Text('이 명함 이미지를 지워요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: C.danger), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    for (final p in [c.imageFront, c.imageBack, c.thumb]) {
      if (p != null) {
        try { await File(ImagePaths.resolve(p)).delete(); } catch (_) {}
      }
    }
    await ref.read(repoProvider).delete(c.id);
  }
}

class _CardPage extends StatelessWidget {
  const _CardPage({required this.card, required this.onTap, required this.onLong});
  final Contact card;
  final VoidCallback onTap;
  final VoidCallback onLong;
  @override
  Widget build(BuildContext context) {
    final img = card.imageFront == null ? null : ImagePaths.resolve(card.imageFront!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLong,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.box),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E2A44), Color(0xFF0F1524)]),
            boxShadow: [BoxShadow(color: C.ink.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          clipBehavior: Clip.antiAlias,
          child: img == null
              ? const Center(child: Text('이미지 없음', style: TextStyle(color: Colors.white70)))
              : Image.file(File(img), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
