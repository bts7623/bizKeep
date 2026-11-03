import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db.dart';

/// 폰 주소록(연락처 앱)에 저장. 설정 두 가지:
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

/// 주소록에 이미 있는 연락처와의 비교 결과.
class PhoneBookMatch {
  const PhoneBookMatch(this.existing, this.changes);
  final fc.Contact existing;
  /// 사람이 읽는 변경 요약 ("이름: 홍길동 → #안전원_홍길동_대리"). 비어 있으면 달라진 게 없음.
  final List<String> changes;
}

abstract final class PhoneBook {
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

  static bool _samePhone(String a, String b) {
    final x = digits(a), y = digits(b);
    if (x.isEmpty || y.isEmpty) return false;
    if (x == y) return true;
    // 국가번호·하이픈 차이는 무시: 뒤 8자리가 같으면 같은 번호 (휴대전화 010-XXXX-XXXX)
    return x.length >= 8 && y.length >= 8 && x.substring(x.length - 8) == y.substring(y.length - 8);
  }

  /// 주소록 목록에서 같은 사람 찾기: 휴대전화 번호 → 이메일. 순수 함수 (테스트 대상).
  static fc.Contact? findIn(List<fc.Contact> all, Contact c) {
    final mobile = digits(c.phoneMobile);
    final email = c.email.trim().toLowerCase();
    if (mobile.isNotEmpty) {
      for (final e in all) {
        if (e.phones.any((p) => _samePhone(p.number, c.phoneMobile))) return e;
      }
    }
    if (email.isNotEmpty) {
      for (final e in all) {
        if (e.emails.any((m) => m.address.trim().toLowerCase() == email)) return e;
      }
    }
    return null;
  }

  /// 명함 기준으로 달라지는 항목 요약. 순수 함수 (테스트 대상).
  static List<String> diff(fc.Contact e, Contact c, {required bool hash}) {
    final out = <String>[];
    final name = displayName(c, hash: hash);
    if (nameOf(e) != name) out.add('이름: ${_or(nameOf(e))} → $name');
    final org = e.organizations.firstOrNull;
    if (c.company.isNotEmpty && (org?.company ?? '') != c.company) out.add('회사: ${_or(org?.company)} → ${c.company}');
    if (c.title.isNotEmpty && (org?.title ?? '') != c.title) out.add('직책: ${_or(org?.title)} → ${c.title}');
    if (c.department.isNotEmpty && (org?.department ?? '') != c.department) out.add('부서: ${_or(org?.department)} → ${c.department}');
    for (final (label, v) in [('휴대전화', c.phoneMobile), ('사무실', c.phoneOffice), ('팩스', c.fax)]) {
      if (v.isNotEmpty && !e.phones.any((p) => _samePhone(p.number, v))) out.add('$label 추가: $v');
    }
    if (c.email.isNotEmpty && !e.emails.any((m) => m.address.trim().toLowerCase() == c.email.trim().toLowerCase())) out.add('이메일 추가: ${c.email}');
    if (c.address.isNotEmpty && !e.addresses.any((a) => a.address.trim() == c.address.trim())) out.add('주소 추가: ${c.address}');
    if (c.website.isNotEmpty && !e.websites.any((w) => w.url.trim() == c.website.trim())) out.add('웹 추가: ${c.website}');
    if (c.memo.isNotEmpty && !e.notes.any((n) => n.note.trim() == c.memo.trim())) out.add('메모 추가: ${c.memo}');
    return out;
  }

  static String _or(String? s) => (s == null || s.isEmpty) ? '(없음)' : s;

  /// 주소록 연락처의 표시 이름 (displayName 은 플랫폼이 채우므로 테스트·직접 생성 시엔 name 에서 조립).
  static String nameOf(fc.Contact e) {
    final d = e.displayName.trim();
    if (d.isNotEmpty) return d;
    return [e.name.last, e.name.first].where((s) => s.trim().isNotEmpty).join(' ').trim();
  }

