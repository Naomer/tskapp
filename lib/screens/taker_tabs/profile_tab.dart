import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/service_taker/edit_profile_screen.dart' as taker;
import '../../screens/service_taker/payment_method_screen.dart';
import '../../screens/service_taker/notification_settings_screen.dart';
import '../../screens/service_taker/help_support_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final StorageService _storageService;
  late final ApiService _apiService;
  bool _isLoading = true;
  String? _error;

  // Profile data
  String? name;
  String? profileImage;
  double earnings = 1234.56;
  int activeOrders = 3;
  int completedOrders = 25;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _storageService = StorageService(prefs);
    _apiService = ApiService(_storageService);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _storageService.getUser();
      setState(() {
        name = user?.name;
        profileImage = user?.profileImage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        title: const Text('My Profile',
            style: TextStyle(
                color: Color(0xFF2F84DF),
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        actions: [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Profile Header
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                backgroundImage: profileImage != null
                                    ? NetworkImage(profileImage!)
                                    : null,
                                child: profileImage == null
                                    ? Text(
                                        name?[0].toUpperCase() ?? '',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          color: Color(0xFF2F84DF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            name ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _buildListTile('Edit Profile'),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _buildListTile('Notification'),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _buildListTile('Payment Method'),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _buildListTile('Help & Support'),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.fromLTRB(50, 0, 24, 0),
                          title: Text(
                            'Logout',
                            style: const TextStyle(
                              color: Color(0xFF2F84DF),
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  insetPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  contentPadding:
                                      const EdgeInsets.fromLTRB(24, 20, 24, 0),
                                  title: const Center(
                                    child: Text(
                                      '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  content: Container(
                                    width: double.maxFinite,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Logout',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Are you sure to logout?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0.0),
                                      child: Container(
                                        width: double.maxFinite,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              height: 58,
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  await _storageService
                                                      .clearAll();
                                                  Navigator.of(context)
                                                      .pushNamedAndRemoveUntil(
                                                    '/login',
                                                    (route) => false,
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                          255, 104, 175, 234),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Logout',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Close dialog
                                              },
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 104, 175, 234),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 40, bottom: 15),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Change Profile to selling mode',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 16,
                                ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                            left: 0, right: 0, bottom: 100),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: Colors.grey,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 19),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add,
                                color: Colors.grey,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                name ?? 'Loading...',
                                style: const TextStyle(
                                  color: Color(0xFF2F84DF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildListTile(String title) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(50, 0, 24, 0),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2F84DF),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: const Icon(
          Icons.chevron_right,
          color: Colors.white,
          size: 20,
        ),
      ),
      onTap: () async {
        switch (title) {
          case 'Edit Profile':
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const taker.EditProfileScreen()),
            );
            if (result == true) {
              // Refresh profile data when returning from edit screen
              await _loadUserData();
            }
            break;
          case 'Notification':
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen()),
            );
            break;
          case 'Payment Method':
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PaymentMethodScreen()),
            );
            break;
          case 'Help & Support':
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen()),
            );
            break;
        }
      },
    );
  }
}
