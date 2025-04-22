import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/storage_service.dart';
import '../../services/language_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Start the animation
    _controller.forward();

    // Run initialization after the animation starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);
      final languageService = LanguageService(prefs);

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 2500));

      if (!mounted) return;

      // Only show language screen if setup is not completed
      if (!languageService.isSetupCompleted) {
        Navigator.pushReplacementNamed(context, '/language');
        return;
      }

      // If user has already seen get started or selected language, go directly to main flow
      if (storageService.isGuest()) {
        Navigator.pushReplacementNamed(context, '/service-taker/home');
        return;
      }

      final token = await storageService.getAccessToken();
      if (token == null || !storageService.validateStoredUser()) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      if (!mounted) return;

      if (storageService.isProvider()) {
        Navigator.pushReplacementNamed(context, '/service-provider/home');
      } else if (storageService.isTaker()) {
        Navigator.pushReplacementNamed(context, '/service-taker/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error in splash screen: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Background animated circles
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.2,
                  top: MediaQuery.of(context).size.height * 0.15,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue[100]!.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: MediaQuery.of(context).size.width * 0.15,
                  bottom: MediaQuery.of(context).size.height * 0.2,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue[200]!.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                // Main content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo with scale and fade animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.work_outline,
                            size: 60,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App name with fade animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'app.name'.tr(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline with fade animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'app.tagline'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Loading indicator with fade animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue[300]!),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'app.loading'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
