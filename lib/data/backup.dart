import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/image_paths.dart';
import '../features/capture/image_io.dart';
import 'contact_repo.dart';
import 'db.dart';

/// 백업/복원. 포맷(zip 하나):
///   contacts.json   — 전체 레코드(내 명함 포함) + 회사 즐겨찾기. 가져오기는 이 파일을 쓴다.
///   contacts.csv    — 사람이 보기 위한 표 (UTF-8 BOM, 엑셀에서 바로 열림). 내 명함 제외.
///   images/회사_이름_직책.jpg, my_cards/1.jpg — 사진은 그냥 JPG. 파일명은 사람이 알아볼 수 있게.
/// 복원 규칙: UUID 같으면 updated_at 이 더 최신인 쪽을 남김(같으면 건너뜀), 없으면 추가. 메모·즐겨찾기는 최신 쪽 기준.
class BackupResult {
  const BackupResult({this.added = 0, this.updated = 0, this.skipped = 0, this.error});
  final int added, updated, skipped;
  final String? error;
}

abstract final class Backup {
  static const version = 1;

  /// zip 파일을 만들어 경로를 돌려준다 (임시 디렉터리). 호출자가 공유 시트로 넘긴다.
  static Future<File> export(AppDb db) async {
    final contacts = await (db.select(db.contacts)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    final favs = await (db.select(db.companyPrefs)..where((t) => t.favorite.equals(true))).get();
    final now = DateTime.now();
    final stamp = '${now.year}-${_pad2(now.month)}-${_pad2(now.day)}';

    final usedNames = <String>{};
    final jsonContacts = <Map<String, Object?>>[];
    final files = <_ZipFile>[]; // (zip 안 경로, 실제 파일 경로)
    var mineIdx = 0;
    for (final c in contacts) {
      String? zipFront, zipBack;
      if (c.isMine) {
        if (c.imageFront != null) {
          mineIdx++;
          zipFront = 'my_cards/$mineIdx.jpg';
          files.add(_ZipFile(zipFront, ImagePaths.resolve(c.imageFront!)));
        }
      } else {
        final base = _uniqueName(_safeName([c.company, c.name, c.title].where((s) => s.isNotEmpty).join('_')), usedNames);
        if (c.imageFront != null) {
          zipFront = 'images/$base.jpg';
          files.add(_ZipFile(zipFront, ImagePaths.resolve(c.imageFront!)));
        }
        if (c.imageBack != null) {
          zipBack = 'images/${base}_back.jpg';
          files.add(_ZipFile(zipBack, ImagePaths.resolve(c.imageBack!)));
        }
      }
      jsonContacts.add({
        'id': c.id, 'name': c.name, 'company': c.company, 'department': c.department, 'title': c.title,
        'phoneMobile': c.phoneMobile, 'phoneOffice': c.phoneOffice, 'fax': c.fax, 'email': c.email,
        'address': c.address, 'website': c.website, 'memo': c.memo,
        'imageFront': zipFront, 'imageBack': zipBack,
        'ocrRaw': c.ocrRaw, 'source': c.source, 'lowConfidence': c.lowConfidence,
        'favorite': c.favorite, 'isMine': c.isMine,
        'createdAt': c.createdAt, 'updatedAt': c.updatedAt,
      });
    }
    final meta = {
      'app': 'BizKeep', 'version': version, 'exportedAt': now.toIso8601String(),
      'count': contacts.where((c) => !c.isMine).length,
      'companyFavorites': favs.map((f) => f.key).toList(),
      'contacts': jsonContacts,
    };

    final tmp = await getTemporaryDirectory();
    final out = File(p.join(tmp.path, 'BizKeep_$stamp.zip'));
    await compute(_writeZip, _ZipJob(out.path, jsonEncode(meta), _csv(contacts.where((c) => !c.isMine)), files));
    return out;
  }

  /// zip 파일에서 복원. 진행 중 UI 를 막지 않도록 압축 해제는 isolate.
  static Future<BackupResult> import(AppDb db, ContactRepo repo, String zipPath) async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory(p.join(tmp.path, 'restore_${DateTime.now().millisecondsSinceEpoch}'));
    await dir.create(recursive: true);
    try {
      final jsonText = await compute(_extractZip, _ExtractJob(zipPath, dir.path));
      if (jsonText == null) return const BackupResult(error: 'contacts.json 이 없는 파일이에요');
      final meta = jsonDecode(jsonText) as Map<String, dynamic>;
      if (meta['app'] != 'BizKeep') return const BackupResult(error: 'BizKeep 백업 파일이 아니에요');
      final list = (meta['contacts'] as List).cast<Map<String, dynamic>>();
      final existing = {for (final c in await db.select(db.contacts).get()) c.id: c};
      final cards = await ImageIo.cardsDir();
      var added = 0, updated = 0, skipped = 0;

      for (final m in list) {
        final id = m['id'] as String;
        final updatedAt = (m['updatedAt'] as num?)?.toInt() ?? 0;
        final old = existing[id];
        if (old != null && old.updatedAt >= updatedAt) {
          skipped++;
          continue;
        }
        // 이미지 복사 (zip 안 상대경로 → cards/<id>_front.jpg)
        Future<String?> copyImg(String? rel, String suffix) async {
          if (rel == null) return null;
          final src = File(p.join(dir.path, rel));
          if (!await src.exists()) return null;
          final dst = File(p.join(cards.path, '${id}_$suffix.jpg'));
          await src.copy(dst.path);
          return dst.path;
        }
        final front = await copyImg(m['imageFront'] as String?, 'front');
        final back = await copyImg(m['imageBack'] as String?, 'back');
        String? thumb;
        if (front != null) {
          final saved = await ImageIo.makeThumb(front, p.join(cards.path, '${id}_thumb.jpg'));
          thumb = saved.thumb;
        }
        final row = ContactsCompanion(
          id: Value(id),
          name: Value((m['name'] as String?) ?? ''), company: Value((m['company'] as String?) ?? ''),
          department: Value((m['department'] as String?) ?? ''), title: Value((m['title'] as String?) ?? ''),
          phoneMobile: Value((m['phoneMobile'] as String?) ?? ''), phoneOffice: Value((m['phoneOffice'] as String?) ?? ''),
          fax: Value((m['fax'] as String?) ?? ''), email: Value((m['email'] as String?) ?? ''),
          address: Value((m['address'] as String?) ?? ''), website: Value((m['website'] as String?) ?? ''),
          memo: Value((m['memo'] as String?) ?? ''),
          imageFront: Value(front == null ? old?.imageFront : ImagePaths.toStored(front)),
          imageBack: Value(back == null ? old?.imageBack : ImagePaths.toStored(back)),
          thumb: Value(thumb == null ? old?.thumb : ImagePaths.toStored(thumb)),
          ocrRaw: Value((m['ocrRaw'] as String?) ?? ''), source: Value((m['source'] as String?) ?? 'import'),
          lowConfidence: Value((m['lowConfidence'] as String?) ?? '[]'),
          favorite: Value((m['favorite'] as bool?) ?? false), isMine: Value((m['isMine'] as bool?) ?? false),
          createdAt: Value((m['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(updatedAt),
        );
        if (old == null) {
          await db.into(db.contacts).insert(row);
          added++;
        } else {
          await (db.update(db.contacts)..where((t) => t.id.equals(id))).write(row);
          updated++;
          // 이전 이미지 파일 정리 (새 이미지로 바뀐 경우만)
          if (front != null) {
            for (final prev in [old.imageFront, old.imageBack, old.thumb]) {
              if (prev != null && !prev.contains(id)) {
                try { await File(ImagePaths.resolve(prev)).delete(); } catch (_) {}
              }
            }
          }
        }
        final c = await repo.get(id);
        if (c != null) await repo.syncPhoneIndex(c);
      }
      for (final k in ((meta['companyFavorites'] as List?) ?? const []).cast<String>()) {
        await repo.setCompanyFavorite(k, true);
      }
      return BackupResult(added: added, updated: updated, skipped: skipped);
    } catch (e) {
      return BackupResult(error: '복원 실패: $e');
    } finally {
      try { await dir.delete(recursive: true); } catch (_) {}
    }
  }

  // ---- helpers ----
  static String _pad2(int n) => n.toString().padLeft(2, '0');

  static String _safeName(String s) {
    final t = s.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return t.isEmpty ? 'card' : (t.length > 60 ? t.substring(0, 60) : t);
  }

  static String _uniqueName(String base, Set<String> used) {
    var n = base;
    var i = 2;
    while (!used.add(n)) {
      n = '${base}_$i';
      i++;
    }
    return n;
  }

  static String _csv(Iterable<Contact> rows) {
    String esc(String v) {
      final needs = v.contains(',') || v.contains('"') || v.contains('\n');
      final s = v.replaceAll('"', '""');
      return needs ? '"$s"' : s;
    }
    final b = StringBuffer('﻿'); // BOM — 엑셀 한글 깨짐 방지
    b.writeln('이름,회사,부서,직책,휴대전화,사무실,팩스,이메일,주소,웹,메모,즐겨찾기,등록일');
    for (final c in rows) {
      final d = DateTime.fromMillisecondsSinceEpoch(c.createdAt);
      b.writeln([
        c.name, c.company, c.department, c.title, c.phoneMobile, c.phoneOffice, c.fax, c.email, c.address, c.website, c.memo,
        c.favorite ? 'Y' : '', '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}',
      ].map(esc).join(','));
    }
    return b.toString();
  }
}

class _ZipFile {
  const _ZipFile(this.zipPath, this.filePath);
  final String zipPath, filePath;
}

class _ZipJob {
  const _ZipJob(this.outPath, this.json, this.csv, this.files);
  final String outPath, json, csv;
  final List<_ZipFile> files;
}

Future<void> _writeZip(_ZipJob j) async {
  final archive = Archive();
  archive.add(ArchiveFile.string('contacts.json', j.json));
  archive.add(ArchiveFile.string('contacts.csv', j.csv));
  for (final f in j.files) {
    final file = File(f.filePath);
    if (await file.exists()) {
      archive.add(ArchiveFile.bytes(f.zipPath, await file.readAsBytes()));
    }
  }
  final out = ZipEncoder().encodeBytes(archive);
  await File(j.outPath).writeAsBytes(out, flush: true);
}

class _ExtractJob {
  const _ExtractJob(this.zipPath, this.outDir);
  final String zipPath, outDir;
}

/// zip 을 풀고 contacts.json 내용을 돌려준다 (없으면 null)
Future<String?> _extractZip(_ExtractJob j) async {
  final bytes = await File(j.zipPath).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  String? json;
  for (final f in archive) {
    if (!f.isFile) continue;
    final name = f.name.replaceAll('\\', '/');
    if (name.contains('..')) continue; // zip slip 방지
    final data = f.readBytes();
    if (data == null) continue;
    final out = File(p.join(j.outDir, name));
    await out.parent.create(recursive: true);
    await out.writeAsBytes(data, flush: true);
    if (p.basename(name) == 'contacts.json') json = utf8.decode(data);
  }
  return json;
}
