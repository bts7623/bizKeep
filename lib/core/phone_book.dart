import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db.dart';

/// 폰 주소록(연락처 앱)에 저장. iOS 는 `ios/Runner/PhoneBookPlugin.swift` (채널 bizkeep/phonebook). 설정 두 가지:
///   hash  — 이름 앞에 # 붙이기 (주소록에서 명함 연락처만 모아 보기 쉬움)
///   confirm — 바로 저장하지 않고 연락처 앱의 새 연락처 양식을 미리 채워서 열기
/// 이름 규칙: [#]회사_이름_직책 (빈 항목은 건너뜀). 예) #안전원_변태섭_대리
class PhoneBookPrefs {
  const PhoneBookPrefs({this.hash = true, this.confirm = false});
  final bool hash;
  final bool confirm;
  PhoneBookPrefs copyWith({bool? hash, bool? confirm}) => PhoneBookPrefs(hash: hash ?? this.hash, confirm: confirm ?? this.confirm);
}

class PhoneBookPrefsNotifier extends StateNotifier<PhoneBookPrefs> {
  PhoneBookPrefsNotifier() : super(const PhoneBookPrefs()) {
    _load();
  }
  static const _kHash = 'pb_hash', _kConfirm = 'pb_confirm';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = PhoneBookPrefs(hash: p.getBool(_kHash) ?? true, confirm: p.getBool(_kConfirm) ?? false);
  }

  Future<void> setHash(bool v) async {
    state = state.copyWith(hash: v);
    (await SharedPreferences.getInstance()).setBool(_kHash, v);
  }

  Future<void> setConfirm(bool v) async {
    state = state.copyWith(confirm: v);
    (await SharedPreferences.getInstance()).setBool(_kConfirm, v);
  }
}

final phoneBookPrefsProvider = StateNotifierProvider<PhoneBookPrefsNotifier, PhoneBookPrefs>((_) => PhoneBookPrefsNotifier());

enum PhoneBookResult { saved, updated, unchanged, opened, denied, cancelled, failed }

/// 주소록의 연락처 한 건 (플랫폼 채널에서 받은 값). 순수 Dart — 테스트에서 직접 만든다.
class BookEntry {
  const BookEntry({
    required this.id, this.name = '', this.company = '', this.title = '', this.department = '',
    this.phones = const [], this.emails = const [], this.addresses = const [], this.urls = const [],
  });
  final String id, name, company, title, department;
  final List<String> phones, emails, addresses, urls;

  factory BookEntry.fromMap(Map m) => BookEntry(
        id: (m['id'] as String?) ?? '', name: (m['name'] as String?) ?? '', company: (m['company'] as String?) ?? '',
        title: (m['title'] as String?) ?? '', department: (m['department'] as String?) ?? '',
        phones: ((m['phones'] as List?) ?? const []).cast<String>(), emails: ((m['emails'] as List?) ?? const []).cast<String>(),
        addresses: ((m['addresses'] as List?) ?? const []).cast<String>(), urls: ((m['urls'] as List?) ?? const []).cast<String>(),
      );
}

/// 주소록에 이미 있는 연락처와의 비교 결과.
class PhoneBookMatch {
  const PhoneBookMatch(this.existing, this.changes);
  final BookEntry existing;
  /// 사람이 읽는 변경 요약 ("이름: 홍길동 → #안전원_홍길동_대리"). 비어 있으면 달라진 게 없음.
  final List<String> changes;
}

abstract final class PhoneBook {
  static const _ch = MethodChannel('bizkeep/phonebook');

  /// 주소록용 표시 이름. 순수 함수 (테스트 대상).
  static String displayName(Contact c, {required bool hash}) {
    final parts = [c.company, c.name, c.title].map((s) => s.trim().replaceAll(RegExp(r'\s+'), ' ')).where((s) => s.isNotEmpty);
    final body = parts.join('_');
    if (body.isEmpty) return hash ? '#명함' : '명함';
    return hash ? '#$body' : body;
  }

