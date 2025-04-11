import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../config/env.dart';

class BaseApiService {
  final StorageService storageService;
  final String baseUrl = Env.apiBaseUrl;

  BaseApiService(this.storageService);

  Future<http.Response> authenticatedGet(String endpoint) async {
    final headers = await storageService.getAuthHeaders();
    print('\nMaking request to: $baseUrl$endpoint');
    print('Method: GET');
    print('Request headers: $headers');

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    return response;
  }

  Future<http.Response> authenticatedPost(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await storageService.getAuthHeaders();
    print('\nMaking request to: $baseUrl$endpoint');
    print('Method: POST');
    print('Request headers: $headers');
    print('Request body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    return response;
  }
}
