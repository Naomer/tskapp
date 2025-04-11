import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../models/service_provider_registration.dart';
import '../../models/service_taker_registration.dart';
import 'location_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class PinScreen extends StatefulWidget {
  final dynamic
      registration; // Can be either ServiceProviderRegistration or ServiceTakerRegistration
  final VoidCallback onPinSet;

  const PinScreen({
    super.key,
    required this.registration,
    required this.onPinSet,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(
    5,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    5,
    (index) => FocusNode(),
  );
  final _authService = AuthService();
  bool _isLoading = false;
  int _attempts = 0;
  final int _maxAttempts = 3;
  bool _isLocked = false;
  DateTime? _lockUntil;
  bool _canResend = true;
  int _resendTimer = 0;
  Timer? _timer;
  String? _verificationCode;

  String _getFormattedLockTime() {
    if (_lockUntil == null) return '';
    final remaining = _lockUntil!.difference(DateTime.now());
    if (remaining.isNegative) return '';
    final minutes = remaining.inMinutes + 1; // Round up to next minute
    return '$minutes minutes';
  }

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
    // Start timer to update lock countdown
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isLocked) {
        setState(() {
          if (_lockUntil != null && DateTime.now().isAfter(_lockUntil!)) {
            _isLocked = false;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilStr = prefs.getString('pin_lock_until');
    if (lockUntilStr != null) {
      final lockUntil = DateTime.parse(lockUntilStr);
      if (lockUntil.isAfter(DateTime.now())) {
        setState(() {
          _isLocked = true;
          _lockUntil = lockUntil;
        });
      } else {
        await prefs.remove('pin_lock_until');
      }
    }
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 60; // 60 seconds cooldown
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handlePinSubmit() async {
    if (_isLocked) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final code = _controllers.map((c) => c.text).join();
      final success = await _authService.verifyUser(
        widget.registration.phoneNumber!,
        code,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (success) {
        if (widget.registration is ServiceProviderRegistration) {
          // Original flow for service provider
          widget.onPinSet();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocationScreen(
                registration:
                    widget.registration as ServiceProviderRegistration,
              ),
            ),
          );
        } else if (widget.registration is ServiceTakerRegistration) {
          // New flow for service taker with combined dialog
          widget.onPinSet();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Registration Successful',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Your phone number has been verified and your account has been created successfully.',
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
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          child: const Text(
                            'Back to Login',
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
              );
            },
          );
        }
      } else {
        setState(() {
          _attempts++;
          for (var controller in _controllers) {
            controller.clear();
          }
          if (_focusNodes.isNotEmpty) {
            _focusNodes[0].requestFocus();
          }
        });

        if (_attempts >= _maxAttempts) {
          final lockUntil = DateTime.now().add(const Duration(minutes: 3));
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pin_lock_until', lockUntil.toIso8601String());

          setState(() {
            _isLocked = true;
            _lockUntil = lockUntil;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLocked
                ? 'Too many attempts. Try again in 5 minutes.'
                : 'Incorrect PIN. ${_maxAttempts - _attempts} attempts remaining'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.sendVerificationCode(
        widget.registration.phoneNumber!,
      );

      if (result['success']) {
        setState(() {
          _verificationCode = result['code'].toString();
        });

        // Auto-fill the code
        final code = _verificationCode!;
        for (var i = 0; i < code.length && i < _controllers.length; i++) {
          _controllers[i].text = code[i];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification code: $code',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        _startResendTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send verification code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error sending verification code'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 250, 249, 249),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Enter verification code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Enter the code sent to ${widget.registration.phoneNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      5,
                      (index) => SizedBox(
                        width: 50,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 4) {
                              _focusNodes[index + 1].requestFocus();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 57,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 135, 192, 238),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handlePinSubmit,
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
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: _isLocked
                        ? Column(
                            children: [
                              Text(
                                'Too many attempts',
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try again in ${_getFormattedLockTime()}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Attempts remaining: ${_maxAttempts - _attempts}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _canResend && !_isLoading && !_isLocked
                          ? _resendCode
                          : null,
                      child: Text(
                        _canResend
                            ? "Didn't get the code? Send again"
                            : 'Resend code in ${_resendTimer}s',
                        style: TextStyle(
                          color: _canResend && !_isLocked
                              ? const Color.fromARGB(255, 135, 192, 238)
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
