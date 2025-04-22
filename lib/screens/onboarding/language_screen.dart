import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  void initState() {
    super.initState();
    _markAsSeen();
  }

  Future<void> _markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final languageService = LanguageService(prefs);
    final storageService = StorageService(prefs);

    await languageService.markLanguageScreenAsSeen();
    await storageService.markGetStartedAsSeen();
  }

  Future<void> _setLanguage(BuildContext context, String language) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );

      final prefs = await SharedPreferences.getInstance();
      final languageService = LanguageService(prefs);

      // Set the language in both LanguageService and EasyLocalization
      await languageService.setLanguageAndComplete(language);
      await context.setLocale(Locale(language));

      if (!mounted) return;

      // Pop loading dialog
      Navigator.of(context).pop();

      // Navigate to get started screen instead of login
      Navigator.pushReplacementNamed(context, '/get-started');
    } catch (e) {
      if (!mounted) return;

      // Pop loading dialog if showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('language.change_error'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Container(
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
                      Icons.language,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'language.title'.tr(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'language.select_preferred'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  _LanguageButton(
                    onPressed: () => _setLanguage(context, 'en'),
                    language: 'language.english'.tr(),
                    icon: '🇺🇸',
                    isFirst: true,
                  ),
                  const SizedBox(height: 16),
                  _LanguageButton(
                    onPressed: () => _setLanguage(context, 'ar'),
                    language: 'language.arabic'.tr(),
                    icon: '🇸🇦',
                    isFirst: false,
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String language;
  final String icon;
  final bool isFirst;

  const _LanguageButton({
    required this.onPressed,
    required this.language,
    required this.icon,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFirst
              ? [Colors.blue[400]!, Colors.blue[600]!]
              : [Colors.grey[800]!, Colors.black],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isFirst ? Colors.blue[300]! : Colors.grey[700]!)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      language,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
