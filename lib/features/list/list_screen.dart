import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/actions.dart';
import '../../core/calldir.dart';
import '../../core/image_paths.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/contact_repo.dart';
import '../../data/db.dart';
import '../capture/capture_screen.dart';
import '../detail/card_view_screen.dart';
import '../detail/detail_sheet.dart';
import '../edit/edit_screen.dart';
import '../mycard/my_cards_sheet.dart';
import '../settings/settings_screen.dart';
import 'widgets.dart';

class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key});
  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> with WidgetsBindingObserver {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scroll = ScrollController();

  static const _gap = 10.0;
  static const _listTop = 4.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 설정 앱에서 통화 식별을 켜고 돌아오면 상태 다시 조회
    if (state == AppLifecycleState.resumed) ref.invalidate(callDirStatusProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// 첫 명함을 저장한 직후 한 번만: 수신 전화 식별 켜기 안내 (디자인 보드 7)
  Future<void> _maybePromptCallDir() async {
    if (!CallDir.supported || !mounted) return;
    final total = ref.read(contactsProvider).value?.length ?? 0;
    if (total != 1 || await CallDir.wasPrompted()) return;
    final status = await CallDir.status();
    if (status == 'enabled' || !mounted) return;
    await CallDir.markPrompted();
    if (!mounted) return;
    final go = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + MediaQuery.paddingOf(ctx).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFD5D8DE), borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 16),
          Container(width: 48, height: 48, decoration: BoxDecoration(color: C.callTint, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.phone_in_talk_rounded, color: C.callInk)),
          const SizedBox(height: 14),
          Text('수신 전화에 이름을 띄울까요?', style: Theme.of(ctx).textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text('주소록에 넣지 않아도 저장한 명함의 번호로 전화가 오면 이름·회사가 보여요.\n설정 > 전화 > 통화 차단 및 발신자 확인에서 BizKeep을 켜 주세요.', style: TextStyle(fontSize: 14, color: C.inkMuted, height: 1.45)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: C.ink, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('설정 열기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(ctx, false), style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)), child: const Text('나중에', style: TextStyle(color: C.inkMuted, fontSize: 15))),
        ]),
      ),
    );
    if (go == true) await CallDir.openSettings();
  }

  static double _entryHeight(ListEntry e) => switch (e) {
        ContactEntry(:final contact, :final hint) => ContactRow.heightOf(contact, hint: hint),
        SectionEntry() => SectionHeader.height,
        CompanyEntry() => CompanyHeader.height,
      };

  /// 이름순 인덱스 점프: 고정 높이 합산으로 오프셋 계산 (헤더가 접힌 상태 기준)
  void _jumpToIndex(List<ListEntry> items, String key, double base) {
    var off = base + _listTop;
    for (final e in items) {
      if (e is SectionEntry && e.indexKey == key) break;
      off += _entryHeight(e) + _gap;
    }
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(off.clamp(0, _scroll.position.maxScrollExtent));
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(callDirSyncProvider);
    final items = ref.watch(visibleEntriesProvider);
    final total = ref.watch(contactsProvider).value?.length ?? 0;
    final searching = ref.watch(searchQueryProvider).trim().isNotEmpty;
    final sort = ref.watch(sortModeProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;
    final selection = ref.watch(selectionProvider);
    final selecting = selection != null;
    final showIndex = !searching && !selecting && sort == SortMode.name && total > 0;
    final indexKeys = showIndex ? [for (final e in items) if (e is SectionEntry && e.indexKey != null) e.indexKey!] : const <String>[];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, 0.4], colors: [C.bgTop, C.bg]),
        ),
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () { _searchFocus.unfocus(); ref.read(openSwipeProvider.notifier).state = null; },
              child: CustomScrollView(
                controller: _scroll,
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
                        child: selecting
                            ? _SelectHeader(
                                count: selection.length,
                                total: total,
                                onAll: () => ref.read(selectionProvider.notifier).state = {for (final e in items) if (e is ContactEntry) e.contact.id},
                                onCancel: () => ref.read(selectionProvider.notifier).state = null,
                              )
                            : _Header(total: total, searching: searching),
                      ),
                    ),
                  ),
                  if (total == 0)
                    SliverFillRemaining(hasScrollBody: false, child: _EmptyState(onCapture: _openCapture, onManual: _openManualDirect))
                  else if (items.isEmpty)
                    const SliverFillRemaining(hasScrollBody: false, child: _NoResult())
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, _listTop, showIndex ? 44 : 20, 120 + bottomInset),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: _gap),
                        itemBuilder: (context, i) => _buildEntry(items[i]),
                      ),
                    ),
                ],
              ),
            ),
            if (showIndex)
              Positioned(
                right: 6, top: 0, bottom: 120 + bottomInset,
                child: Center(child: IndexBar(keys: indexKeys, onSelect: (k) => _jumpToIndex(items, k, topInset + _Header.height))),
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
            // 글래스 독: 검색 + 등록 / 선택 모드에선 삭제 버튼
            if (selecting)
              Positioned(
                left: 16, right: 16, bottom: 12 + bottomInset,
                child: _DeleteBar(count: selection.length, onDelete: () => _deleteSelected(selection)),
              )
            else
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
                onAdd: _openCapture,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntry(ListEntry e) {
    final selection = ref.watch(selectionProvider);
    switch (e) {
      case ContactEntry(:final contact, :final hint, :final indent):
        final selecting = selection != null;
        final row = ContactRow(
          key: ValueKey('row:${contact.id}'),
          contact: contact,
          hint: hint,
          indent: indent,
          selecting: selecting,
          selected: selection?.contains(contact.id) ?? false,
          onTap: selecting ? () => _toggle(contact.id) : () { if (ref.read(openSwipeProvider) != null) { ref.read(openSwipeProvider.notifier).state = null; } else { _openDetail(contact); } },
          onThumbTap: () => _openCard(contact),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            ref.read(selectionProvider.notifier).state = {contact.id};
          },
          onCall: () => Act.call(contact.primaryPhone),
          onCallLong: contact.phoneOffice.isNotEmpty ? () => Act.call(contact.phoneOffice) : null,
        );
        if (selecting) return row;
        // 왼쪽으로 살짝 밀면 삭제 버튼 (한 번에 한 행만 열림)
        final open = ref.watch(openSwipeProvider) == contact.id;
        return SwipeReveal(
          key: ValueKey(contact.id),
          open: open,
          onOpenChanged: (v) => ref.read(openSwipeProvider.notifier).state = v ? contact.id : null,
          onDelete: () => _swipeDelete(contact),
          child: row,
        );
      case SectionEntry(:final label):
        return SectionHeader(key: ValueKey('s:$label'), label: label);
      case CompanyEntry(:final key, :final name, :final count, :final expanded, :final favorite):
        return CompanyHeader(
          key: ValueKey('c:$key'),
          name: name, count: count, expanded: expanded, favorite: favorite,
          onTap: () {
            final n = ref.read(expandedCompaniesProvider.notifier);
            n.state = expanded ? ({...n.state}..remove(key)) : {...n.state, key};
          },
          onStar: () => ref.read(repoProvider).setCompanyFavorite(key, !favorite),
        );
    }
  }

  void _toggle(String id) {
    final n = ref.read(selectionProvider.notifier);
    final cur = {...?n.state};
    cur.contains(id) ? cur.remove(id) : cur.add(id);
    n.state = cur;
  }

  Future<void> _swipeDelete(Contact c) async {
    ref.read(openSwipeProvider.notifier).state = null;
    await ref.read(repoProvider).deleteWithImages(c);
    if (mounted) Toast.show(context, '삭제되었습니다');
  }

  Future<void> _deleteSelected(Set<String> ids) async {
    if (ids.isEmpty) return;
    final ok = await ConfirmSheet.show(context, title: '${ids.length}명 삭제', message: '명함 이미지도 함께 삭제돼요.');
    if (!ok || !mounted) return;
    final all = ref.read(contactsProvider).value ?? const <Contact>[];
    final repo = ref.read(repoProvider);
    var n = 0;
    for (final c in all.where((c) => ids.contains(c.id))) {
      await repo.deleteWithImages(c);
      n++;
    }
    ref.read(selectionProvider.notifier).state = null;
    if (mounted) Toast.show(context, '$n건 삭제되었습니다');
  }

  Future<void> _openManualDirect() async {
    final id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const EditScreen(), fullscreenDialog: true));
    if (id != null && mounted) {
      await DetailSheet.show(context, id, justSaved: true);
      await _maybePromptCallDir();
    }
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

  /// + = 바로 촬영. 촬영 → 상세(저장됨) → "다음 명함" 이면 다시 촬영 (연속 등록).
  /// 촬영 화면의 "직접 입력" 은 CaptureScreen.manualResult 로 돌아와 입력 폼을 연다.
  Future<void> _openCapture() async {
    _searchFocus.unfocus();
    while (true) {
      if (!mounted) return;
      var id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const CaptureScreen(), fullscreenDialog: true));
      if (id == CaptureScreen.manualResult) {
        if (!mounted) return;
        id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const EditScreen(), fullscreenDialog: true));
      }
      if (id == null || !mounted) return;
      final r = await DetailSheet.show(context, id, justSaved: true);
      await _maybePromptCallDir();
      if (r != 'next') return;
    }
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
                icon: Icons.badge_outlined,
                label: '내 명함',
                onTap: () => MyCardsSheet.show(context),
              ),
              const SizedBox(width: 8),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCapture, required this.onManual});
  final VoidCallback onCapture;
  final VoidCallback onManual;
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
          const SizedBox(height: 6),
          TextButton(onPressed: onManual, child: const Text('명함 없이 직접 입력', style: TextStyle(color: C.accent, fontSize: 14, fontWeight: FontWeight.w600))),
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

