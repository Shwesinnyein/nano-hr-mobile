import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class HttpClient {
  static const String _baseUrl = 'https://nano-hr-api.vercel.app';

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');

    print('🔄 HTTP GET: $url');

    try {
      // Try web-specific fetch first
      if (html.window.navigator.userAgent.contains('Chrome') ||
          html.window.navigator.userAgent.contains('Firefox') ||
          html.window.navigator.userAgent.contains('Safari')) {
        print('🌐 Using web fetch...');
        return await _webFetch(url.toString());
      }

      // Fallback to regular HTTP
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('✅ HTTP Response: ${response.statusCode}');
      print('✅ Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('❌ HTTP Error: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _webFetch(String url) async {
    try {
      print('🌐 Web fetch: $url');
      final response = await html.window.fetch(url, {
        'method': 'GET',
        'headers': {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      });

      print('🌐 Web fetch response status: ${response.status}');

      if (response.status == 200) {
        final text = await response.text();
        print('🌐 Web fetch response length: ${text.length}');
        final data = json.decode(text);
        return data;
      } else {
        throw Exception('Web fetch failed: ${response.status}');
      }
    } catch (e) {
      print('❌ Web fetch error: $e');
      rethrow;
    }
  }
}
