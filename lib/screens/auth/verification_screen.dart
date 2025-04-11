import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/auth_service.dart';
import '../../models/service_provider_registration.dart';
import '../../models/service_taker_registration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';
import '../../models/user.dart';
import 'dart:convert';

class VerificationScreen extends StatefulWidget {
  final dynamic
      registration; // Can be either ServiceProviderRegistration or ServiceTakerRegistration
  final VoidCallback onVerificationComplete;

  const VerificationScreen({
    super.key,
    required this.registration,
    required this.onVerificationComplete,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendVerificationCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String phoneNumber = _phoneController.text.trim();

      if (widget.registration is ServiceProviderRegistration) {
        (widget.registration as ServiceProviderRegistration).phoneNumber =
            phoneNumber;
      } else if (widget.registration is ServiceTakerRegistration) {
        (widget.registration as ServiceTakerRegistration).phoneNumber =
            phoneNumber;
      }

      final result = await _authService.sendVerificationCode(phoneNumber);

      if (!mounted) return;

      if (result['success']) {
        // Show verification code in a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification code: ${result['code']}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );

        widget.onVerificationComplete();
      } else {
        // Show specific error message from the API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'Failed to send verification code. Please try again.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
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
                  'Enter Phone Number',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We will send you a verification code',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. 0912345678',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    // Remove any spaces and check format
                    String phone = value.trim();
                    if (!phone.startsWith('0')) {
                      return 'Phone number must start with 0';
                    }
                    if (phone.length != 10) {
                      return 'Phone number must be 10 digits (starting with 0)';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
                      return 'Phone number can only contain digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendVerificationCode,
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
                            'Send Code',
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
