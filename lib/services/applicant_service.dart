import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/applicant.dart';
import '../services/storage_service.dart';
import '../config/env.dart';

class ApplicantService {
  final String baseUrl = '${Env.apiBaseUrl}/api/v1/serviceTaker';
  final StorageService _storageService;

  ApplicantService(SharedPreferences prefs)
      : _storageService = StorageService(prefs);

  Future<List<Applicant>> getApplicants() async {
    try {
      final token = await _storageService.getAccessToken();

      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('Fetching applicants with token: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/getApplicants'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return (data['data'] as List)
            .map((json) => Applicant.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404 &&
          data['message'] == 'No jobs found') {
        // Return empty list instead of throwing error for no jobs
        return [];
      }

      throw Exception(data['message'] ?? 'Failed to load applicants');
    } catch (e) {
      print('Error getting applicants: $e');
      rethrow;
    }
  }
}
