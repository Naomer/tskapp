import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../config/env.dart';
import '../../services/storage_service.dart';
import '../../models/job.dart';
import '../../widgets/custom_navigation_bar.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _images = [];
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
        "budget": "${_budgetController.text.trim()} USD"
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
                            // Clear form
                            _titleController.clear();
                            _descriptionController.clear();
                            _budgetController.clear();
                            _addressController.clear();
                            setState(() {
                              _selectedDate = null;
                              _selectedCategoryId = null;
                              _isEmergency = false;
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
