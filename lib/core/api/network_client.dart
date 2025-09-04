// Conditional imports for web vs mobile
import 'network_client_stub.dart'
    if (dart.library.html) 'network_client_web.dart'
    if (dart.library.io) 'network_client_io.dart';

abstract class NetworkClient {
  static const String baseUrl = 'https://nano-hr-api.vercel.app';

  static Future<Map<String, dynamic>> get(String endpoint) async {
    return await getImplementation(endpoint);
  }
}
