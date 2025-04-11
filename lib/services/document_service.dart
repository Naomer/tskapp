import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../config/env.dart';

class DocumentService {
  final String baseUrl = '${Env.apiBaseUrl}/api/v1/document';

  Future<String?> uploadDocument(File file) async {
    try {
      print('Uploading document...');

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      // Add file to request
      var fileStream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile('file', fileStream, length,
          filename: file.path.split('/').last);
      request.files.add(multipartFile);

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print('Upload response status: ${response.statusCode}');
      print('Upload response: $responseData');

      if (response.statusCode == 201) {
        // Parse response and return document ID
        return responseData;
      }
      return null;
    } catch (e) {
      print('Error uploading document: $e');
      return null;
    }
  }
}
