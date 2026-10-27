import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db.dart';
import '../data/ocr_parser.dart';
import 'providers.dart';

/// 수신 전화 식별 (iOS Call Directory Extension). 연락처가 바뀔 때마다 App Group 파일을 갱신하고 익스텐션을 리로드한다.
/// 사용자는 설정 > 전화 > 통화 차단 및 발신자 확인 에서 "BizKeep 통화 식별" 을 켜야 한다.
abstract final class CallDir {
  static const _ch = MethodChannel('bizkeep/calldir');
  static bool get supported => Platform.isIOS;

  /// 연락처 → [[번호(Int, E.164 숫자만), 라벨]] 오름차순. 같은 번호는 먼저 나온(최근 등록) 사람이 이김.
  static List<List<Object>> entriesOf(Iterable<Contact> contacts) {
    final m = <int, String>{};
    for (final c in contacts) {
      if (c.isMine) continue;
      final label = [c.name, c.company].where((s) => s.isNotEmpty).join(' · ');
      if (label.isEmpty) continue;
      for (final ph in [c.phoneMobile, c.phoneOffice]) {
        final e = OcrParser.toE164(ph);
        if (e == null) continue;
        final n = int.tryParse(e.substring(1));
        if (n == null || n < 100000000) continue;
        m.putIfAbsent(n, () => label);
      }
    }
    final keys = m.keys.toList()..sort();
    return [for (final k in keys) [k, m[k]!]];
  }

  static Future<String> sync(Iterable<Contact> contacts) async {
    if (!supported) return 'unsupported';
    try {
      return (await _ch.invokeMethod<String>('sync', {'entries': entriesOf(contacts)})) ?? 'unknown';
    } on PlatformException catch (e) {
      return 'error: ${e.message}';
    } on MissingPluginException {
      return 'unsupported';
    }
  }

  /// enabled | disabled | unknown | unsupported
  static Future<String> status() async {
    if (!supported) return 'unsupported';
    try {
      return (await _ch.invokeMethod<String>('status')) ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  static Future<bool> openSettings() async {
    if (!supported) return false;
    try {
      return (await _ch.invokeMethod<bool>('openSettings')) ?? false;
    } catch (_) {
      return false;
    }
  }

  static const _promptedKey = 'calldir_prompted';
  static Future<bool> wasPrompted() async => (await SharedPreferences.getInstance()).getBool(_promptedKey) ?? false;
  static Future<void> markPrompted() async => (await SharedPreferences.getInstance()).setBool(_promptedKey, true);
}

/// 익스텐션 켜짐 상태. 설정 화면 진입·앱 복귀 시 invalidate 해서 새로 조회.
final callDirStatusProvider = FutureProvider<String>((_) => CallDir.status());

/// 연락처 변경 → 2초 디바운스 → 익스텐션 데이터 갱신. 앱 어디서든 한 번만 watch 하면 된다.
final callDirSyncProvider = Provider<void>((ref) {
  Timer? t;
  ref.listen<AsyncValue<List<Contact>>>(contactsProvider, (_, next) {
    final list = next.value;
    if (list == null) return;
    t?.cancel();
    t = Timer(const Duration(seconds: 2), () => CallDir.sync(list));
  });
  ref.onDispose(() => t?.cancel());
});
