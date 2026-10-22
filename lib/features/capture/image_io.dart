import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as im;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SavedImages {
  final String front;
  final String thumb;
  const SavedImages(this.front, this.thumb);
}

/// 촬영 원본 → (가이드 영역 크롭) → 긴 변 1280 JPEG(q85) + 썸네일 320px. 전부 isolate 에서.
abstract final class ImageIo {
  static Future<Directory> cardsDir() async {
    final base = await getApplicationSupportDirectory();
    final d = Directory(p.join(base.path, 'cards'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<SavedImages> processAndSave(Uint8List raw, Rect rel, String id) async {
    final dir = await cardsDir();
    final front = p.join(dir.path, '${id}_front.jpg');
    final thumb = p.join(dir.path, '${id}_thumb.jpg');
    final out = await compute(_process, _Job(raw, rel.left, rel.top, rel.right, rel.bottom));
    await File(front).writeAsBytes(out.front, flush: true);
    await File(thumb).writeAsBytes(out.thumb, flush: true);
    return SavedImages(front, thumb);
  }

  /// 갤러리/수동 선택 이미지용 (크롭 없음)
  static Future<SavedImages> saveFull(Uint8List raw, String id) => processAndSave(raw, const Rect.fromLTRB(0, 0, 1, 1), id);

  /// 이미 크롭·리사이즈된 정면 이미지에서 썸네일만 생성
  static Future<SavedImages> makeThumb(String front, String thumb) async {
    final bytes = await File(front).readAsBytes();
    final out = await compute(_thumbOnly, bytes);
    await File(thumb).writeAsBytes(out, flush: true);
    return SavedImages(front, thumb);
  }
}

Uint8List _thumbOnly(Uint8List raw) {
  final img = im.decodeImage(raw);
  if (img == null) throw StateError('decode failed');
  final th = im.copyResize(img, width: 320, interpolation: im.Interpolation.average);
  return Uint8List.fromList(im.encodeJpg(th, quality: 80));
}

class _Job {
  final Uint8List raw;
  final double l, t, r, b;
  const _Job(this.raw, this.l, this.t, this.r, this.b);
}

class _Out {
  final Uint8List front, thumb;
  const _Out(this.front, this.thumb);
}

_Out _process(_Job j) {
  var img = im.decodeImage(j.raw);
  if (img == null) throw StateError('decode failed');
  img = im.bakeOrientation(img);
  final w = img.width, h = img.height;
  final x = (j.l * w).round().clamp(0, w - 1), y = (j.t * h).round().clamp(0, h - 1);
  final cw = ((j.r - j.l) * w).round().clamp(16, w - x), ch = ((j.b - j.t) * h).round().clamp(16, h - y);
  if (cw < w || ch < h) img = im.copyCrop(img, x: x, y: y, width: cw, height: ch);
  final longest = img.width > img.height ? img.width : img.height;
  if (longest > 1280) {
    img = img.width >= img.height ? im.copyResize(img, width: 1280, interpolation: im.Interpolation.average) : im.copyResize(img, height: 1280, interpolation: im.Interpolation.average);
  }
  final front = Uint8List.fromList(im.encodeJpg(img, quality: 85));
  final th = im.copyResize(img, width: 320, interpolation: im.Interpolation.average);
  final thumb = Uint8List.fromList(im.encodeJpg(th, quality: 80));
  return _Out(front, thumb);
}
