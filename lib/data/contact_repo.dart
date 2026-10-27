import 'dart:convert';

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/image_paths.dart';
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

  // ---- 중복 명함 ----

  /// 같은 사람 판정: 휴대전화 → 이메일 → 이름+회사(정규화). 내 명함·자기 자신 제외.
  static bool isSamePerson(Contact a, Contact b) {
    if (a.id == b.id || a.isMine || b.isMine) return false;
    final am = _digits(a.phoneMobile), bm = _digits(b.phoneMobile);
    if (am.length >= 9 && am == bm) return true;
    final ae = a.email.trim().toLowerCase(), be = b.email.trim().toLowerCase();
    if (ae.isNotEmpty && ae == be) return true;
    if (a.name.isNotEmpty && a.name == b.name && companyKey(a.company).isNotEmpty && companyKey(a.company) == companyKey(b.company)) return true;
    return false;
  }

  /// 명함 필드 중 달라진 것: (라벨, 기존값, 새값). 메모·이미지는 비교 안 함.
  /// 새 명함에 없는(빈) 필드는 교체해도 기존 값을 유지하므로 차이로 치지 않는다.
  static List<(String, String, String)> diffFields(Contact old, Contact fresh) {
    final pairs = <(String, String, String)>[
      ('이름', old.name, fresh.name), ('회사', old.company, fresh.company), ('부서', old.department, fresh.department),
      ('직책', old.title, fresh.title), ('휴대전화', old.phoneMobile, fresh.phoneMobile), ('사무실', old.phoneOffice, fresh.phoneOffice),
      ('팩스', old.fax, fresh.fax), ('이메일', old.email, fresh.email), ('주소', old.address, fresh.address), ('웹', old.website, fresh.website),
    ];
    return [for (final p in pairs) if (p.$3.trim().isNotEmpty && p.$2.trim() != p.$3.trim()) p];
  }

  /// [fresh] 와 같은 사람인 기존 레코드 (가장 최근 것). 없으면 null.
  Future<Contact?> findDuplicate(Contact fresh) async {
    final all = await (db.select(db.contacts)..where((t) => t.isMine.equals(false))..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    for (final c in all) {
      if (isSamePerson(c, fresh)) return c;
    }
    return null;
  }

  /// 기존 레코드를 새 명함 내용으로 교체: 새 값이 비어 있지 않으면 덮어쓰고, 메모·즐겨찾기·등록일은 유지.
  /// 이미지는 새 것으로 바꾸고(이전 파일 경로 반환 — 호출자가 삭제), 새 레코드는 지운다. 반환: 남는(기존) id.
  Future<List<String>> replaceWith({required Contact old, required Contact fresh}) async {
    String pick(String o, String n) => n.trim().isEmpty ? o : n.trim();
    final oldImages = [old.imageFront, old.imageBack, old.thumb].whereType<String>().toList();
    final hasNewImage = fresh.imageFront != null;
    final merged = old.copyWith(
      name: pick(old.name, fresh.name), company: pick(old.company, fresh.company), department: pick(old.department, fresh.department),
      title: pick(old.title, fresh.title), phoneMobile: pick(old.phoneMobile, fresh.phoneMobile), phoneOffice: pick(old.phoneOffice, fresh.phoneOffice),
      fax: pick(old.fax, fresh.fax), email: pick(old.email, fresh.email), address: pick(old.address, fresh.address), website: pick(old.website, fresh.website),
      memo: old.memo.isEmpty ? fresh.memo : old.memo,
      imageFront: hasNewImage ? Value(fresh.imageFront) : Value(old.imageFront),
      imageBack: hasNewImage ? Value(fresh.imageBack) : Value(old.imageBack),
      thumb: hasNewImage ? Value(fresh.thumb) : Value(old.thumb),
      ocrRaw: fresh.ocrRaw.isEmpty ? old.ocrRaw : fresh.ocrRaw,
      source: fresh.source,
      lowConfidence: fresh.lowConfidence,
    );
    await update(merged);
    // 새 레코드는 이미지 소유권을 넘겼으니 파일은 두고 행만 삭제
    await delete(fresh.id);
    return hasNewImage ? oldImages : const [];
  }

  static String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

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

  /// 레코드 + 명함 이미지 파일 삭제.
  Future<void> deleteWithImages(Contact c) async {
    for (final p in [c.imageFront, c.imageBack, c.thumb]) {
      if (p != null) {
        try { await File(ImagePaths.resolve(p)).delete(); } catch (_) {}
      }
    }
    await delete(c.id);
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
