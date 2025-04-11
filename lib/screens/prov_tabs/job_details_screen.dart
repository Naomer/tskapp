import 'package:flutter/material.dart';
import '../../models/job.dart';
import 'package:iconly/iconly.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import './bid_screen.dart';
import '../../config/env.dart';
import '../../config/constants.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isLoading = true;
  Job? _jobDetails;
  String? _error;
  late StorageService _storageService;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _storageService = StorageService(prefs);
    _apiService = ApiService(_storageService);
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Fetching job details for ID: ${widget.jobId}');
      final result = await _apiService.getJobs();
      print('API Response: $result');

      if (result is Map<String, dynamic>) {
        print('Response status: ${result['status']}');
        print('Response data: ${result['data']}');

        if (result['status'] == true && result['data'] != null) {
          final List<dynamic> jobs = result['data'];
          print('Found ${jobs.length} jobs');
          print('Looking for job with ID: ${widget.jobId}');

          final job = jobs.firstWhere(
            (j) => j['_id'] == widget.jobId,
            orElse: () => throw Exception('Job not found'),
          );
          print('Found job: $job');

          setState(() {
            _jobDetails = Job.fromJson(job);
            _isLoading = false;
          });
        } else {
          throw Exception(
              'Invalid response format: status=${result['status']}, data=${result['data']}');
        }
      } else {
        print('Unexpected response type: ${result.runtimeType}');
        throw Exception('Unexpected response format');
      }
    } catch (e, stackTrace) {
      print('Error fetching job details: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = 'Error loading job details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchJobDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                image: const DecorationImage(
                  image: NetworkImage(AppConstants.sampleJobImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Safe area for back button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
            // Curved body content
            Container(
              margin: const EdgeInsets.only(top: 280),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      _jobDetails?.title ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            offset: const Offset(0, 3),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Verified User
                          Column(
                            children: [
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 80, 79, 79),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'User',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          // Budget
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              const Text(
                                'Budget',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 80, 79, 79),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _jobDetails?.budget ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          // Years of Service
                          Column(
                            children: [
                              const Text(
                                '4 Years',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 80, 79, 79),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Service User',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Emergency Status
                    if (_jobDetails?.isEmergency == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Emergency Job',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Booking Date
                    const Text(
                      'Booking Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Date Card
                        Container(
                          width: 110,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                offset: const Offset(0, 3),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Text(
                            _jobDetails?.completionDate != null
                                ? DateFormat('MMM dd, yyyy')
                                    .format(_jobDetails!.completionDate)
                                : '-',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Time Card
                        Container(
                          width: 110,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                offset: const Offset(0, 3),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Text(
                            _jobDetails?.completionDate != null
                                ? DateFormat('hh:mm a')
                                    .format(_jobDetails!.completionDate)
                                : '-',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Details
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _jobDetails?.description ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Location
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(IconlyLight.location,
                              color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _jobDetails?.location.address ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: ElevatedButton(
          onPressed: () => _navigateToBidScreen(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 79, 160, 231),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Bid For The Job',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToBidScreen() {
    if (_jobDetails == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BidScreen(
          jobId: widget.jobId,
          jobTitle: _jobDetails!.title,
        ),
      ),
    );
  }
}

class DownwardCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, 0);
    path.lineTo(0, size.height - 50);

    var firstControlPoint = Offset(size.width / 4, size.height - 80);
    var firstEndPoint = Offset(size.width / 2, size.height);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint =
        Offset(size.width - (size.width / 4), size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
