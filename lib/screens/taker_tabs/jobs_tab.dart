import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import '../../config/env.dart';
import '../../services/storage_service.dart';
import '../../models/job.dart';
import '../../widgets/custom_navigation_bar.dart';

class FileUploadItem {
  final File file;
  final bool isVideo;
  double progress;
  String? error;
  String? uploadedId;
  bool isUploading;

  FileUploadItem({
    required this.file,
    required this.isVideo,
    this.progress = 0,
    this.error,
    this.uploadedId,
    this.isUploading = false,
  });

  String get fileName => file.path.split('/').last;
}

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final List<FileUploadItem> _mediaItems = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;
  bool _isEmergency = false;
  bool _isLoading = true;
  List<Job> _jobs = [];
  String? _error;
  late StorageService _storageService;
  List<String> _jobPlacePictures = [];
  List<String> _jobPlaceVideos = [];
  String _jobCountry = "saudi"; // Default value

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _fetchCategories();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _storageService = StorageService(prefs);
    _fetchJobs();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() => _isLoadingCategories = true);

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/api/v1/common/getParentCategories'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(data['data']);
            _isLoadingCategories = false;
          });
        }
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading categories: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final headers = await _storageService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/api/v1/serviceTaker/getJobs'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _jobs = (data['data'] as List)
                .map((item) => Job.fromJson(item))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load jobs';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await _storageService.clearTokens();
        setState(() {
          _error = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load jobs';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching jobs: $e');
      setState(() {
        _error = 'Error loading jobs';
        _isLoading = false;
      });
    }
  }

  Future<void> _postJob() async {
    try {
      if (!_formKey.currentState!.validate() || _selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final jobData = {
        "title": _titleController.text.trim(),
        "description": _descriptionController.text.trim(),
        "category": _selectedCategoryId,
        "isEmergency": _isEmergency,
        "location": {
          "address": _addressController.text.trim(),
          "coordinates": [-73.935242, 40.73061]
        },
        "completionDate": _selectedDate!.toIso8601String(),
        "budget": "${_budgetController.text.trim()} USD",
        "jobCountry": _jobCountry,
        "jobPlacePictures": _jobPlacePictures,
        "jobPlaceVideos": _jobPlaceVideos
      };

      print('Posting job with data: ${json.encode(jobData)}');

      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/api/v1/serviceTaker/postJob'),
        headers: await _storageService.getAuthHeaders(),
        body: json.encode(jobData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      Navigator.pop(context); // Hide loading

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF5D7A9A),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Job Posted',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your job service has been posted',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Clear form and media items
                            setState(() {
                              _titleController.clear();
                              _descriptionController.clear();
                              _budgetController.clear();
                              _addressController.clear();
                              _selectedDate = null;
                              _selectedCategoryId = null;
                              _isEmergency = false;
                              // Clear media items and their IDs
                              _mediaItems.clear();
                              _jobPlacePictures.clear();
                              _jobPlaceVideos.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D7A9A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Done',
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
              );
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to post job: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Hide loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting job: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _mediaItems.addAll(
            images.map((image) => FileUploadItem(
                  file: File(image.path),
                  isVideo: false,
                )),
          );
        });
        // Upload each image
        for (var item in _mediaItems
            .where((item) => !item.isVideo && item.uploadedId == null)) {
          await _uploadMedia(item);
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting images'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final videoItem = FileUploadItem(
          file: File(video.path),
          isVideo: true,
        );
        setState(() {
          _mediaItems.add(videoItem);
        });
        await _uploadMedia(videoItem);
      }
    } catch (e) {
      print('Error picking video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadMedia(FileUploadItem item) async {
    try {
      final fileName = item.fileName.toLowerCase();
      final extension = fileName.split('.').last;
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'mp4'];

      if (!allowedExtensions.contains(extension)) {
        item.error = 'Only jpg, jpeg, png, pdf, and video files are allowed';
        setState(() {});
        return;
      }

      setState(() {
        item.isUploading = true;
        item.progress = 0;
        item.error = null;
      });

      final url = '${Env.apiBaseUrl}/api/v1/document/pictureUpload';
      var request = http.MultipartRequest('POST', Uri.parse(url));

      final headers = await _storageService.getAuthHeaders();
      request.headers.addAll({
        ...headers,
        'Accept': 'application/json',
      });

      final mimeType =
          fileName.endsWith('.mp4') ? 'video/mp4' : 'image/$extension';
      final fileStream = item.file.openRead();
      final totalBytes = await item.file.length();

      var bytesUploaded = 0;
      final streamWithProgress = fileStream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            bytesUploaded += data.length;
            setState(() {
              item.progress = bytesUploaded / totalBytes;
            });
            sink.add(data);
          },
        ),
      );

      var multipartFile = http.MultipartFile(
        'files',
        streamWithProgress,
        totalBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200 && jsonData['status'] == true) {
        final List<dynamic> pictureIds = jsonData['data']['picture_ids'];
        if (pictureIds.isNotEmpty) {
          setState(() {
            item.uploadedId = pictureIds[0].toString();
            item.isUploading = false;
            // Add to the appropriate list for job submission
            if (item.isVideo) {
              _jobPlaceVideos.add(item.uploadedId!);
            } else {
              _jobPlacePictures.add(item.uploadedId!);
            }
          });
        } else {
          throw Exception('No picture ID received in response');
        }
      } else {
        final errorMessage = jsonData['message'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() {
        item.error = e.toString().replaceAll('Exception: ', '');
        item.isUploading = false;
      });
    }
  }

  Widget _buildMediaList() {
    final photos = _mediaItems.where((item) => !item.isVideo).toList();
    final videos = _mediaItems.where((item) => item.isVideo).toList();

    return Column(
      children: [
        // Photos Section
        Container(
          height: photos.isEmpty ? 100 : 140,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                onTap: _pickImages,
                leading: const Icon(Icons.photo_library),
                title: const Text('Add Photos'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              if (photos.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) => _buildMediaItem(
                        photos[index], _mediaItems.indexOf(photos[index])),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Videos Section
        Container(
          height: videos.isEmpty ? 100 : 140,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                onTap: _pickVideo,
                leading: const Icon(Icons.videocam),
                title: const Text('Add Video'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              if (videos.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: videos.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) => _buildMediaItem(
                        videos[index], _mediaItems.indexOf(videos[index])),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaItem(FileUploadItem item, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                    image: item.isVideo
                        ? null
                        : DecorationImage(
                            image: FileImage(item.file),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: item.isVideo
                      ? const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Color(0xFF5D7A9A),
                            size: 32,
                          ),
                        )
                      : null,
                ),
                if (item.isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${(item.progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (item.error != null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: -12,
                  top: -12,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        if (item.uploadedId != null) {
                          if (item.isVideo) {
                            _jobPlaceVideos.remove(item.uploadedId);
                          } else {
                            _jobPlacePictures.remove(item.uploadedId);
                          }
                        }
                        _mediaItems.removeAt(index);
                      });
                    },
                  ),
                ),
              ],
            ),
            if (item.isUploading)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: 60,
                  height: 2,
                  child: LinearProgressIndicator(
                    value: item.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF5D7A9A),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Post a Job',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Handle notifications
            },
            icon: const Icon(IconlyLight.notification, color: Colors.black87),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Job Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter job title',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter job title';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Select Job Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _isLoadingCategories
                          ? const SizedBox(
                              height: 56,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Select a category',
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category['_id'],
                                  child: Text(
                                      category['name'] ?? 'Unknown Category'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCategoryId = value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Job Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Write job description...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter job description';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Budget (USD)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _budgetController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          hintText: 'e.g., 300-500',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter budget range';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Completion Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () => _selectDate(context),
                        title: Text(
                          _selectedDate == null
                              ? 'Select completion date'
                              : DateFormat('MMM dd, yyyy')
                                  .format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Is Emergency?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _isEmergency,
                          onChanged: (value) {
                            setState(() {
                              _isEmergency = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter complete address',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter complete address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Add Photos/Videos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMediaList(),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 90),
                      child: ClipPath(
                        clipper: BottomNotchClipper(),
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF556A82),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _postJob,
                              child: Center(
                                child: Text(
                                  'Post',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
