import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/job_application.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobsView extends StatefulWidget {
  const JobsView({super.key});

  @override
  State<JobsView> createState() => _JobsViewState();
}

class _JobsViewState extends State<JobsView> {
  late final StorageService _storageService;
  late final ApiService _apiService;
  List<JobApplication>? _applications;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('JobsView initialized'); // Debug print
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _storageService = StorageService(prefs);
    _apiService = ApiService(_storageService);
    await _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final applications = await _apiService.getSentApplications();
      print('Fetched ${applications.length} applications'); // Debug print

      if (mounted) {
        setState(() {
          _applications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching applications: $e'); // Debug print
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchApplications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_applications == null || _applications!.isEmpty) {
      return const Center(
        child: Text('No applications found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _applications!.length,
        itemBuilder: (context, index) {
          final application = _applications![index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    application.job.description,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(application.job.title),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(application.createdAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Message:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(application.message),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
