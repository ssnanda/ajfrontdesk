import 'package:shared_preferences/shared_preferences.dart';

/// Runtime settings for this iPad: which AJ Core site, which device key, and the staff PIN that protects settings.
class AppConfig {
  AppConfig._();

  static String siteUrl = ''; // normalized API base, e.g. https://example.com/wp-json/ajcore/v1
  static String deviceKey = '';
  static String pin = '';
  static String siteName = '';

  static bool get configured => siteUrl.isNotEmpty && deviceKey.isNotEmpty;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    siteUrl = p.getString('site_url') ?? '';
    deviceKey = p.getString('device_key') ?? '';
    pin = p.getString('pin') ?? '';
    siteName = p.getString('site_name') ?? '';
  }

  static Future<void> save({required String siteUrl, required String deviceKey, required String pin, required String siteName}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('site_url', siteUrl);
    await p.setString('device_key', deviceKey);
    await p.setString('pin', pin);
    await p.setString('site_name', siteName);
    await load();
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    await load();
  }

  /// "wozig.com", "https://wozig.com/" or a full API URL -> "https://wozig.com/wp-json/ajcore/v1".
  static String normalizeSiteUrl(String input) {
    var v = input.trim();
    if (v.isEmpty) throw const FormatException('Enter the site URL.');
    if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(v)) v = 'https://$v';
    final uri = Uri.tryParse(v);
    if (uri == null || uri.host.isEmpty || (!uri.host.contains('.') && uri.host != 'localhost')) {
      throw const FormatException('That site URL is not valid.');
    }
    var path = uri.path.replaceAll(RegExp(r'/+$'), '');
    if (!path.endsWith('/wp-json/ajcore/v1')) path = '$path/wp-json/ajcore/v1';
    return '${uri.scheme}://${uri.authority}$path';
  }
}
