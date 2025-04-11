import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../services/auth_service.dart';
import '../../models/service_provider_registration.dart';
import '../service_provider/home_screen.dart';
import '../auth/login_screen.dart';
import 'dart:convert';

class PricingRateScreen extends StatefulWidget {
  final ServiceProviderRegistration registration;

  const PricingRateScreen({
    super.key,
    required this.registration,
  });

  @override
  State<PricingRateScreen> createState() => _PricingRateScreenState();
}

class _PricingRateScreenState extends State<PricingRateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hourlyRateController = TextEditingController();
  final _minimumHoursController = TextEditingController();
  bool _isNegotiable = false;
  bool _isLoading = false;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _minimumHoursController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Add hourly rate and minimum hours to registration
        widget.registration.hourlyRate = int.parse(_hourlyRateController.text);
        widget.registration.minimumHour =
            int.parse(_minimumHoursController.text);
        widget.registration.isNegotiable = _isNegotiable;

        print('Registering user: ${widget.registration.toJson()}');
        final response = await _authService.register(widget.registration);
        final responseData = json.decode(response.body);
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (!mounted) return;

        if (response.statusCode == 200 && responseData['status'] == true) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Application Received',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Your application for the service of ${widget.registration.mainProfession} has been received. You will get confirmation from our staff.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D7A7F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } else {
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
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Your Rates',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Define your service pricing',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _hourlyRateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Hourly Rate (PKR)',
                    hintText: 'Enter your hourly rate',
                    prefixIcon: const Icon(IconlyLight.wallet),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your hourly rate';
                    }
                    final rate = int.tryParse(value);
                    if (rate == null || rate <= 0) {
                      return 'Please enter a valid rate';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minimumHoursController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Minimum Hours',
                    hintText: 'Enter minimum hours per booking',
                    prefixIcon: const Icon(IconlyLight.time_circle),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter minimum hours';
                    }
                    final hours = int.tryParse(value);
                    if (hours == null || hours <= 0) {
                      return 'Please enter valid hours';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  value: _isNegotiable,
                  onChanged: (value) {
                    setState(() {
                      _isNegotiable = value;
                    });
                  },
                  title: const Text(
                    'Rate is Negotiable',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Allow customers to negotiate the rate',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  activeColor: const Color(0xFF5D7A7F),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D7A7F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
