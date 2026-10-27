import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/contact_repo.dart';
import '../data/db.dart';
import '../data/list_grouper.dart';
import '../data/search_ranker.dart';

export '../data/list_grouper.dart' show SortMode, ListEntry, ContactEntry, SectionEntry, CompanyEntry, ListGrouper;

final dbProvider = Provider<AppDb>((ref) {
  final db = AppDb();
  ref.onDispose(db.close);
  return db;
});

final repoProvider = Provider<ContactRepo>((ref) => ContactRepo(ref.watch(dbProvider)));

/// 업무 연락처 전체 (최근 등록순, 내 명함 제외). DB 변경 시 자동 갱신.
final contactsProvider = StreamProvider<List<Contact>>((ref) => ref.watch(repoProvider).watchAll());

/// 내 명함들.
final myCardsProvider = StreamProvider<List<Contact>>((ref) => ref.watch(repoProvider).watchMine());

/// 즐겨찾기 회사 key 집합.
final companyFavoritesProvider = StreamProvider<Set<String>>((ref) => ref.watch(repoProvider).watchCompanyFavorites());

final sortModeProvider = StateProvider<SortMode>((_) => SortMode.recent);

/// 회사순 트리에서 펼쳐진 회사 key (세션 동안만 유지).
final expandedCompaniesProvider = StateProvider<Set<String>>((_) => const {});

/// 선택 모드: null 이면 꺼짐, 아니면 선택된 id 집합 (빈 집합도 선택 모드).
final selectionProvider = StateProvider<Set<String>?>((_) => null);

/// 스와이프 삭제 대기열: 목록에서 즉시 숨기고 5초 뒤 실제 삭제. "실행 취소" 로 복구.
class PendingDelete extends StateNotifier<Set<String>> {
  PendingDelete(this.ref) : super(const {});
  final Ref ref;
  final _timers = <String, Timer>{};

  void schedule(Contact c) {
    state = {...state, c.id};
    _timers[c.id]?.cancel();
    _timers[c.id] = Timer(const Duration(seconds: 5), () => _commit(c));
  }

  void undo(String id) {
    _timers.remove(id)?.cancel();
    state = {...state}..remove(id);
  }

  Future<void> _commit(Contact c) async {
    _timers.remove(c.id);
    await ref.read(repoProvider).deleteWithImages(c);
    state = {...state}..remove(c.id);
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}

final pendingDeleteProvider = StateNotifierProvider<PendingDelete, Set<String>>((ref) => PendingDelete(ref));

/// 검색어 (150ms 디바운스 후 반영).
final searchQueryProvider = StateProvider<String>((_) => '');

class SearchDebouncer {
  SearchDebouncer(this.ref);
  final Ref ref;
  Timer? _t;
  void set(String v) {
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 150), () => ref.read(searchQueryProvider.notifier).state = v);
  }

  void clear() {
    _t?.cancel();
    ref.read(searchQueryProvider.notifier).state = '';
  }
}

final searchDebouncerProvider = Provider<SearchDebouncer>((ref) {
  final d = SearchDebouncer(ref);
  ref.onDispose(() => d._t?.cancel());
  return d;
});

/// 화면에 그릴 최종 목록: 검색어가 있으면 랭커 결과(평면), 없으면 정렬 모드별 섹션 목록.
final visibleEntriesProvider = Provider<List<ListEntry>>((ref) {
  final hidden = ref.watch(pendingDeleteProvider);
  final all = (ref.watch(contactsProvider).value ?? const <Contact>[]).where((c) => !hidden.contains(c.id)).toList();
  final q = ref.watch(searchQueryProvider);
  if (q.trim().isNotEmpty) {
    final hits = const SearchRanker().rank(q, all.map((c) => c.toSearchDoc()));
    final byId = {for (final c in all) c.id: c};
    return [for (final h in hits) ContactEntry(byId[h.doc.id]!, hint: h.hint)];
  }
  return const ListGrouper().group(
    all,
    mode: ref.watch(sortModeProvider),
    favoriteCompanies: ref.watch(companyFavoritesProvider).value ?? const {},
    expanded: ref.watch(expandedCompaniesProvider),
  );
});
