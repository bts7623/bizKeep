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

enum PhoneBookResult { saved, opened, denied, cancelled, failed }

abstract final class PhoneBook {
  /// 주소록용 표시 이름. 순수 함수 (테스트 대상).
  static String displayName(Contact c, {required bool hash}) {
    final parts = [c.company, c.name, c.title].map((s) => s.trim().replaceAll(RegExp(r'\s+'), ' ')).where((s) => s.isNotEmpty);
    final body = parts.join('_');
    if (body.isEmpty) return hash ? '#명함' : '명함';
    return hash ? '#$body' : body;
  }

  static fc.Contact _build(Contact c, PhoneBookPrefs prefs) {
    final fcC = fc.Contact(
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
    return fcC;
  }

  /// 설정에 따라 바로 저장하거나(saved) 연락처 앱 양식을 연다(opened).
  static Future<PhoneBookResult> save(Contact c, PhoneBookPrefs prefs) async {
    try {
      final draft = _build(c, prefs);
      if (prefs.confirm) {
        // 양식 열기는 권한이 필요 없음 (iOS). 저장 여부는 사용자가 양식에서 결정.
        final r = await fc.FlutterContacts.openExternalInsert(draft);
        return r == null ? PhoneBookResult.cancelled : PhoneBookResult.opened;
      }
      if (!await fc.FlutterContacts.requestPermission(readonly: false)) return PhoneBookResult.denied;
      await draft.insert();
      return PhoneBookResult.saved;
    } catch (_) {
      return PhoneBookResult.failed;
    }
  }
}
