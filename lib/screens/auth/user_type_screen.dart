import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../models/service_provider_registration.dart';
import 'location_screen.dart';
import 'verification_screen.dart';
import 'pin_screen.dart';
import 'dart:convert';
import '../../services/auth_service.dart';
import '../service_taker/home_screen.dart';
import '../../models/service_taker_registration.dart';

class UserTypeScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const UserTypeScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<UserTypeScreen> createState() => _UserTypeScreenState();
}

class _UserTypeScreenState extends State<UserTypeScreen> {
  String? _selectedUserType;
  final AuthService _authService = AuthService();

  void _handleNext() {
    if (_selectedUserType == 'Service Provider') {
      final registration = ServiceProviderRegistration()
        ..name = widget.name
        ..email = widget.email
        ..password = widget.password;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(
            registration: registration,
            onVerificationComplete: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PinScreen(
                    registration: registration,
                    onPinSet: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationScreen(
                            registration: registration,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else if (_selectedUserType == 'Service Taker') {
      final registration = ServiceTakerRegistration()
        ..name = widget.name
        ..email = widget.email
        ..password = widget.password;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(
            registration: registration,
            onVerificationComplete: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PinScreen(
                    registration: registration,
                    onPinSet: () {
                      _handleServiceTakerRegistration(registration);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _handleServiceTakerRegistration(ServiceTakerRegistration registration) {
    _authService.registerServiceTaker(registration).then((response) {
      final responseData = json.decode(response.body);

      if (response.statusCode != 200 || responseData['status'] != true) {
        // Extract error message from response
        String errorMessage;
        if (responseData is Map) {
          if (responseData.containsKey('email')) {
            errorMessage = responseData['email'];
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'];
          } else if (responseData.containsKey('msg')) {
            errorMessage = responseData['msg'];
          } else {
            // If there are multiple errors, combine them
            errorMessage = responseData.values.join('\n');
          }
        } else {
          errorMessage = 'Registration failed. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(
                seconds: 4), // Increased duration for longer messages
          ),
        );
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _handleUserTypeSelection(String userType) {
    setState(() {
      _selectedUserType = userType;
    });
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose User Type',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select how you want to use the app',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildUserTypeCard(
                      title: 'Service Provider',
                      description: 'I want to provide services',
                      icon: IconlyLight.work,
                      color: Colors.blue[100]!,
                    ),
                    const SizedBox(height: 16),
                    _buildUserTypeCard(
                      title: 'Service Taker',
                      description: 'I want to book services',
                      icon: IconlyLight.user,
                      color: Colors.green[100]!,
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedUserType != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D7A7F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedUserType == title;

    return InkWell(
      onTap: () => _handleUserTypeSelection(title),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5D7A7F).withOpacity(0.1) : color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5D7A7F) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: const Color(0xFF5D7A7F),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.chevron_right,
              color: isSelected ? const Color(0xFF5D7A7F) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
