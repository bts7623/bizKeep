import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'db.g.dart';

class Contacts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get company => text().withDefault(const Constant(''))();
  TextColumn get department => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get phoneMobile => text().withDefault(const Constant(''))();
  TextColumn get phoneOffice => text().withDefault(const Constant(''))();
  TextColumn get fax => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get website => text().withDefault(const Constant(''))();
  TextColumn get memo => text().withDefault(const Constant(''))();
  TextColumn get imageFront => text().nullable()();
  TextColumn get imageBack => text().nullable()();
  TextColumn get thumb => text().nullable()();
  TextColumn get ocrRaw => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get lowConfidence => text().withDefault(const Constant('[]'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  /// 즐겨찾기 (목록 상단 고정)
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  /// 내 명함 (목록·검색 제외, 내 명함 시트에서만)
  BoolColumn get isMine => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 회사 단위 설정 (즐겨찾기). key 는 ContactRepo.companyKey() 정규화 값.
class CompanyPrefs extends Table {
  TextColumn get key => text()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Contacts, CompanyPrefs])
class AppDb extends _$AppDb {
  AppDb() : super(_open());
  AppDb.test(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX IF NOT EXISTS idx_contacts_created ON contacts(created_at DESC)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_contacts_name ON contacts(name)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_contacts_company ON contacts(company)');
          // 통화 식별 익스텐션용 번호 인덱스 (E.164)
          await customStatement('CREATE TABLE IF NOT EXISTS phone_index (phone_e164 TEXT PRIMARY KEY, contact_id TEXT NOT NULL)');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(contacts, contacts.favorite);
            await m.addColumn(contacts, contacts.isMine);
            await m.createTable(companyPrefs);
          }
        },
        beforeOpen: (d) async {
          await customStatement('PRAGMA journal_mode=WAL');
          await customStatement('PRAGMA synchronous=NORMAL');
        },
      );

  static LazyDatabase _open() => LazyDatabase(() async {
        final dir = await getApplicationSupportDirectory();
        final file = File(p.join(dir.path, 'bizkeep.sqlite'));
        return NativeDatabase.createInBackground(file);
      });
}
