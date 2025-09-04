import 'dart:convert';
import 'dart:html' as html;
import 'network_client.dart';

Future<Map<String, dynamic>> getImplementation(String endpoint) async {
  final url = '${NetworkClient.baseUrl}$endpoint';

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
