import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_provider_registration.dart';
import '../models/service_taker_registration.dart';
import '../config/env.dart';

class AuthService {
  final String baseUrl = '${Env.apiBaseUrl}/api/v1/user';

  Future<Map<String, dynamic>> sendVerificationCode(String phoneNumber) async {
    try {
      print('\n=== Sending Verification Code ===');
      print('Request URL: $baseUrl/sendVerificationCode');
      print('Request body: ${json.encode({'phoneNumber': phoneNumber})}');

      final response = await http.post(
        Uri.parse('$baseUrl/sendVerificationCode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'phoneNumber': phoneNumber,
        }),
      );

      print('\nResponse:');
      print('Status code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Verification code sent successfully');
        return {
          'success': true,
          'code': responseData['removeOnProduction'],
        };
      }

      print('Request failed with status: ${response.statusCode}');
      final responseData = json.decode(response.body);
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to send verification code'
      };
    } catch (e, stackTrace) {
      print('\nError sending verification code:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'An error occurred while sending verification code'
      };
    }
  }

  Future<bool> verifyUser(String phoneNumber, String code) async {
    try {
      print('Verifying code for: $phoneNumber'); // Debug log
      final response = await http.post(
        Uri.parse('$baseUrl/verifyUser'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'phoneNumber': phoneNumber,
          'code': code,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['status'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error verifying code: $e'); // Debug log
      return false;
    }
  }

  Future<http.Response> register(
      ServiceProviderRegistration registration) async {
    try {
      print('\n=== Registration Request ===');
      print('URL: $baseUrl/register');

      final requestBody = {
        'role': registration.role,
        'name': registration.name,
        'email': registration.email,
        'password': registration.password,
        'phoneNumber': registration.phoneNumber,
        'services': registration.services,
        'experience': registration.experience,
        'serviceArea': registration.serviceArea,
        'workingHour': registration.workingHour,
        'serviceLicense': registration.serviceLicense,
        'cv': registration.cv,
        'passport': registration.passport,
        'mainProfession': registration.mainProfession,
      };

      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('\nResponse:');
      print('Status code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      return response;
    } catch (e) {
      print('\nError in registration:');
      print('Error: $e');
      rethrow;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      print('\n=== Sending Forget Password Code ===');
      print('Request URL: $baseUrl/sendForgetPasswordCode');
      print('Request body: ${json.encode({'email': email})}');

      final response = await http.post(
        Uri.parse('$baseUrl/sendForgetPasswordCode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      print('\nResponse:');
      print('Status code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['status'] ?? false;
      }
      return false;
    } catch (e, stackTrace) {
      print('\nError in forgot password:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String code, String newPassword) async {
    try {
      print('\n=== Reset Password Request ===');
      print('Request URL: $baseUrl/recoverPassword');
      print('Request body: ${json.encode({
            'email': email,
            'code': code,
            'newPassword': newPassword,
          })}');

      final response = await http.post(
        Uri.parse('$baseUrl/recoverPassword'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );

      print('\nResponse:');
      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');

      final responseData = json.decode(response.body);
      return {
        'success':
            response.statusCode == 200 && (responseData['status'] ?? false),
        'message': responseData['message'] ?? 'An error occurred',
      };
    } catch (e) {
      print('Error in reset password: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  Future<bool> verifyResetCode(String email, String code) async {
    try {
      print('\n=== Verifying Reset Code ===');
      print('Request URL: $baseUrl/recoverPassword');
      print('Request body: ${json.encode({
            'email': email,
            'code': code,
            'newPassword':
                'temporary_password_123', // Temporary password for verification
          })}');

      final response = await http.post(
        Uri.parse('$baseUrl/recoverPassword'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'code': code,
          'newPassword': 'temporary_password_123', // Required by API
        }),
      );

      print('\nResponse:');
      print('Status code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      // If code is valid, response will be 200
      return response.statusCode == 200;
    } catch (e) {
      print('Error verifying reset code: $e');
      return false;
    }
  }

  Future<http.Response> registerServiceTaker(
      ServiceTakerRegistration registration) async {
    try {
      print('\n=== Registration Request ===');
      print('URL: $baseUrl/register');
      print('Request body: ${registration.toJson()}');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(registration.toJson()),
      );

      print('\nResponse:');
      print('Status code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      return response;
    } catch (e) {
      print('\nError in registration:');
      print('Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('\nAttempting login for email: $email');
      final String url = '$baseUrl/login';
      print('API URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          if (data['token'] != null && data['user'] != null) {
            return {
              'success': true,
              'data': {
                'token': data['token'],
                'refreshToken': data[
                    'token'], // Using same token as refresh token since API doesn't provide separate refresh token
                'user': data['user'],
              }
            };
          }
        }
      }

      final message = response.statusCode == 401
          ? 'Invalid email or password'
          : 'Login failed. Please check your credentials.';

      print('Login error: $message');
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'An error occurred during login.',
      };
    }
  }
}