/// 선택 모드 헤더 (높이는 _Header 와 동일하게 유지)
class _SelectHeader extends StatelessWidget {
  const _SelectHeader({required this.count, required this.total, required this.onAll, required this.onCancel});
  final int count;
  final int total;
  final VoidCallback onAll;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.inkMuted)),
                const SizedBox(height: 2),
                Text.rich(TextSpan(children: [
                  TextSpan(text: '$count', style: Theme.of(context).textTheme.headlineLarge),
                  TextSpan(text: ' / $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.inkMuted)),
                ])),
              ]),
            ),
            GlassCircleButton(icon: Icons.close_rounded, label: '선택 취소', onTap: onCancel),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            SortChip(label: count == total ? '전체 선택됨' : '전체 선택', selected: count == total, onTap: onAll),
            const SizedBox(width: 8),
            SortChip(label: '취소', selected: false, onTap: onCancel),
          ]),
        ],
      ),
    );
  }
}

/// 선택 모드 하단: 독 자리에 삭제 버튼
class _DeleteBar extends StatelessWidget {
  const _DeleteBar({required this.count, required this.onDelete});
  final int count;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;
    return GestureDetector(
      onTap: enabled ? onDelete : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? C.danger : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: enabled ? C.danger : Colors.white.withValues(alpha: 0.95)),
          boxShadow: dockShadow,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete_outline_rounded, color: enabled ? Colors.white : C.inkFaint, size: 22),
          const SizedBox(width: 8),
          Text(enabled ? '삭제 ($count)' : '삭제할 명함을 선택하세요', style: TextStyle(color: enabled ? Colors.white : C.inkMuted, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
