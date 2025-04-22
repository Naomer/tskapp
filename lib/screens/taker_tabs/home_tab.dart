import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import '../../models/category.dart';
import '../../models/provider.dart';
import '../../widgets/service_category.dart';
import '../../widgets/service_card.dart';
import 'package:iconly/iconly.dart';
import '../service_taker/services_screen.dart';
import '../service_taker/service_providers_screen.dart';
import '../service_taker/provider_details_screen.dart';
import '../../config/env.dart';
import '../../services/provider_service.dart';
import '../../services/storage_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Category> _categories = [];
  List<Provider> _providers = [];
  bool _isLoading = true;
  bool _isLoadingProviders = true;
  String _selectedCategoryId = '';
  late final ProviderService _providerService;
  Category? _featuredCategory;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _updateFeaturedCategory() {
    if (_categories.isNotEmpty) {
      final random = DateTime.now().millisecondsSinceEpoch;
      _featuredCategory = _categories[random % _categories.length];
    }
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    _providerService = ProviderService(storageService);

    _fetchCategories();
    _fetchProviders();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/api/v1/common/getCategories'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final List<Category> categories = (data['data'] as List)
              .map((item) => Category.fromJson(item))
              .toList();

          setState(() {
            _categories = categories;
            if (categories.isNotEmpty) {
              _selectedCategoryId = categories[0].id;
              _updateFeaturedCategory();
            }
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _fetchProviders() async {
    try {
      setState(() => _isLoadingProviders = true);

      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);
      final providerService = ProviderService(storageService);

      final providers = await providerService.getServiceProviders();

      setState(() {
        _providers = providers;
        _isLoadingProviders = false;
      });
    } catch (e) {
      setState(() => _isLoadingProviders = false);
      debugPrint('Error fetching providers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 18,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            width: 40,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: _isLoading
              ? _buildShimmerLoading()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.04),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.04),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F8FC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ' Service',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.04,
                              ),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.width * 0.02),
                            Text(
                              _categories.isEmpty
                                  ? 'Loading...'
                                  : _categories[DateTime.now().second %
                                          _categories.length]
                                      .name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.06,
                              ),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.width * 0.04),
                            ElevatedButton(
                              onPressed: () {
                                if (_categories.isNotEmpty) {
                                  final category = _categories[
                                      DateTime.now().millisecondsSinceEpoch %
                                          _categories.length];
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ServiceProvidersScreen(
                                        serviceCategory: category.name,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.04,
                                  vertical:
                                      MediaQuery.of(context).size.width * 0.02,
                                ),
                              ),
                              child: Text(
                                'Book Now',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.035,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 0.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ServicesScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: _categories.take(3).map((category) {
                          return Row(
                            children: [
                              ServiceCard(
                                icon: Icon(
                                  _categories.indexOf(category) == 0
                                      ? IconlyBold.home
                                      : _categories.indexOf(category) == 1
                                          ? IconlyBold.work
                                          : IconlyBold.buy,
                                  size: 28,
                                  color: _categories.indexOf(category) == 0
                                      ? const Color(0XFFF15756)
                                      : _categories.indexOf(category) == 1
                                          ? const Color(0XFFFE924B)
                                          : const Color(0XFF71D7F3),
                                ),
                                iconBackground: _categories.indexOf(category) ==
                                        0
                                    ? const Color(
                                        0xFFFAC6C8) // darker blue grey
                                    : _categories.indexOf(category) == 1
                                        ? const Color(
                                            0xFFFDDAC2) // darker green grey
                                        : const Color(
                                            0xFFCCF0FC), // darker purple grey
                                title: category.name,
                                categoryId: category.id,
                                color: _categories.indexOf(category) == 0
                                    ? const Color(0xFFFDE8E9)
                                    : _categories.indexOf(category) == 1
                                        ? const Color(
                                            0xFFFCF1E9) // darker green grey
                                        : const Color(0xFFE9F8FC),
                                width: 122,
                                height: 150,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ServiceProvidersScreen(
                                        serviceCategory: category.name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (_categories.indexOf(category) < 2)
                                const SizedBox(width: 12),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Offers & News',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: _categories.map((category) {
                            final isSelected =
                                category.id == _selectedCategoryId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId = category.id;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0XFFFD6B22)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0XFFFD6B22)
                                          : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    category.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : PageView.builder(
                              padEnds: false,
                              controller: PageController(viewportFraction: 0.9),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: category.image != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                                category.image!.data),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: Colors.grey[100],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.6),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          category.description,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: const Text(
                        'Providers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingProviders)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_providers.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No providers available'),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            for (int i = 0; i < _providers.length; i++) ...[
                              _buildProviderAvatar(
                                _providers[i],
                                [
                                  Colors.orange[100]!,
                                  Colors.green[100]!,
                                  Colors.purple[100]!,
                                  Colors.blue[100]!,
                                  Colors.pink[100]!,
                                ][i % 5],
                              ),
                              if (i < _providers.length - 1)
                                const SizedBox(width: 24),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProviderAvatar(Provider provider, Color backgroundColor) {
    final avatarColors = [
      const Color(0xFFB2D8D8), // aqua grey
      const Color(0xFFBEB5B5), // brown grey
      const Color(0xFFE5C3C6), // pink grey
    ];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderDetailsScreen(
              providerId: provider.id,
              name: provider.name,
              profession: provider.profession,
              imageUrl: provider.image,
              rating: provider.rating,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColors[_providers.indexOf(provider) % 3],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner shimmer
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),

        // Services title shimmer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Shimmer.fromColors(
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
        ),
        const SizedBox(height: 16),

        // Service cards shimmer
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
              3,
              (index) => Padding(
                padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Categories shimmer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Category pills shimmer
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
              4,
              (index) => Padding(
                padding: EdgeInsets.only(right: index < 3 ? 12 : 0),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 80,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Providers shimmer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Shimmer.fromColors(
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
        ),
        const SizedBox(height: 16),

        // Provider avatars shimmer
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
              5,
              (index) => Padding(
                padding: EdgeInsets.only(right: index < 4 ? 24 : 0),
                child: Column(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
