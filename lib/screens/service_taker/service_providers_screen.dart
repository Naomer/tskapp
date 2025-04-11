import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../../models/service_provider.dart';
import 'package:iconly/iconly.dart';
import 'provider_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/env.dart';
import '../../services/storage_service.dart';
import '../../services/provider_service.dart';
import 'package:shimmer/shimmer.dart';

class ServiceProvidersScreen extends StatefulWidget {
  final String serviceCategory;

  const ServiceProvidersScreen({
    super.key,
    required this.serviceCategory,
  });

  @override
  State<ServiceProvidersScreen> createState() => _ServiceProvidersScreenState();
}

class _ServiceProvidersScreenState extends State<ServiceProvidersScreen> {
  bool _isLoading = true;
  List<ServiceProvider> _providers = [];
  String? _error;
  late StorageService _storageService;
  late ProviderService _providerService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _storageService = StorageService(prefs);
    _providerService = ProviderService(_storageService);
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final providers = await _providerService.getServiceProviders(
        services: widget.serviceCategory,
        page: 1,
        size: 10,
      );

      if (providers.isEmpty) {
        setState(() {
          _error = 'No providers found for this service';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _providers = providers
            .map((p) => ServiceProvider(
                  id: p.id,
                  name: p.name,
                  profession: p.profession,
                  imageUrl: p.image,
                  rating: p.rating,
                  services: [], // Required field but we don't need it in the UI
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching providers: $e');
      setState(() {
        _error = 'Error loading providers';
        _isLoading = false;
      });
    }
  }

  Widget _buildRatingStars(double? rating) {
    final actualRating = rating ?? 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(3, (index) {
          if (index < actualRating.floor()) {
            return Icon(Icons.star, size: 12, color: Colors.amber[700]);
          } else if (index == actualRating.floor() && actualRating % 1 > 0) {
            return Icon(Icons.star_half, size: 12, color: Colors.amber[700]);
          }
          return Icon(Icons.star_border, size: 12, color: Colors.amber[700]);
        }),
        const SizedBox(width: 1),
        Text(
          actualRating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.white,
                          ),
                          const Spacer(),
                          Container(
                            width: 50,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
        leading: Container(
          margin: const EdgeInsets.all(6),
          padding: EdgeInsets.zero,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 241, 247, 248),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.black,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          widget.serviceCategory,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement filter
            },
            icon: const Icon(IconlyLight.filter, color: Colors.black87),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement search
            },
            icon: const Icon(IconlyLight.search, color: Colors.black87),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _error != null
              ? Center(child: Text(_error!))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _providers.length,
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderDetailsScreen(
                              providerId: provider.id,
                              name: provider.name,
                              profession: provider.profession,
                              imageUrl: provider.imageUrl,
                              rating: provider.rating,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Container
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                image: provider.imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(provider.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: provider.imageUrl == null
                                  ? Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                    )
                                  : null,
                            ),
                            // Info Container
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    provider.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    provider.profession ?? 'Not specified',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      _buildRatingStars(provider.rating),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Details',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
