import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/custom_navigation_bar.dart';
import '../../widgets/bottom_nav_bar/bottom_nav_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_drawer.dart';

class ServiceTakerHomeScreen extends StatefulWidget {
  const ServiceTakerHomeScreen({super.key});

  @override
  State<ServiceTakerHomeScreen> createState() => _ServiceTakerHomeScreenState();
}

class _ServiceTakerHomeScreenState extends State<ServiceTakerHomeScreen> {
  int _selectedIndex = 0;
  late StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _storageService = StorageService(prefs);
  }

  void _handleProtectedAction(BuildContext context, VoidCallback action) {
    if (_storageService.isGuest()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login to access this feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    } else {
      action();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add a context.locale listener to ensure the screen rebuilds when language changes
    context.locale; // This line ensures the widget rebuilds when locale changes

    return Scaffold(
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: navScreens.map((screen) {
          if (_selectedIndex > 0 && _storageService.isGuest()) {
            return GestureDetector(
              onTap: () => _handleProtectedAction(context, () {}),
              child: Container(
                color: Colors.white,
                child: const Center(
                  child: Text(
                    'Please login to access this feature',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }
          return screen;
        }).toList(),
      ),
      extendBody: true,
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          if (index > 0 && _storageService.isGuest()) {
            _handleProtectedAction(context, () {
              setState(() {
                _selectedIndex = index;
              });
            });
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for services...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            // Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                children: [
                  ServiceCategory(
                    icon: Icons.plumbing,
                    title: 'Plumbing',
                    onTap: () {},
                  ),
                  ServiceCategory(
                    icon: Icons.electrical_services,
                    title: 'Electrical',
                    onTap: () {},
                  ),
                  ServiceCategory(
                    icon: Icons.carpenter,
                    title: 'Carpentry',
                    onTap: () {},
                  ),
                  ServiceCategory(
                    icon: Icons.cleaning_services,
                    title: 'Cleaning',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Popular Services
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Popular Services',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ServiceCard(
                  title: 'Service ${index + 1}',
                  description: 'Description for service ${index + 1}',
                  rating: 4.5,
                  price: '\$${50 + index * 10}',
                  onTap: () {},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Add other tabs
class CityTab extends StatelessWidget {
  const CityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('City Tab'),
      ),
    );
  }
}

class JobsTab extends StatelessWidget {
  const JobsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Jobs Tab'),
      ),
    );
  }
}

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Orders Tab'),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Profile Tab'),
      ),
    );
  }
}

class ServiceCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ServiceCategory({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      overflow: TextOverflow.ellipsis,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final double rating;
  final String price;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.rating,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              price,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(' $rating'),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
