import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';
import 'ocr_parser.dart';
import 'search_ranker.dart';

/// 연락처 CRUD. 목록은 전체를 메모리에 캐시해 검색·정렬을 Dart에서 처리한다
/// (수천 건까지 ms 단위). 1만 건을 넘기면 FTS5 도입.
class ContactRepo {
  ContactRepo(this.db);
  final AppDb db;
  static const _uuid = Uuid();

  /// 업무 연락처 (내 명함 제외), 최근 등록순.
  Stream<List<Contact>> watchAll() => (db.select(db.contacts)
        ..where((t) => t.isMine.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  /// 내 명함들, 등록순.
  Stream<List<Contact>> watchMine() => (db.select(db.contacts)
        ..where((t) => t.isMine.equals(true))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();

  Future<void> setFavorite(String id, bool v) =>
      (db.update(db.contacts)..where((t) => t.id.equals(id))).write(ContactsCompanion(favorite: Value(v)));

  /// 즐겨찾기 회사 key 집합.
  Stream<Set<String>> watchCompanyFavorites() => (db.select(db.companyPrefs)..where((t) => t.favorite.equals(true)))
      .watch()
      .map((rows) => rows.map((r) => r.key).toSet());

  Future<void> setCompanyFavorite(String key, bool v) => db
      .into(db.companyPrefs)
      .insertOnConflictUpdate(CompanyPrefsCompanion(key: Value(key), favorite: Value(v)));

  /// 회사명 정규화 키: ㈜·(주)·주식회사·공백·대소문자 무시. 트리 그룹·즐겨찾기 기준.
  static String companyKey(String company) => company
      .replaceAll(RegExp(r'주식회사|㈜|\(주\)|\(유\)|유한회사'), '')
      .replaceAll(RegExp(r'[\s\-_.,·]'), '')
      .toLowerCase();

  Future<Contact?> get(String id) => (db.select(db.contacts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Contact> create({
    String name = '',
    String company = '',
    String department = '',
    String title = '',
    String phoneMobile = '',
    String phoneOffice = '',
    String fax = '',
    String email = '',
    String address = '',
    String website = '',
    String memo = '',
    String? imageFront,
    String? imageBack,
    String? thumb,
    String ocrRaw = '',
    String source = 'manual',
    List<String> lowConfidence = const [],
    bool isMine = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = ContactsCompanion.insert(
      id: _uuid.v4(),
      name: Value(name.trim()),
      company: Value(company.trim()),
      department: Value(department.trim()),
      title: Value(title.trim()),
      phoneMobile: Value(phoneMobile.trim()),
      phoneOffice: Value(phoneOffice.trim()),
      fax: Value(fax.trim()),
      email: Value(email.trim()),
      address: Value(address.trim()),
      website: Value(website.trim()),
      memo: Value(_clipMemo(memo)),
      imageFront: Value(imageFront),
      imageBack: Value(imageBack),
      thumb: Value(thumb),
      ocrRaw: Value(ocrRaw),
      source: Value(source),
      lowConfidence: Value(jsonEncode(lowConfidence)),
      isMine: Value(isMine),
      createdAt: now,
      updatedAt: now,
    );
    await db.into(db.contacts).insert(row);
    final c = await get(row.id.value);
    await _syncPhoneIndex(c!);
    return c;
  }

  Future<void> update(Contact c) async {
    final updated = c.copyWith(memo: _clipMemo(c.memo), updatedAt: DateTime.now().millisecondsSinceEpoch);
    await db.update(db.contacts).replace(updated);
    await _syncPhoneIndex(updated);
  }

  Future<void> updateMemo(String id, String memo) async {
    await (db.update(db.contacts)..where((t) => t.id.equals(id))).write(ContactsCompanion(
      memo: Value(_clipMemo(memo)),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> delete(String id) async {
    await (db.delete(db.contacts)..where((t) => t.id.equals(id))).go();
    await db.customStatement('DELETE FROM phone_index WHERE contact_id = ?', [id]);
  }

  Future<int> count() async {
    final r = await db.customSelect('SELECT COUNT(*) AS c FROM contacts WHERE is_mine = 0').getSingle();
    return r.read<int>('c');
  }

  Future<void> _syncPhoneIndex(Contact c) async {
    await db.customStatement('DELETE FROM phone_index WHERE contact_id = ?', [c.id]);
    if (c.isMine) return;
    for (final ph in [c.phoneMobile, c.phoneOffice]) {
      final e = OcrParser.toE164(ph);
      if (e != null) {
        await db.customStatement('INSERT OR REPLACE INTO phone_index(phone_e164, contact_id) VALUES (?, ?)', [e, c.id]);
      }
    }
  }

  static String _clipMemo(String m) {
    final t = m.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.runes.length > 40 ? String.fromCharCodes(t.runes.take(40)) : t;
  }
}

extension ContactSearch on Contact {
  SearchDoc toSearchDoc() => SearchDoc(
        id: id,
        name: name,
        company: company,
        department: department,
        title: title,
        phoneMobile: phoneMobile,
        phoneOffice: phoneOffice,
        email: email,
        address: address,
        memo: memo,
        ocrRaw: ocrRaw,
        createdAt: createdAt,
      );

  List<String> get lowConfidenceFields {
    try {
      return (jsonDecode(lowConfidence) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  String get primaryPhone => phoneMobile.isNotEmpty ? phoneMobile : phoneOffice;
  String get initial => name.isNotEmpty ? String.fromCharCode(name.runes.first) : '?';
}
