import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_exceptions.dart';
import '../../models/user.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/select_verification_method_screen.dart';
import '../../config/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isPasswordVisible = false;
  bool isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final StorageService _storageService;
  late final ApiService _apiService;
  int _loginAttempts = 0;
  DateTime? _lastFailedAttempt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadLoginAttempts();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _storageService = StorageService(prefs);
    _apiService = ApiService(_storageService);
  }

  Future<void> _loadLoginAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loginAttempts = prefs.getInt('login_attempts') ?? 0;
      final lastAttemptStr = prefs.getString('last_failed_attempt');
      _lastFailedAttempt =
          lastAttemptStr != null ? DateTime.parse(lastAttemptStr) : null;
    });
  }

  Future<void> _updateLoginAttempts(bool success) async {
    final prefs = await SharedPreferences.getInstance();
    if (success) {
      // Reset on successful login
      await prefs.setInt('login_attempts', 0);
      await prefs.remove('last_failed_attempt');
      _loginAttempts = 0;
      _lastFailedAttempt = null;
    } else {
      // Increment attempts on failure
      _loginAttempts++;
      _lastFailedAttempt = DateTime.now();
      await prefs.setInt('login_attempts', _loginAttempts);
      await prefs.setString(
          'last_failed_attempt', _lastFailedAttempt!.toIso8601String());
    }
  }

  bool _isLockedOut() {
    if (_loginAttempts >= AppConstants.maxLoginAttempts &&
        _lastFailedAttempt != null) {
      final lockoutEnd =
          _lastFailedAttempt!.add(AppConstants.loginLockoutDuration);
      if (DateTime.now().isBefore(lockoutEnd)) {
        return true;
      } else {
        // Reset if lockout period has passed
        _loginAttempts = 0;
        _lastFailedAttempt = null;
        return false;
      }
    }
    return false;
  }

  Duration _getRemainingLockoutTime() {
    if (_lastFailedAttempt == null) return Duration.zero;
    final lockoutEnd =
        _lastFailedAttempt!.add(AppConstants.loginLockoutDuration);
    return lockoutEnd.difference(DateTime.now());
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
        _error = null;
      });

      try {
        await _storageService.setGuestMode(false);
        await _storageService.clearAll();
        await _apiService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        await Future.delayed(const Duration(milliseconds: 100));

        final token = await _storageService.getAccessToken();
        final user = _storageService.getUser();

        if (!mounted) return;

        if (token != null && user != null) {
          if (user.role == 'serviceProvider') {
            Navigator.pushReplacementNamed(context, '/service-provider/home');
          } else if (user.role == 'serviceTaker') {
            Navigator.pushReplacementNamed(context, '/service-taker/home');
          }
        } else {
          throw Exception('Login failed: Unable to verify credentials');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
            _error = e.toString();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'auth.login.errors.generic'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _validateInputs() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.login.errors.missing_fields').tr(),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.login.errors.email_required'.tr();
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'auth.login.errors.invalid_email'.tr();
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.login.errors.password_required'.tr();
    }
    return null;
  }

  Future<void> _changeLanguage() async {
    final currentLocale = context.locale;
    if (currentLocale.languageCode == 'en') {
      await context.setLocale(const Locale('ar'));
    } else {
      await context.setLocale(const Locale('en'));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          child: TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final storageService = StorageService(prefs);
              await storageService.setGuestMode(true);
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/service-taker/home');
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'common.skip'.tr(),
              style: TextStyle(
                color: Color(0xFF6C94D0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 250, 249, 249),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton(
              onPressed: _changeLanguage,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                context.locale.languageCode == 'en' ? 'عربي' : 'EN',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'auth.login.sign_in_now'.tr(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'auth.login.please_sign_in'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'auth.login.email'.tr(),
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
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _passwordController,
                    autofillHints: const [AutofillHints.password],
                    keyboardType: TextInputType.visiblePassword,
                    enableInteractiveSelection: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'auth.login.password'.tr(),
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !isPasswordVisible,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SelectVerificationMethodScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'auth.login.forgot_password'.tr(),
                        style: TextStyle(
                          color: const Color.fromARGB(255, 135, 192, 238),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 57,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C94D0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _login();
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'auth.login.sign_in'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(text: 'auth.login.no_account'.tr() + ' '),
                            TextSpan(
                              text: 'auth.login.sign_up'.tr(),
                              style: TextStyle(
                                color: Color.fromARGB(255, 135, 192, 238),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Or connect divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'auth.login.or_connect'.tr(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Social sign in buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        imageUrl:
                            'https://developers.google.com/identity/images/g-logo.png',
                        onPressed: () {
                          // TODO: Implement Google sign in
                        },
                      ),
                      if (Platform.isIOS) ...[
                        const SizedBox(width: 16),
                        _SocialButton(
                          icon: Icons.apple,
                          onPressed: () {
                            // TODO: Implement Apple sign in
                          },
                        ),
                      ],
                      const SizedBox(width: 16),
                      _SocialButton(
                        icon: FontAwesomeIcons.facebookF,
                        isFacebook: true,
                        onPressed: () {
                          // TODO: Implement Facebook sign in
                        },
                      ),
                    ],
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

class _SocialButton extends StatelessWidget {
  final String? imageUrl;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isFacebook;
  final bool isLocalImage;

  const _SocialButton({
    this.imageUrl,
    this.icon,
    required this.onPressed,
    this.isFacebook = false,
    this.isLocalImage = false,
  }) : assert(imageUrl != null || icon != null,
            'Either imageUrl or icon must be provided');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isFacebook ? const Color(0xFF1877F2) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isFacebook ? Colors.white : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: imageUrl != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: isLocalImage
                    ? Image.asset(
                        imageUrl!,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            icon ?? Icons.error_outline,
                            size: 30,
                            color: Colors.grey[800],
                          );
                        },
                      )
                    : Image.network(
                        imageUrl!,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            icon ?? Icons.error_outline,
                            size: 30,
                            color: Colors.grey[800],
                          );
                        },
                      ),
              )
            : isFacebook
                ? Stack(
                    children: [
                      Positioned(
                        bottom: -14,
                        left: 0,
                        right: 0,
                        child: Text(
                          'f',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Helvetica',
                            fontSize: 56,
                            height: 1,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                : Icon(
                    icon ?? Icons.error_outline,
                    size: 30,
                    color: Colors.grey[800],
                  ),
      ),
    );
  }
}
