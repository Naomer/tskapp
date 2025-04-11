import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service_taker/applicant_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/env.dart';
import 'package:shimmer/shimmer.dart';

class ApplicantsListScreen extends StatefulWidget {
  final String jobTitle;
  final String jobId;

  const ApplicantsListScreen({
    super.key,
    required this.jobTitle,
    required this.jobId,
  });

  @override
  State<ApplicantsListScreen> createState() => _ApplicantsListScreenState();
}

class _ApplicantsListScreenState extends State<ApplicantsListScreen> {
  late final StorageService _storageService;
  List<dynamic> _applicants = [];
  String? _error;
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    print('ApplicantsListScreen initialized with jobId: ${widget.jobId}');
    _initializeServices();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _storageService = StorageService(prefs);
    _apiService = ApiService(_storageService);
    await _fetchApplicants();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMoreData && !_isLoading) {
        _loadMoreApplicants();
      }
    }
  }

  Future<void> _loadMoreApplicants() async {
    if (_currentPage < _totalPages) {
      _currentPage++;
      await _fetchApplicants(isLoadMore: true);
    }
  }

  Future<void> _fetchApplicants({bool isLoadMore = false}) async {
    try {
      if (!isLoadMore) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      print('\n=== Fetching Applicants Debug Info ===');
      print('Job Title: ${widget.jobTitle}');
      print('Widget Job ID: ${widget.jobId}');

      final response = await _apiService.getApplicantsByJobTitle(
        title: widget.jobTitle,
        page: _currentPage,
        size: 10,
      );

      print('Response from getApplicantsByJobTitle: $response');

      if (response['jobData'] != null) {
        final jobData = Map<String, dynamic>.from(response['jobData']);
        final String actualJobId = jobData['jobId'] ?? widget.jobId;
        print('Found actual jobId: $actualJobId');

        if (actualJobId.isEmpty) {
          throw Exception('No job ID found in response or widget');
        }

        final List<dynamic> rawApplicants =
            List.from(jobData['applicants'] ?? []);

        print('Raw applicants: $rawApplicants');

        final List<Map<String, dynamic>> applicants =
            rawApplicants.map((applicant) {
          final Map<String, dynamic> enrichedApplicant =
              Map<String, dynamic>.from(applicant)..['jobId'] = actualJobId;
          print('Enriched applicant with jobId: ${enrichedApplicant['jobId']}');
          return enrichedApplicant;
        }).toList();

        setState(() {
          if (isLoadMore) {
            _applicants.addAll(applicants);
          } else {
            _applicants = applicants;
          }
          _totalPages = response['totalPages'] ?? 1;
          _hasMoreData = _currentPage < _totalPages;
          _isLoading = false;
        });

        // Debug log all applicants
        print('\nAll applicants after update:');
        for (var applicant in _applicants) {
          print(
              'Applicant ID: ${applicant['_id'] ?? applicant['userId']}, Job ID: ${applicant['jobId']}');
        }
      } else {
        setState(() {
          _error = 'Failed to load applicants';
          _isLoading = false;
          _hasMoreData = false;
        });
      }
    } catch (e) {
      print('Error loading applicants: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _hasMoreData = false;
      });
    }
  }

  void _navigateToApplicantDetails(dynamic applicant) {
    if (applicant['userId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to view applicant details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String jobId = applicant['jobId'] ?? widget.jobId;
    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No job ID found for this applicant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('\n=== Navigation Debug Info ===');
    print('Navigating to ApplicantDetailsScreen with:');
    print(
        'Applicant ID: ${applicant['_id'] ?? applicant['id'] ?? applicant['userId']}');
    print('Job ID: $jobId');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicantDetailsScreen(
          applicantId:
              applicant['_id'] ?? applicant['id'] ?? applicant['userId'],
          jobId: jobId,
          applicantData: applicant,
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 80,
                                height: 12,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Applicants for ${widget.jobTitle}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_applicants.length} Applicants',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _applicants.isEmpty) {
      return _buildShimmerLoading();
    }

    if (_error != null && _applicants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red[300], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _fetchApplicants(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_applicants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No applicants yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Applicants will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchApplicants(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _applicants.length,
        itemBuilder: (context, index) {
          final applicant = _applicants[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplicantDetailsScreen(
                      applicantId: applicant['_id'] ??
                          applicant['id'] ??
                          applicant['userId'],
                      jobId: applicant['jobId'],
                      applicantData: applicant,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            applicant['name'][0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                applicant['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(
                                  DateTime.parse(applicant['applicationDate']),
                                ),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'View',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (applicant['message'] != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        applicant['message'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
