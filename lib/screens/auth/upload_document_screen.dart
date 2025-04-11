import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/service_provider_registration.dart';
import '../../services/document_service.dart';
import 'account_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../../config/env.dart';

class UploadDocumentScreen extends StatefulWidget {
  final ServiceProviderRegistration registration;

  const UploadDocumentScreen({
    super.key,
    required this.registration,
  });

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _documentService = DocumentService();
  bool _isLoading = false;

  // Store file paths temporarily
  File? _serviceLicenseFile;
  File? _passportFile;
  File? _cvFile;

  String? _serviceLicenseError;
  String? _passportError;
  String? _cvError;

  Future<void> _pickDocument(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        if (fileSizeMB > 4) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'File size (${fileSizeMB.toStringAsFixed(1)}MB) exceeds 4MB limit. Please choose a smaller file.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        setState(() {
          switch (type) {
            case 'passport':
              _passportFile = file;
              _passportError = null;
              break;
            case 'cv':
              _cvFile = file;
              _cvError = null;
              break;
            default:
              _serviceLicenseFile = file;
              _serviceLicenseError = null;
          }
        });

        // Show success message with file size
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected (${fileSizeMB.toStringAsFixed(1)}MB)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting document'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _uploadFile(File file, String type) async {
    try {
      final fileName = file.path.split('/').last;
      final mimeType = fileName.endsWith('.pdf')
          ? 'application/pdf'
          : 'image/${fileName.split('.').last}';

      print('\n=== Uploading $type ===');
      print('File: $fileName');
      print('MIME Type: $mimeType');
      print('File size: ${await file.length()} bytes');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiBaseUrl}/api/v1/document/upload'),
      );

      request.fields['type'] = type;

      var stream = http.ByteStream(file.openRead());
      var length = await file.length();

      var multipartFile = http.MultipartFile(
        'files',
        stream,
        length,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);
      request.headers.addAll({
        'Accept': 'application/json',
      });

      print('Sending request to upload $type...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Upload response data: $responseData');

        final List<dynamic> fileIds = responseData['data']['file_ids'] ?? [];
        print('File IDs from response: $fileIds');

        if (fileIds.isNotEmpty) {
          final fileId = fileIds[0]; // Get the first file ID
          print('File ID: $fileId');

          // Update registration model with the file ID
          switch (type) {
            case 'passport':
              widget.registration.passport = fileId;
              print('Updated passport ID: ${widget.registration.passport}');
              break;
            case 'cv':
              widget.registration.cv = fileId;
              print('Updated CV ID: ${widget.registration.cv}');
              break;
            case 'serviceLicense':
              widget.registration.serviceLicense = fileId;
              print(
                  'Updated service license ID: ${widget.registration.serviceLicense}');
              break;
          }
          return true;
        } else {
          throw Exception('No file ID in response');
        }
      }

      // Handle specific error codes
      switch (response.statusCode) {
        case 413:
          throw Exception('File size too large');
        case 502:
          throw Exception('Server error. Please try again in a few minutes');
        case 500:
          final errorData = json.decode(response.body);
          throw Exception(errorData['msg'] ?? 'Server error');
        default:
          final errorData = json.decode(response.body);
          throw Exception(errorData.toString());
      }
    } catch (e, stackTrace) {
      print('Error uploading $type:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to upload $type: ${e.toString()}');
    }
  }

  Future<void> _handleNext() async {
    if (_serviceLicenseFile != null &&
        _passportFile != null &&
        _cvFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('\n=== Starting document uploads ===');

        // Upload files one by one
        for (var upload in [
          {'file': _serviceLicenseFile!, 'type': 'serviceLicense'},
          {'file': _passportFile!, 'type': 'passport'},
          {'file': _cvFile!, 'type': 'cv'},
        ]) {
          try {
            final success = await _uploadFile(
              upload['file'] as File,
              upload['type'] as String,
            );
            if (!success) {
              throw Exception('Failed to upload ${upload['type']}');
            }
            // Print updated registration data after each upload
            print('Registration data after ${upload['type']} upload:');
            print(widget.registration.toJson());
          } catch (e) {
            throw Exception(
                'Error uploading ${upload['type']}: ${e.toString()}');
          }
        }

        // Print final registration data before navigation
        print('\nFinal registration data:');
        print(widget.registration.toJson());

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountScreen(
              registration: widget.registration,
            ),
          ),
        );
      } catch (e) {
        print('Error in _handleNext: $e');
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _handleNext,
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        if (_serviceLicenseFile == null) {
          _serviceLicenseError = 'Please upload your service license';
        }
        if (_passportFile == null) {
          _passportError = 'Please upload your passport';
        }
        if (_cvFile == null) {
          _cvError = 'Please upload your CV';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Upload Documents'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please upload the required documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildUploadButton(
                title: 'Service License',
                subtitle: 'Upload your service license (PDF)',
                isUploaded: _serviceLicenseFile != null,
                error: _serviceLicenseError,
                onTap: () => _pickDocument('serviceLicense'),
              ),
              const SizedBox(height: 16),
              _buildUploadButton(
                title: 'Passport',
                subtitle: 'Upload your passport (PDF)',
                isUploaded: _passportFile != null,
                error: _passportError,
                onTap: () => _pickDocument('passport'),
              ),
              const SizedBox(height: 16),
              _buildUploadButton(
                title: 'CV',
                subtitle: 'Upload your CV (PDF)',
                isUploaded: _cvFile != null,
                error: _cvError,
                onTap: () => _pickDocument('cv'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D7A7F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required String? error,
    required VoidCallback onTap,
  }) {
    // Get file info for the current type
    File? selectedFile;
    switch (title) {
      case 'Service License':
        selectedFile = _serviceLicenseFile;
        break;
      case 'Passport':
        selectedFile = _passportFile;
        break;
      case 'CV':
        selectedFile = _cvFile;
        break;
    }

    String? fileName;
    String? fileSize;
    if (selectedFile != null) {
      fileName = selectedFile.path.split('/').last;
      final fileSizeBytes = selectedFile.lengthSync();
      final fileSizeMB = fileSizeBytes / (1024 * 1024);
      fileSize = '${fileSizeMB.toStringAsFixed(1)}MB';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: error != null ? Colors.red : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isUploaded ? Icons.check_circle : Icons.upload_file,
                  color: isUploaded ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (fileName != null) ...[
                        Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fileSize!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ] else
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        'Maximum size: 4MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