  /// 기존 연락처에 명함 내용을 덮어쓴다. 명함에 있는 항목만 갱신하고, 주소록에만 있는 번호·생일 등은 그대로 둔다.
  static void applyTo(fc.Contact e, Contact c, {required bool hash}) {
    e.name = fc.Name(first: displayName(c, hash: hash));
    e.displayName = displayName(c, hash: hash);
    if (c.company.isNotEmpty || c.title.isNotEmpty || c.department.isNotEmpty) {
      final org = e.organizations.firstOrNull ?? fc.Organization();
      if (c.company.isNotEmpty) org.company = c.company;
      if (c.title.isNotEmpty) org.title = c.title;
      if (c.department.isNotEmpty) org.department = c.department;
      if (e.organizations.isEmpty) e.organizations = [org];
    }
    for (final (v, label) in [(c.phoneMobile, fc.PhoneLabel.mobile), (c.phoneOffice, fc.PhoneLabel.work), (c.fax, fc.PhoneLabel.faxWork)]) {
      if (v.isNotEmpty && !e.phones.any((p) => _samePhone(p.number, v))) e.phones = [...e.phones, fc.Phone(v, label: label)];
    }
    if (c.email.isNotEmpty && !e.emails.any((m) => m.address.trim().toLowerCase() == c.email.trim().toLowerCase())) e.emails = [...e.emails, fc.Email(c.email, label: fc.EmailLabel.work)];
    if (c.address.isNotEmpty && !e.addresses.any((a) => a.address.trim() == c.address.trim())) e.addresses = [...e.addresses, fc.Address(c.address, label: fc.AddressLabel.work)];
    if (c.website.isNotEmpty && !e.websites.any((w) => w.url.trim() == c.website.trim())) e.websites = [...e.websites, fc.Website(c.website, label: fc.WebsiteLabel.work)];
    if (c.memo.isNotEmpty && !e.notes.any((n) => n.note.trim() == c.memo.trim())) e.notes = [...e.notes, fc.Note(c.memo)];
  }

  static fc.Contact _build(Contact c, PhoneBookPrefs prefs) => fc.Contact(
        name: fc.Name(first: displayName(c, hash: prefs.hash)),
        organizations: [
          if (c.company.isNotEmpty || c.title.isNotEmpty || c.department.isNotEmpty)
            fc.Organization(company: c.company, title: c.title, department: c.department),
        ],
        phones: [
          if (c.phoneMobile.isNotEmpty) fc.Phone(c.phoneMobile, label: fc.PhoneLabel.mobile),
          if (c.phoneOffice.isNotEmpty) fc.Phone(c.phoneOffice, label: fc.PhoneLabel.work),
          if (c.fax.isNotEmpty) fc.Phone(c.fax, label: fc.PhoneLabel.faxWork),
        ],
        emails: [if (c.email.isNotEmpty) fc.Email(c.email, label: fc.EmailLabel.work)],
        addresses: [if (c.address.isNotEmpty) fc.Address(c.address, label: fc.AddressLabel.work)],
        websites: [if (c.website.isNotEmpty) fc.Website(c.website, label: fc.WebsiteLabel.work)],
        notes: [if (c.memo.isNotEmpty) fc.Note(c.memo)],
      );

  /// 1단계: 권한 확인 후 주소록에서 같은 사람 찾기. 권한 거부면 null 과 denied 를 구분하기 위해 예외 대신 레코드로.
  static Future<(PhoneBookResult?, PhoneBookMatch?)> lookup(Contact c, PhoneBookPrefs prefs) async {
    try {
      if (!await fc.FlutterContacts.requestPermission(readonly: false)) return (PhoneBookResult.denied, null);
      if (c.phoneMobile.isEmpty && c.email.isEmpty) return (null, null);
      final all = await fc.FlutterContacts.getContacts(withProperties: true, withPhoto: false);
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
      final draft = _build(c, prefs);
      if (prefs.confirm) {
        final r = await fc.FlutterContacts.openExternalInsert(draft);
        return r == null ? PhoneBookResult.cancelled : PhoneBookResult.opened;
      }
      await draft.insert();
      return PhoneBookResult.saved;
    } catch (_) {
      return PhoneBookResult.failed;
    }
  }

  /// 기존 연락처 덮어쓰기.
  static Future<PhoneBookResult> overwrite(PhoneBookMatch m, Contact c, PhoneBookPrefs prefs) async {
    try {
      applyTo(m.existing, c, hash: prefs.hash);
      await m.existing.update();
      return PhoneBookResult.updated;
    } catch (_) {
      return PhoneBookResult.failed;
    }
  }
}
