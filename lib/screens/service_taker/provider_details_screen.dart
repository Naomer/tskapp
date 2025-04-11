import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'provider_gallery_screen.dart';
import '../../widgets/custom_navigation_bar.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final String providerId;
  final String name;
  final String? profession;
  final String? imageUrl;
  final double? rating;

  const ProviderDetailsScreen({
    super.key,
    required this.providerId,
    required this.name,
    this.profession,
    this.imageUrl,
    this.rating,
  });

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  late final StorageService _storageService;
  late final ApiService _apiService;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _providerDetails;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _storageService = StorageService(prefs);
    _apiService = ApiService(_storageService);
    await _fetchProviderDetails();
  }

  Future<void> _fetchProviderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (widget.providerId.isEmpty) {
        throw Exception('Provider ID is required');
      }

      print('Fetching details for provider ID: ${widget.providerId}');

      final details = await _apiService.getProviderDetails(widget.providerId);

      print('Received provider details: $details');

      if (mounted) {
        setState(() {
          _providerDetails = details;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error fetching provider details: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading provider details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _extractExperienceNumber(String experience) {
    final RegExp regex = RegExp(r'(\d+\.?\d*)');
    final match = regex.firstMatch(experience);
    return match?.group(1) ?? '0';
  }

  String _formatExperience(String number) {
    final double value = double.tryParse(number) ?? 0;
    return '$number ${value == 1 ? 'year' : 'years'}';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildShimmerLoading() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image Shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 330,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Profession Shimmer
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: 200,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: 150,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats Row Shimmer
                      Row(
                        children: List.generate(
                            3,
                            (index) => Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      right: index < 2 ? 12 : 0,
                                    ),
                                    child: Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                )).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Skills Section Shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 100,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                            6,
                            (index) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: 80,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                )),
                      ),
                      const SizedBox(height: 24),

                      // Bio Section Shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 80,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: List.generate(
                            3,
                            (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                )),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Back Button Shimmer
          Positioned(
            top: 40,
            left: 16,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Book Button Shimmer
          Positioned(
            left: 8,
            right: 8,
            bottom: 16,
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: ClipPath(
                  clipper: BottomNotchClipper(),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _fetchProviderDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Use _providerDetails to display the data
    final details = _providerDetails;
    final experience = details?['experience'] ?? '0';
    final experienceNumber = _extractExperienceNumber(experience);
    final formattedExperience = _formatExperience(experienceNumber);
    final services = List<String>.from(details?['services'] ?? []);
    final mainProfession = details?['mainProfession'] ?? 'Not specified';
    final serviceArea = details?['serviceArea'] ?? 'Not specified';
    final workingHour = details?['workingHour'] ?? 'Not specified';
    final averageRating = (details?['averageRating'] ?? 0).toDouble();
    final numberOfRatings = details?['numberOfRatings'] ?? 0;
    final documents = details?['documents'] as Map<String, dynamic>?;
    final ordersCompleted = details?['ordersCompleted'] ?? 0;
    final rating = details?['rating']?.toDouble() ?? 0.0;
    final skills = List<String>.from(details?['skills'] ?? []);
    final bio = details?['bio'] ?? 'No bio available';
    final reviews = List<Map<String, dynamic>>.from(details?['reviews'] ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image Section
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderGalleryScreen(
                          providerName: widget.name,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 330,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(widget.imageUrl ??
                            'https://images.unsplash.com/photo-1581578731548-c64695cc6952?ixlib=rb-4.0.3'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name, Profession and Call section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mainProfession,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F7F8),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                final phoneNumber =
                                    _providerDetails?['phoneNumber'] ?? '';
                                if (phoneNumber.isNotEmpty) {
                                  _makePhoneCall(phoneNumber);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Phone number not available'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Icon(
                                IconlyLight.call,
                                color: Color(0xFF5D7A7F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    ordersCompleted.toString(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const Text('Orders'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formattedExperience,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Experience',
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    averageRating.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Rating',
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Skills Section
                      const Text(
                        'Skills',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: services
                            .map((service) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F7F8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    service,
                                    style: const TextStyle(
                                      color: Color(0xFF5D7A7F),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Bio Section
                      const Text(
                        'Bio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bio,
                        style: TextStyle(
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Reviews Section
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      review['userName'] ?? 'Anonymous',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      review['date'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(5, (index) {
                                      const double rating =
                                          3.5; // Example rating
                                      if (index < rating.floor()) {
                                        // Full star
                                        return Icon(
                                          IconlyBold.star,
                                          size: 16,
                                          color: const Color.fromARGB(
                                              255, 43, 56, 115),
                                        );
                                      } else if (index == rating.floor() &&
                                          rating % 1 != 0) {
                                        // Half star
                                        return ShaderMask(
                                          blendMode: BlendMode.srcATop,
                                          shaderCallback: (Rect bounds) {
                                            return LinearGradient(
                                              stops: const [0, 0.5, 0.5],
                                              colors: [
                                                const Color.fromARGB(
                                                    255, 43, 56, 115),
                                                const Color(0xFF2B6173),
                                                Colors.grey[300]!,
                                              ],
                                            ).createShader(bounds);
                                          },
                                          child: const Icon(
                                            IconlyBold.star,
                                            size: 16,
                                          ),
                                        );
                                      }
                                      // Empty star
                                      return Icon(
                                        IconlyBold.star,
                                        size: 16,
                                        color: Colors.grey[300],
                                      );
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  review['comment'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),
                                if (index < reviews.length - 1)
                                  const Divider(height: 32),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 100), // Space for button
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Book Button
          Positioned(
            left: 8,
            right: 8,
            bottom: 16,
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: ClipPath(
                  clipper: BottomNotchClipper(),
                  child: Container(
                    height: 80,
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
                        onTap: () {
                          // TODO: Handle booking
                        },
                        child: Center(
                          child: Text(
                            'Book',
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
            ),
          ),
        ],
      ),
    );
  }
}
