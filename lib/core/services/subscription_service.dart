import 'dart:convert';
import 'dart:io';
import '../models/vpn_config.dart';
import '../../protocols/xray/vless_parser.dart';

class SubscriptionService {
  Future<List<VpnConfig>> fetchSubscription(String url) async {
    final uri = Uri.parse(url);
    final httpClient = HttpClient();

    String body;
    try {
      final request = await httpClient.getUrl(uri);
      request.headers.set('User-Agent', 'TeapodStream/1.0');
      final response = await request.close().timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch subscription: ${response.statusCode}');
      }

      body = await response.transform(utf8.decoder).join();
    } finally {
      httpClient.close();
    }

    body = body.trim();
    List<String> lines;

    // Try base64 decode first
    try {
      // Normalize base64 padding before decode
      final padded = body.padRight((body.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Decode(padded));
      lines = decoded.split('\n').where((l) => l.trim().isNotEmpty).toList();
    } catch (_) {
      // Plain text with links separated by newlines
      lines = body.split('\n').where((l) => l.trim().isNotEmpty).toList();
    }

    final configs = <VpnConfig>[];
    for (final line in lines) {
      final trimmed = line.trim();
      try {
        final config = VlessParser.parseUri(trimmed);
        if (config != null) configs.add(config);
      } catch (_) {
        // Skip unparseable lines
      }
    }
    return configs;
  }
}
