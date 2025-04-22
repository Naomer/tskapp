import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';
import 'package:easy_localization/easy_localization.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _pageController = PageController();
  bool isLastPage = false;
  int currentPage = 0;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      image: 'assets/images/onboarding1.png',
      title: 'onboarding.pages.services.title'.tr(),
      description: 'onboarding.pages.services.description'.tr(),
    ),
    OnboardingPage(
      image: 'assets/images/onboarding2.png',
      title: 'onboarding.pages.booking.title'.tr(),
      description: 'onboarding.pages.booking.description'.tr(),
    ),
    OnboardingPage(
      image: 'assets/images/onboarding3.png',
      title: 'onboarding.pages.tracking.title'.tr(),
      description: 'onboarding.pages.tracking.description'.tr(),
    ),
  ];

  Future<void> _markAsSeen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    await storageService.markGetStartedAsSeen();

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent going back
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          isLastPage = index == pages.length - 1;
                          currentPage = index;
                        });
                      },
                      children: pages,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: pages.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: Colors.blue[300]!,
                            dotColor: Colors.blue[100]!,
                            dotHeight: 8,
                            dotWidth: 8,
                            spacing: 4,
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
                            onPressed: () {
                              if (isLastPage) {
                                _markAsSeen(context);
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Text(
                              isLastPage
                                  ? 'onboarding.get_started'.tr()
                                  : 'onboarding.next'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Skip button (on top)
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: () => _markAsSeen(context),
                  child: Text(
                    'onboarding.skip'.tr(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image,
            height: 300,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
