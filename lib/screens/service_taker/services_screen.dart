import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/category.dart';
import 'package:iconly/iconly.dart';
import '../../widgets/service_card.dart';
import '../../screens/service_taker/service_providers_screen.dart';
import '../../config/env.dart';
import 'package:shimmer/shimmer.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    print('ServicesScreen initialized');
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    print('_fetchCategories started');

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${Env.apiBaseUrl}/api/v1/common/getCategories?parentCategory=&page&size&sort'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response received - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed JSON data: $data');

        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> categoryList = data['data'] as List;
          print('Found ${categoryList.length} categories in response');

          final List<Category> categories =
              categoryList.map((item) => Category.fromJson(item)).toList();

          if (mounted) {
            setState(() {
              _categories = categories;
              _isLoading = false;
            });
          }

          print('Total categories loaded: ${_categories.length}');

          // Debug print all categories
          for (var category in _categories) {
            print(
                'Category: ${category.name}, ParentID: ${category.parentCategory}');
          }
        } else {
          print('Invalid response format or empty data');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        print('Error response: ${response.body}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      print('Error fetching categories: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Shimmer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          // Grid Shimmer
          GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: List.generate(9, (index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
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
        title: const Text(
          'Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Handle filter
            },
            icon: const Icon(IconlyLight.filter, color: Colors.black87),
          ),
          IconButton(
            onPressed: () {
              // TODO: Handle search
            },
            icon: const Icon(IconlyLight.search, color: Colors.black87),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _categories.isEmpty
          ? _buildShimmerLoading()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildServiceSections(),
              ),
            ),
    );
  }

  List<Widget> _buildServiceSections() {
    print('\nBuilding sections from ${_categories.length} total categories');

    // Create a map of parent categories by their ID for easy lookup
    Map<String, Category> parentCategoriesMap = {};

    // First pass: identify all parent categories (those without parentCategory)
    for (var category in _categories) {
      if (category.parentCategory == null) {
        parentCategoriesMap[category.id] = category;
        print('Found parent category: ${category.name} (${category.id})');
      }
    }

    // Build sections
    List<Widget> sections = [];

    // First add standalone parent categories (those that have no children)
    for (var parent in parentCategoriesMap.values) {
      List<Category> children =
          _categories.where((c) => c.parentCategory == parent.id).toList();

      if (children.isEmpty) {
        print('Adding standalone parent category: ${parent.name}');
        sections.add(_buildServiceSection(parent.name, [parent]));
      }
    }

    // Then add parent categories with their children
    for (var parent in parentCategoriesMap.values) {
      List<Category> children =
          _categories.where((c) => c.parentCategory == parent.id).toList();

      if (children.isNotEmpty) {
        print('Adding parent ${parent.name} with ${children.length} children');
        List<Category> categoryGroup = [parent, ...children];
        sections.add(_buildServiceSection(parent.name, categoryGroup));
      }
    }

    // Finally add categories that have a parentCategory but their parent is not in our list
    Set<String> processedCategories = Set.from(parentCategoriesMap.keys);
    List<Category> orphanCategories = _categories.where((category) {
      if (category.parentCategory != null &&
          !parentCategoriesMap.containsKey(category.parentCategory)) {
        print(
            'Found orphan category: ${category.name} with parent ID: ${category.parentCategory}');
        return true;
      }
      return false;
    }).toList();

    if (orphanCategories.isNotEmpty) {
      print('Adding ${orphanCategories.length} orphan categories');
      sections.add(_buildServiceSection('Other Services', orphanCategories));
    }

    print('Built ${sections.length} total sections');
    return sections;
  }

  Widget _buildServiceSection(String title, List<Category> categories) {
    print('Building section: $title with ${categories.length} categories');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        GridView.count(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: categories.map((category) {
            final index = categories.indexOf(category);
            return ServiceCard(
              title: category.name,
              categoryId: category.id,
              color: index % 4 == 0
                  ? const Color(0xFFB2D8D8) // aqua grey
                  : index % 4 == 1
                      ? const Color(0xFFBEB5B5) // brown grey
                      : index % 4 == 2
                          ? const Color(0xFFE5C3C6) // pink grey
                          : const Color(0xFFB2D8B2), // green grey
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceProvidersScreen(
                      serviceCategory: category.name,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
