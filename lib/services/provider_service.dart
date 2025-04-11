import 'dart:convert';
import '../models/provider.dart';
import 'base_api_service.dart';
import 'storage_service.dart';

class ProviderService extends BaseApiService {
  ProviderService(StorageService storageService) : super(storageService);

  Future<List<Provider>> getServiceProviders({
    String name = '',
    String services = '',
    String area = '',
    int page = 1,
    int size = 10,
  }) async {
    try {
      final queryParams = {
        'name': name,
        'services': services,
        'area': area,
        'page': page.toString(),
        'size': size.toString(),
      };

      final response = await authenticatedGet(
          '/api/v1/serviceTaker/getServiceProviders?${Uri(queryParameters: queryParams).query}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => Provider.fromJson(item))
              .toList();
        }
      }

      print(
          'Failed to fetch providers. Status: ${response.statusCode}, Body: ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching providers: $e');
      return [];
    }
  }
}
