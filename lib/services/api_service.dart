import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/api_response.dart';
import '../utils/app_exceptions.dart';
import '../models/job_application.dart';
import '../models/job_request.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../config/env.dart';
import 'package:flutter/material.dart';

class ApiService {
  final StorageService _storageService;
  final String baseUrl = Env.apiBaseUrl;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  ApiService(this._storageService);

  // Handle token expiration globally
  Future<bool> _handleTokenExpiration(
      http.Response response, BuildContext? context) async {
    if (response.statusCode == 401 || response.statusCode == 408) {
      print('Token expired or invalid');
      await _storageService.clearAll();

      // If context is provided, show snackbar and navigate
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        // Use navigator key for global navigation
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/login', (route) => false);
      }
      return true;
    }
    return false;
  }

  // Add authorization header if token exists
  Future<Map<String, String>> _getHeaders({
    bool requiresAuth = true,
    String? contentType,
  }) async {
    Map<String, String> headers = {
      'Content-Type': contentType ?? 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      String? token;
      // Try up to 3 times to get a valid token
      for (int i = 0; i < 3; i++) {
        token = await _storageService.getAccessToken();
        if (token != null) break;
        await Future.delayed(
            Duration(milliseconds: 100)); // Small delay between retries
      }

      print(
          'Getting token for headers: ${token != null ? "${token.substring(0, 10)}..." : "null"}');

      if (token == null) {
        // One final attempt to refresh the token
        print('No token found, attempting final refresh...');
        token = await _storageService.refreshAccessToken();

        if (token == null) {
          throw ApiException('Authentication required');
        }
      }

      headers['Authorization'] = 'Bearer $token';
    }

    print('Final headers: $headers');
    return headers;
  }

  // Generic HTTP request handler with token refresh
  Future<http.Response> _makeRequest(
    String url,
    String method, {
    Map<String, String>? headers,
    Object? body,
    BuildContext? context,
    bool requiresAuth = true,
  }) async {
    try {
      print('\nMaking request to: $url');
      print('Method: $method');
      if (body != null) print('Body: $body');

      headers = await _getHeaders(requiresAuth: requiresAuth);
      print('Request headers: $headers');

      http.Response response;
      final uri = Uri.parse(url);

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle token expiration
      if (response.statusCode == 401 || response.statusCode == 408) {
        print('Token expired, attempting refresh...');
        final newToken = await _storageService.refreshAccessToken();

        if (newToken != null) {
          // Retry request with new token
          headers['Authorization'] = 'Bearer $newToken';
          print('Retrying request with new token');

          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(uri, headers: headers);
              break;
            case 'POST':
              response = await http.post(uri, headers: headers, body: body);
              break;
            case 'PUT':
              response = await http.put(uri, headers: headers, body: body);
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: headers);
              break;
          }

          print('Retry response status: ${response.statusCode}');
          print('Retry response body: ${response.body}');

          if (response.statusCode == 401 || response.statusCode == 408) {
            await _storageService.clearTokens();
            await _handleTokenExpiration(response, context);
            throw ApiException('Session expired');
          }
        } else {
          await _storageService.clearTokens();
          await _handleTokenExpiration(response, context);
          throw ApiException('Session expired');
        }
      }

      return response;
    } catch (e) {
      print('API request error: $e');
      rethrow;
    }
  }

  // Login with dual token system
  Future<void> login(String email, String password) async {
    try {
      print('\nAttempting login for email: $email');
      print('API URL: ${Env.apiBaseUrl}/api/v1/user/login');

      if (email.isEmpty || password.isEmpty) {
        throw ApiException('Email and password are required');
      }

      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/api/v1/user/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email.trim(),
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        // Extract token and user data from the response
        final token = data['data']['token'];
        final userData = data['data']['user'];

        if (token == null) {
          throw ApiException('No token received from server');
        }

        // Create user object
        final user = User(
          id: userData['_id'],
          name: userData['name'],
          email: userData['email'],
          role: userData['role'],
          phoneNumber: userData['phoneNumber'],
          isPhoneNumberVerified: userData['isPhoneNumberVerified'] ?? false,
          services: List<String>.from(userData['services'] ?? []),
          paymentMethod: List<String>.from(userData['paymentMethod'] ?? []),
          jobsCompleted: userData['jobsCompleted'] ?? 0,
          ratings: userData['ratings'] ??
              {'averageRating': 0, 'numberOfRatings': 0, 'ratingsByUser': []},
        );

        // Clear any existing tokens first
        await _storageService.clearTokens();

        // Save tokens and user data atomically
        await _storageService.saveTokens(
          accessToken: token,
          refreshToken: token,
          accessTokenDuration:
              const Duration(hours: 1), // Match token expiry from server
          user: user,
        );

        // Wait a moment to ensure storage is complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify everything was saved correctly
        if (!await _verifyLoginData()) {
          throw ApiException('Failed to verify saved login data');
        }

        // Double check token is accessible
        final verifyToken = await _storageService.getAccessToken();
        if (verifyToken == null) {
          throw ApiException('Token verification failed');
        }

        print('Login data saved and verified successfully');

        // Return early - let the caller handle navigation
        return;
      } else if (response.statusCode == 401) {
        throw ApiException('Invalid email or password');
      } else if (response.statusCode == 400) {
        throw ApiException(data['message'] ?? 'Bad request');
      } else {
        throw ApiException(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<bool> _verifyLoginData() async {
    final token = await _storageService.getAccessToken();
    final user = _storageService.getUser();
    final role = _storageService.getUserRole();

    print('Verifying login data:');
    print('Token exists: ${token != null}');
    print('User exists: ${user != null}');
    print('Role exists: ${role != null}');

    return token != null && user != null && role != null;
  }

  Future<List<JobRequest>> getJobRequests() async {
    try {
      final response = await _makeRequest(
        '$baseUrl/api/v1/serviceProvider/jobRequests',
        'GET',
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> requests = data['data'];
        return requests.map((json) => JobRequest.fromJson(json)).toList();
      } else if (response.statusCode == 200 &&
          data['message'] == 'No job requests found.') {
        return []; // Return empty list when no job requests are found
      } else {
        throw ApiException(data['message'] ?? 'Failed to fetch job requests');
      }
    } catch (e) {
      print('Error fetching job requests: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch job requests: ${e.toString()}');
    }
  }

  Future<List<JobApplication>> getSentApplications() async {
    try {
      final response = await _makeRequest(
        '$baseUrl/api/v1/serviceProvider/getSentApplications',
        'GET',
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> applications = data['data'];
        return applications
            .map((json) => JobApplication.fromJson(json))
            .toList();
      } else if (response.statusCode == 404 &&
          data['message'] == 'No applications found') {
        return []; // Return empty list when no applications are found
      } else {
        throw ApiException(data['message'] ?? 'Failed to fetch applications');
      }
    } catch (e) {
      print('Error fetching applications: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getJobs({
    int? page,
    int? size,
    String? sort,
    String? categoryId,
    bool? isEmergency,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (size != null) queryParams['size'] = size.toString();
      if (sort != null) queryParams['sort'] = sort;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (isEmergency != null)
        queryParams['isEmergency'] = isEmergency.toString();
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/api/v1/common/getJobs')
          .replace(queryParameters: queryParams);
      final headers = await _getHeaders(requiresAuth: true);

      final response = await http.get(
        uri,
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw ApiException(data['message'] ?? 'Failed to fetch jobs');
      }
    } catch (e) {
      print('Error fetching jobs: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String dateOfBirth,
    required String country,
    String? bio,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'dateOfBirth': dateOfBirth,
        'country': country,
        'bio': bio,
      };

      print('Updating profile with data: $requestBody');

      final response = await _makeRequest(
        '$baseUrl/api/v1/common/updateProfile',
        'POST',
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final userData = data['data'];

        final updatedUser = User(
          id: userData['_id'],
          name: userData['name'],
          email: userData['email'],
          phoneNumber: userData['phoneNumber'] ?? '',
          isPhoneNumberVerified: userData['isPhoneNumberVerified'] ?? false,
          role: userData['role'],
          services: List<String>.from(userData['services'] ?? []),
          paymentMethod: List<String>.from(userData['paymentMethod'] ?? []),
          jobsCompleted: userData['jobsCompleted'] ?? 0,
          ratings: userData['ratings'] ??
              {'averageRating': 0, 'numberOfRatings': 0, 'ratingsByUser': []},
          profileImage: userData['profileImage'],
          dateOfBirth: userData['dateOfBirth'],
          country: userData['country'],
          bio: userData['bio'],
        );

        await _storageService.saveUser(updatedUser);
        return data;
      } else {
        throw ApiException(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Update profile error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getProviderDetails(String providerId) async {
    try {
      print('Getting provider details for ID: $providerId');

      if (providerId.isEmpty) {
        throw Exception('Provider ID cannot be empty');
      }

      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/v1/serviceTaker/getProviderDetails/$providerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to load provider details');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception(
            'Failed to load provider details. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('API Service error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error fetching provider details: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to perform request: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getJobDetails(String jobId) async {
    try {
      final response = await _makeRequest(
        '$baseUrl/api/v1/serviceProvider/getJobDetails/$jobId',
        'GET',
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return data['data'];
      } else {
        throw ApiException(data['message'] ?? 'Failed to load job details');
      }
    } catch (e) {
      print('Error fetching job details: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getApplicantsByJobTitle({
    required String title,
    int page = 1,
    int size = 10,
  }) async {
    try {
      final queryParams = {
        'title': title,
        'page': page.toString(),
        'size': size.toString(),
      };

      final response = await _makeRequest(
        '$baseUrl/api/v1/serviceTaker/getApplicantsByJobTitle?${Uri(queryParameters: queryParams).query}',
        'GET',
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'jobData': data['data'][0], // First item contains all the job info
          'totalApplicants': data['totalApplicants'],
          'currentPage': data['page'],
          'totalPages': data['data'][0]['totalPages'],
        };
      } else {
        throw ApiException(data['message'] ?? 'Failed to fetch applicants');
      }
    } catch (e) {
      print('Error fetching applicants by job title: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getApplicants({
    required String jobId,
    int page = 1,
    int size = 10,
  }) async {
    try {
      final headers = await _storageService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(
            '${baseUrl}/api/v1/serviceTaker/getApplicants/$jobId?page=$page&size=$size'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw ApiException('Session expired. Please login again.');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          return {
            'applicants': data['data']['applicants'],
            'totalPages': data['data']['totalPages'],
            'totalApplicants': data['data']['totalApplicants'],
          };
        }
      }

      throw ApiException('Failed to load applicants');
    } catch (e) {
      print('Error getting applicants: $e');
      throw ApiException('Error loading applicants: $e');
    }
  }

  Future<Map<String, dynamic>> getJobTitles({
    int page = 1,
    int size = 10,
  }) async {
    try {
      final headers = await _storageService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(
            '${baseUrl}/api/v1/serviceTaker/getJobTitles?page=$page&size=$size'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw ApiException('Session expired. Please login again.');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          return {
            'jobs': data['data']['jobs'],
            'totalPages': data['data']['totalPages'],
            'totalJobs': data['data']['totalJobs'],
          };
        }
      }

      throw ApiException('Failed to load job titles');
    } catch (e) {
      print('Error getting job titles: $e');
      throw ApiException('Error loading job titles: $e');
    }
  }

  Future<void> acceptApplicant({
    required String jobId,
    required String applicantId,
  }) async {
    try {
      print('\n=== Accept Applicant Debug Info ===');
      print('Job ID: $jobId');
      print('Applicant ID: $applicantId');

      if (jobId.isEmpty) {
        throw ApiException('Job ID is required');
      }
      if (applicantId.isEmpty) {
        throw ApiException('Applicant ID is required');
      }

      final requestBody = {
        'jobId': jobId,
        'applicantId': applicantId,
      };
      print('Request Body: ${json.encode(requestBody)}');

      final response = await _makeRequest(
        '$baseUrl/api/v1/serviceTaker/acceptApplicant',
        'POST',
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 400 &&
          data['message']?.contains('already accepted') == true) {
        throw ApiException('This job already has an accepted applicant');
      }

      if (response.statusCode == 200 && data['status'] == true) {
        return;
      }

      throw ApiException(data['message'] ?? 'Failed to accept applicant');
    } catch (e) {
      print('Error accepting applicant: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitBid({
    required String jobId,
    required int bidAmount,
    required DateTime proposedCompletionDate,
    required String message,
  }) async {
    try {
      print('\nSubmitting bid for job: $jobId');
      print('Bid Amount: $bidAmount');
      print('Proposed Completion Date: $proposedCompletionDate');
      print('Message: $message\n');

      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/serviceProvider/applyForJob/$jobId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bidAmount': bidAmount,
          'proposedCompletionDate': proposedCompletionDate.toIso8601String(),
          'message': message,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData.toString());
      }
    } catch (e) {
      print('Error submitting bid: $e');
      rethrow;
    }
  }
}
