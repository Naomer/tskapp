import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import 'new_password_screen.dart';
import 'dart:async';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final _authService = AuthService();
  bool _isLoading = false;
  int _attempts = 0;
  final int _maxAttempts = 3;
  bool _isLocked = false;
  DateTime? _lockUntil;
  bool _canResend = false;
  int _resendTimer = 60; // Start with 60 seconds
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendTimer = 60;
      _canResend = false;
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

  Future<void> _checkLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilStr = prefs.getString('verify_lock_until');
    if (lockUntilStr != null) {
      final lockUntil = DateTime.parse(lockUntilStr);
      if (DateTime.now().isBefore(lockUntil)) {
        setState(() {
          _isLocked = true;
          _lockUntil = lockUntil;
        });
      } else {
        await prefs.remove('verify_lock_until');
      }
    }
  }

  String _getFormattedLockTime() {
    if (_lockUntil == null) return '';
    final remaining = _lockUntil!.difference(DateTime.now());
    if (remaining.isNegative) return '';
    final minutes = remaining.inMinutes + 1; // Round up to next minute
    return '$minutes minutes';
  }

  Future<void> _resendCode() async {
    if (!_canResend || _isLocked) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.forgotPassword(widget.email);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _startResendTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
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

  void _clearInputs() {
    for (var controller in _controllers) {
      controller.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_isLocked) return;

      setState(() {
        _isLoading = true;
      });

      try {
        final code = _controllers.map((c) => c.text).join();

        // Instead of verifying, just proceed to new password screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewPasswordScreen(
              email: widget.email,
              code: code,
            ),
          ),
        );

        // If result is false (invalid code), clear inputs
        if (result == false) {
          _clearInputs();
          _attempts++;
          if (_attempts >= _maxAttempts) {
            final lockUntil = DateTime.now().add(const Duration(minutes: 3));
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                'verify_lock_until', lockUntil.toIso8601String());

            setState(() {
              _isLocked = true;
              _lockUntil = lockUntil;
            });
          }
        }
      } catch (e) {
        // Error handling...
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
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the verification code sent to ${widget.email}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      6,
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
                          ),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
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
                      onPressed: _isLoading ? null : _handleSubmit,
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
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
