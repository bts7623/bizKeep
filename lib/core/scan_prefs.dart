import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 명함 이미지 스캔 질감 설정 (iOS: ios/Runner/ScanKit.swift). 켜면 촬영·앨범 등록 시 조명 평탄화·종이 톤·샤픈 적용.
class ScanPrefsNotifier extends StateNotifier<bool> {
  ScanPrefsNotifier() : super(true) {
    SharedPreferences.getInstance().then((p) => state = p.getBool(_k) ?? true);
  }
  static const _k = 'scan_look';

  Future<void> set(bool v) async {
    state = v;
    (await SharedPreferences.getInstance()).setBool(_k, v);
  }
}

final scanLookProvider = StateNotifierProvider<ScanPrefsNotifier, bool>((_) => ScanPrefsNotifier());
