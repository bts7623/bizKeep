import 'package:flutter/services.dart';
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

  static String _digits(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
