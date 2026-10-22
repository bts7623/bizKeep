import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/contact_repo.dart';
import '../data/db.dart';
import '../data/search_ranker.dart';

final dbProvider = Provider<AppDb>((ref) {
  final db = AppDb();
  ref.onDispose(db.close);
  return db;
});

final repoProvider = Provider<ContactRepo>((ref) => ContactRepo(ref.watch(dbProvider)));

/// 전체 연락처 (최근 등록순). DB 변경 시 자동 갱신.
final contactsProvider = StreamProvider<List<Contact>>((ref) => ref.watch(repoProvider).watchAll());

enum SortMode { recent, name, company }

final sortModeProvider = StateProvider<SortMode>((_) => SortMode.recent);

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

class ListItem {
  final Contact contact;
  final String? hint;
  const ListItem(this.contact, this.hint);
}

/// 화면에 그릴 최종 목록: 검색어가 있으면 랭커 결과, 없으면 정렬된 전체.
final visibleListProvider = Provider<List<ListItem>>((ref) {
  final all = ref.watch(contactsProvider).value ?? const <Contact>[];
  final q = ref.watch(searchQueryProvider);
  if (q.trim().isNotEmpty) {
    final hits = const SearchRanker().rank(q, all.map((c) => c.toSearchDoc()));
    final byId = {for (final c in all) c.id: c};
    return [for (final h in hits) ListItem(byId[h.doc.id]!, h.hint)];
  }
  final sorted = [...all];
  switch (ref.watch(sortModeProvider)) {
    case SortMode.recent:
      break; // 이미 최근순
    case SortMode.name:
      sorted.sort((a, b) => a.name.compareTo(b.name));
    case SortMode.company:
      sorted.sort((a, b) {
        final c = a.company.compareTo(b.company);
        return c != 0 ? c : a.name.compareTo(b.name);
      });
  }
  return [for (final c in sorted) ListItem(c, null)];
});
