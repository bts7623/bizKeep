/// 목록 섹션 구성 (순수 Dart — 테스트 대상).
/// 최근순: 월 구분 / 이름순: 초성(ㄱ~ㅎ·A~Z·#) 구분 + 인덱스 / 회사순: 회사 트리(2명 이상이면 접었다 펴기).
/// 즐겨찾기 사람은 모든 모드에서 맨 위 "즐겨찾기" 섹션. 즐겨찾기 회사는 회사순에서 맨 위 + 펼침.
library;

import 'contact_repo.dart';
import 'db.dart';

enum SortMode { recent, name, company }

sealed class ListEntry {
  const ListEntry();
}

/// 사람 행.
class ContactEntry extends ListEntry {
  const ContactEntry(this.contact, {this.hint, this.indent = false});
  final Contact contact;
  final String? hint;
  /// 회사 트리 아래 들여쓰기 행
  final bool indent;
}

/// 구분 헤더 (월·초성·즐겨찾기).
class SectionEntry extends ListEntry {
  const SectionEntry(this.label, {this.indexKey});
  final String label;
  /// 인덱스 바에 표시할 키 (이름순에서만)
  final String? indexKey;
}

/// 회사 트리 헤더 (접었다 펴기).
class CompanyEntry extends ListEntry {
  const CompanyEntry({required this.key, required this.name, required this.count, required this.expanded, required this.favorite});
  final String key;
  final String name;
  final int count;
  final bool expanded;
  final bool favorite;
}

class ListGrouper {
  const ListGrouper();

  static const favoritesLabel = '즐겨찾기';
  static const noCompanyLabel = '소속 없음';

  List<ListEntry> group(
    List<Contact> all, {
    required SortMode mode,
    Set<String> favoriteCompanies = const {},
    Set<String> expanded = const {},
  }) {
    final out = <ListEntry>[];
    final favs = all.where((c) => c.favorite).toList()..sort((a, b) => _nameCmp(a, b));
    if (favs.isNotEmpty) {
      out.add(const SectionEntry(favoritesLabel));
      out.addAll(favs.map((c) => ContactEntry(c)));
    }
    final rest = mode == SortMode.company ? all : all.where((c) => !c.favorite).toList();

    switch (mode) {
      case SortMode.recent:
        String? cur;
        for (final c in rest) {
          final d = DateTime.fromMillisecondsSinceEpoch(c.createdAt);
          final label = '${d.year}년 ${d.month}월';
          if (label != cur) {
            cur = label;
            out.add(SectionEntry(label));
          }
          out.add(ContactEntry(c));
        }
      case SortMode.name:
        final sorted = [...rest]..sort(_nameCmp);
        String? cur;
        for (final c in sorted) {
          final k = indexKeyOf(c.name);
          if (k != cur) {
            cur = k;
            out.add(SectionEntry(k, indexKey: k));
          }
          out.add(ContactEntry(c));
        }
      case SortMode.company:
        final groups = <String, List<Contact>>{};
        final names = <String, String>{};
        for (final c in rest) {
          final k = ContactRepo.companyKey(c.company);
          groups.putIfAbsent(k, () => []).add(c);
          names.putIfAbsent(k, () => c.company.isEmpty ? noCompanyLabel : c.company);
        }
        final keys = groups.keys.toList()
          ..sort((a, b) {
            final fa = favoriteCompanies.contains(a), fb = favoriteCompanies.contains(b);
            if (fa != fb) return fa ? -1 : 1;
            if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1; // 소속 없음은 맨 뒤
            return a.compareTo(b); // 정규화 키로 정렬 (㈜·(주) 무시)
          });
        for (final k in keys) {
          final members = groups[k]!..sort(_nameCmp);
          final fav = favoriteCompanies.contains(k);
          if (members.length == 1 && !fav) {
            out.add(ContactEntry(members.first));
            continue;
          }
          final open = fav || expanded.contains(k);
          out.add(CompanyEntry(key: k, name: names[k]!, count: members.length, expanded: open, favorite: fav));
          if (open) out.addAll(members.map((c) => ContactEntry(c, indent: true)));
        }
    }
    return out;
  }

  static int _nameCmp(Contact a, Contact b) {
    final c = a.name.compareTo(b.name);
    return c != 0 ? c : a.company.compareTo(b.company);
  }

  /// 이름 첫 글자 → 인덱스 키: 한글은 초성, 영문은 대문자, 그 외 '#'. 빈 이름은 '#'.
  static String indexKeyOf(String name) {
    if (name.isEmpty) return '#';
    final code = name.runes.first;
    if (code >= 0xAC00 && code <= 0xD7A3) return _chosung[(code - 0xAC00) ~/ 588];
    if (code >= 0x3131 && code <= 0x314E) return String.fromCharCode(code); // 자음 자체
    final ch = String.fromCharCode(code).toUpperCase();
    if (RegExp(r'^[A-Z]$').hasMatch(ch)) return ch;
    return '#';
  }

  static const _chosung = ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'];
}
