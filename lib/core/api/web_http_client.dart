import 'dart:convert';
import 'dart:html' as html;

class WebHttpClient {
  static const String _baseUrl = 'https://nano-hr-api.vercel.app';

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = '$_baseUrl$endpoint';

    print('🌐 Web HTTP GET: $url');

    try {
      final response = await html.window.fetch(url, {
        'method': 'GET',
        'headers': {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        'mode': 'cors',
      });

      print('🌐 Web fetch response status: ${response.status}');

      if (response.status == 200) {
        final text = await response.text();
        print('🌐 Web fetch response length: ${text.length}');
        print('🌐 Web fetch response preview: ${text.substring(0, 200)}...');

        final data = json.decode(text);
        return data;
      } else {
        throw Exception(
          'Web fetch failed: ${response.status} ${response.statusText}',
        );
      }
    } catch (e) {
      print('❌ Web fetch error: $e');
      print('❌ Web fetch error type: ${e.runtimeType}');
      rethrow;
    }
  }
}
