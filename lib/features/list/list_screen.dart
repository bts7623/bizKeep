import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/actions.dart';
import '../../core/image_paths.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/contact_repo.dart';
import '../../data/db.dart';
import '../capture/capture_screen.dart';
import '../detail/card_view_screen.dart';
import '../detail/detail_sheet.dart';
import '../edit/edit_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets.dart';

class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key});
  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(visibleListProvider);
    final total = ref.watch(contactsProvider).value?.length ?? 0;
    final searching = ref.watch(searchQueryProvider).trim().isNotEmpty;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, 0.4], colors: [C.bgTop, C.bg]),
        ),
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _searchFocus.unfocus(),
              child: CustomScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  // 위로 올리면 숨고, 내리면 즉시 나타나는 헤더
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    pinned: false,
                    backgroundColor: C.bgTop,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    automaticallyImplyLeading: false,
                    primary: false,
                    toolbarHeight: 0,
                    // 상태바 + 라벨(13) + 숫자(36) + 칩(34) + 여백 — 기기별 상태바 높이를 직접 더한다
                    expandedHeight: topInset + _Header.height,
                    // 접힐 때 내용이 위로 밀려 올라가며 잘리도록 (오버플로 방지)
                    flexibleSpace: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: _Header(total: total, searching: searching),
                      ),
                    ),
                  ),
                  if (total == 0)
                    SliverFillRemaining(hasScrollBody: false, child: _EmptyState(onCapture: _openCapture))
                  else if (items.isEmpty)
                    const SliverFillRemaining(hasScrollBody: false, child: _NoResult())
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 120 + bottomInset),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final it = items[i];
                          return ContactRow(
                            key: ValueKey(it.contact.id),
                            contact: it.contact,
                            hint: it.hint,
                            onTap: () => _openDetail(it.contact),
                            onThumbTap: () => _openCard(it.contact),
                            onCall: () => Act.call(it.contact.primaryPhone),
                            onCallLong: it.contact.phoneOffice.isNotEmpty ? () => Act.call(it.contact.phoneOffice) : null,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            // 하단 페이드
            Positioned(
              left: 0, right: 0, bottom: 0, height: 150,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      stops: const [0, 0.55, 1],
                      colors: [C.bg.withValues(alpha: 0), C.bg.withValues(alpha: 0.9), C.bg],
                    ),
                  ),
                ),
              ),
            ),
            // 글래스 독: 검색 + 등록
            Positioned(
              left: 16, right: 16, bottom: 12 + bottomInset,
              child: _Dock(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                searching: searching,
                onChanged: (v) => ref.read(searchDebouncerProvider).set(v),
                onClear: () {
                  _searchCtrl.clear();
                  ref.read(searchDebouncerProvider).clear();
                },
                onAdd: _openAddMenu,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(Contact c) => DetailSheet.show(context, c.id);
  void _openCard(Contact c) {
    if (c.imageFront == null) {
      _openDetail(c);
      return;
    }
    Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => CardViewScreen(contactId: c.id), fullscreenDialog: true))
        .then((r) { if (r == 'detail' && mounted) _openDetail(c); });
  }

  Future<void> _openCapture() async {
    _searchFocus.unfocus();
    final id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const CaptureScreen(), fullscreenDialog: true));
    if (id != null && mounted) DetailSheet.show(context, id, justSaved: true);
  }

  Future<void> _openManual() async {
    _searchFocus.unfocus();
    final id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const EditScreen(), fullscreenDialog: true));
    if (id != null && mounted) DetailSheet.show(context, id, justSaved: true);
  }

  void _openAddMenu() {
    _searchFocus.unfocus();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, a1, a2) => _AddMenu(
        onCapture: () { Navigator.pop(ctx); _openCapture(); },
        onManual: () { Navigator.pop(ctx); _openManual(); },
      ),
      transitionBuilder: (ctx, a, _, child) => FadeTransition(opacity: a, child: child),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.total, required this.searching});
  /// 상태바 제외 높이: 8 + 16(라벨) + 2 + 36(숫자) + 12 + 34(칩) + 18(아래 여백)
  static const double height = 126;
  final int total;
  final bool searching;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(sortModeProvider);
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('업무 연락처', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.inkMuted)),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(children: [
                      TextSpan(text: '$total', style: Theme.of(context).textTheme.headlineLarge),
                      const TextSpan(text: ' 명', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.inkMuted)),
                    ])),
                  ],
                ),
              ),
              GlassCircleButton(
                icon: Icons.settings_outlined,
                label: '설정',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final m in SortMode.values) ...[
                SortChip(
                  label: switch (m) { SortMode.recent => '최근 등록', SortMode.name => '이름순', SortMode.company => '회사순' },
                  selected: sort == m && !searching,
                  onTap: () => ref.read(sortModeProvider.notifier).state = m,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.controller, required this.focusNode, required this.searching, required this.onChanged, required this.onClear, required this.onAdd});
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
                  boxShadow: dockShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 22, color: C.ink),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: onChanged,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 16, color: C.ink),
                        decoration: const InputDecoration(hintText: '이름·회사·직책·번호·메일', hintStyle: TextStyle(color: C.inkFaint)),
                      ),
                    ),
                    if (searching)
                      GestureDetector(
                        onTap: onClear,
                        child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.cancel, size: 20, color: C.inkFaint)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: '명함 등록',
          child: GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: C.ink, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: C.ink.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddMenu extends StatelessWidget {
  const _AddMenu({required this.onCapture, required this.onManual});
  final VoidCallback onCapture;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: C.ink.withValues(alpha: 0.35)),
              ),
            ),
          ),
          Positioned(
            left: 16, right: 16, bottom: 88 + bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassMenuCard(icon: Icons.photo_camera_outlined, dark: true, title: '명함 촬영', subtitle: '찍으면 바로 저장돼요', onTap: onCapture),
                const SizedBox(height: 10),
                GlassMenuCard(icon: Icons.edit_outlined, dark: false, title: '직접 입력', subtitle: '명함이 없을 때', onTap: onManual),
              ],
            ),
          ),
          Positioned(
            right: 16, bottom: 12 + bottom,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: dockShadow),
                child: const Icon(Icons.close_rounded, color: C.ink, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCapture});
  final VoidCallback onCapture;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: onCapture,
            style: FilledButton.styleFrom(backgroundColor: C.ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16), shape: const StadiumBorder()),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('첫 명함 찍기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          const Text('찍으면 바로 저장돼요', style: TextStyle(color: C.inkMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult();
  @override
  Widget build(BuildContext context) => const Center(child: Text('검색 결과가 없어요', style: TextStyle(color: C.inkMuted)));
}

/// 명함 썸네일: 이미지가 있으면 표시, 없으면 이름 첫 글자.
class CardThumb extends StatelessWidget {
  const CardThumb({super.key, required this.contact, this.width = 64, this.height = 40});
  final Contact contact;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    final stored = contact.thumb ?? contact.imageFront;
    final path = stored == null ? null : ImagePaths.resolve(stored);
    return ClipRRect(
      borderRadius: BorderRadius.circular(R.thumb),
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE3E6EB)), borderRadius: BorderRadius.circular(R.thumb)),
        child: path != null
            ? Image.file(File(path), fit: BoxFit.cover, cacheWidth: (width * 3).toInt())
            : Center(child: Text(contact.initial, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.accent))),
      ),
    );
  }
}
