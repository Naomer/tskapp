import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'user_type_screen.dart';
import 'dart:io' show Platform;
import 'package:easy_localization/easy_localization.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserTypeScreen(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            ),
          ),
        );
      } catch (e) {
        // Handle any errors here
        print('Error during registration: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
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
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'auth.register.create_account'.tr(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'auth.register.please_register'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        autofillHints: const [AutofillHints.name],
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'auth.register.full_name'.tr(),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'auth.register.errors.name_required'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'auth.register.email'.tr(),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'auth.register.errors.email_required'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.newPassword],
                        keyboardType: TextInputType.visiblePassword,
                        enableInteractiveSelection: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'auth.register.password'.tr(),
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
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'auth.register.errors.password_short'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
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
                          onPressed: _isLoading ? null : _handleRegister,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'auth.register.sign_up'.tr(),
                                  style: const TextStyle(
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
                            Navigator.pop(context);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                    text:
                                        'auth.register.has_account'.tr() + ' '),
                                TextSpan(
                                  text: 'auth.register.sign_in'.tr(),
                                  style: const TextStyle(
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
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'auth.register.or_connect'.tr(),
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
            ],
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
