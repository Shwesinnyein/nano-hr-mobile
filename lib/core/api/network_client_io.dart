import 'dart:convert';
import 'package:http/http.dart' as http;
import 'network_client.dart';

Future<Map<String, dynamic>> getImplementation(String endpoint) async {
  final url = Uri.parse('${NetworkClient.baseUrl}$endpoint');

  print('📱 Mobile HTTP GET: $url');

  final response = await http.get(
    url,
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  );

  print('✅ Mobile HTTP Response: ${response.statusCode}');

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data;
  } else {
    throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
  }
}