  static String digits(String s) {
    var d = s.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('82') && d.length >= 11) d = '0${d.substring(2)}'; // +82 10 → 010
    return d;
  }

  static bool samePhone(String a, String b) {
    final x = digits(a), y = digits(b);
    if (x.isEmpty || y.isEmpty) return false;
    if (x == y) return true;
    // 국가번호·하이픈 차이는 무시: 뒤 8자리가 같으면 같은 번호 (휴대전화 010-XXXX-XXXX)
    return x.length >= 8 && y.length >= 8 && x.substring(x.length - 8) == y.substring(y.length - 8);
  }

  static bool _sameText(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();

  /// 주소록 목록에서 같은 사람 찾기: 휴대전화 번호 → 이메일. 순수 함수 (테스트 대상).
  static BookEntry? findIn(List<BookEntry> all, Contact c) {
    if (digits(c.phoneMobile).isNotEmpty) {
      for (final e in all) {
        if (e.phones.any((p) => samePhone(p, c.phoneMobile))) return e;
      }
    }
    if (c.email.trim().isNotEmpty) {
      for (final e in all) {
        if (e.emails.any((m) => _sameText(m, c.email))) return e;
      }
    }
    return null;
  }

  static String _or(String s) => s.isEmpty ? '(없음)' : s;

  /// 명함 기준으로 달라지는 항목 요약. 순수 함수 (테스트 대상).
  static List<String> diff(BookEntry e, Contact c, {required bool hash}) {
    final out = <String>[];
    final name = displayName(c, hash: hash);
    if (e.name.trim() != name) out.add('이름: ${_or(e.name.trim())} → $name');
    if (c.company.isNotEmpty && e.company != c.company) out.add('회사: ${_or(e.company)} → ${c.company}');
    if (c.title.isNotEmpty && e.title != c.title) out.add('직책: ${_or(e.title)} → ${c.title}');
    if (c.department.isNotEmpty && e.department != c.department) out.add('부서: ${_or(e.department)} → ${c.department}');
    for (final (label, v) in [('휴대전화', c.phoneMobile), ('사무실', c.phoneOffice), ('팩스', c.fax)]) {
      if (v.isNotEmpty && !e.phones.any((p) => samePhone(p, v))) out.add('$label 추가: $v');
    }
    if (c.email.isNotEmpty && !e.emails.any((m) => _sameText(m, c.email))) out.add('이메일 추가: ${c.email}');
    if (c.address.isNotEmpty && !e.addresses.any((a) => _sameText(a, c.address))) out.add('주소 추가: ${c.address}');
    if (c.website.isNotEmpty && !e.urls.any((w) => _sameText(w, c.website))) out.add('웹 추가: ${c.website}');
    return out;
  }

  /// 새 연락처 페이로드 (insert / openInsert 용).
  static Map<String, Object?> payload(Contact c, {required bool hash}) => {
        'name': displayName(c, hash: hash),
        'company': c.company, 'title': c.title, 'department': c.department,
        'phones': [
          if (c.phoneMobile.isNotEmpty) {'number': c.phoneMobile, 'label': 'mobile'},
          if (c.phoneOffice.isNotEmpty) {'number': c.phoneOffice, 'label': 'work'},
          if (c.fax.isNotEmpty) {'number': c.fax, 'label': 'fax'},
        ],
        'emails': [if (c.email.isNotEmpty) c.email],
        'addresses': [if (c.address.isNotEmpty) c.address],
        'urls': [if (c.website.isNotEmpty) c.website],
      };

  /// 덮어쓰기 페이로드: 이름·회사·직책·부서는 명함 값으로, 번호·메일·주소·웹은 주소록에 없는 것만 추가.
  /// 주소록에만 있는 정보는 건드리지 않는다. 순수 함수 (테스트 대상).
  static Map<String, Object?> updatePayload(BookEntry e, Contact c, {required bool hash}) => {
        'id': e.id,
        'name': displayName(c, hash: hash),
        'company': c.company, 'title': c.title, 'department': c.department,
        'phones': [
          for (final (v, label) in [(c.phoneMobile, 'mobile'), (c.phoneOffice, 'work'), (c.fax, 'fax')])
            if (v.isNotEmpty && !e.phones.any((p) => samePhone(p, v))) {'number': v, 'label': label},
        ],
        'emails': [if (c.email.isNotEmpty && !e.emails.any((m) => _sameText(m, c.email))) c.email],
        'addresses': [if (c.address.isNotEmpty && !e.addresses.any((a) => _sameText(a, c.address))) c.address],
        'urls': [if (c.website.isNotEmpty && !e.urls.any((w) => _sameText(w, c.website))) c.website],
      };

  /// 1단계: 권한 확인 후 주소록에서 같은 사람 찾기. (결과, 매치) — 권한 거부·실패는 결과로, 없으면 둘 다 null.
  static Future<(PhoneBookResult?, PhoneBookMatch?)> lookup(Contact c, PhoneBookPrefs prefs) async {
    try {
      if (await _ch.invokeMethod<bool>('requestAccess') != true) return (PhoneBookResult.denied, null);
      if (c.phoneMobile.isEmpty && c.email.isEmpty) return (null, null);
      final raw = await _ch.invokeMethod<List<Object?>>('fetchAll') ?? const [];
      final all = [for (final m in raw) BookEntry.fromMap(m as Map)];
      final hit = findIn(all, c);
      if (hit == null) return (null, null);
      return (null, PhoneBookMatch(hit, diff(hit, c, hash: prefs.hash)));
    } catch (_) {
      return (PhoneBookResult.failed, null);
    }
  }

  /// 새로 저장 (설정에 따라 바로 insert 하거나 연락처 앱 양식을 연다).
  static Future<PhoneBookResult> insert(Contact c, PhoneBookPrefs prefs) async {
    try {
      final p = payload(c, hash: prefs.hash);
      if (prefs.confirm) {
        final ok = await _ch.invokeMethod<bool>('openInsert', p);
        return ok == true ? PhoneBookResult.opened : PhoneBookResult.cancelled;
      }
      final id = await _ch.invokeMethod<String>('insert', p);
      return id == null ? PhoneBookResult.failed : PhoneBookResult.saved;
    } catch (_) {
      return PhoneBookResult.failed;
    }
  }

  /// 기존 연락처 덮어쓰기.
  static Future<PhoneBookResult> overwrite(PhoneBookMatch m, Contact c, PhoneBookPrefs prefs) async {
    try {
      final ok = await _ch.invokeMethod<bool>('update', updatePayload(m.existing, c, hash: prefs.hash));
      return ok == true ? PhoneBookResult.updated : PhoneBookResult.failed;
    } catch (_) {
      return PhoneBookResult.failed;
    }
  }
}
