import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// iOS는 재설치·업데이트마다 샌드박스 경로가 바뀌므로 DB엔 파일명만 두고 런타임에 조합한다.
abstract final class ImagePaths {
  static String? _cards;

  static Future<void> init() async {
    final base = await getApplicationSupportDirectory();
    final d = Directory(p.join(base.path, 'cards'));
    if (!await d.exists()) await d.create(recursive: true);
    _cards = d.path;
  }

  static String get cardsDir => _cards ?? '';

  /// DB 값(절대경로 또는 파일명) → 현재 유효한 절대경로
  static String resolve(String stored) {
    if (stored.isEmpty) return stored;
    // 파일명만 저장된 정상 케이스: I/O 없이 조합
    if (!stored.startsWith('/')) return p.join(cardsDir, stored);
    // 구버전 절대경로: 살아있으면 그대로, 아니면 현재 샌드박스로 재조합
    if (File(stored).existsSync()) return stored;
    return p.join(cardsDir, p.basename(stored));
  }

  /// 저장용: 파일명만
  static String toStored(String absolute) => p.basename(absolute);
}
