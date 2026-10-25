import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 전화·문자·메일·지도 외부 연동.
abstract final class Act {
  static Future<void> call(String phone) => _launch(Uri(scheme: 'tel', path: _digits(phone)));
  static Future<void> sms(String phone) => _launch(Uri(scheme: 'sms', path: _digits(phone)));
  static Future<void> mail(String email) => _launch(Uri(scheme: 'mailto', path: email));
  static Future<void> map(String address) =>
      _launch(Uri.parse('https://maps.apple.com/?q=${Uri.encodeComponent(address)}'));
  static Future<void> web(String url) =>
      _launch(Uri.parse(url.startsWith('http') ? url : 'https://$url'));
  static Future<void> copy(String text) => Clipboard.setData(ClipboardData(text: text));

  /// iOS 공유 시트 — 이미지 저장·복사·에어드롭·메신저 전송을 한 번에.
  static Future<void> shareImages(List<String> paths, {Rect? origin}) =>
      SharePlus.instance.share(ShareParams(files: [for (final p in paths) XFile(p, mimeType: 'image/jpeg')], sharePositionOrigin: origin));

  static String _digits(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
