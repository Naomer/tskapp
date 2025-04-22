import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/language_service.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late LanguageService _languageService;

  @override
  void initState() {
    super.initState();
    _initializeLanguageService();
  }

  Future<void> _initializeLanguageService() async {
    final prefs = await SharedPreferences.getInstance();
    _languageService = LanguageService(prefs);
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (context.locale.languageCode == languageCode) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );

      // Change the language
      await _languageService.setLanguageAndComplete(languageCode);
      await context.setLocale(Locale(languageCode));

      if (!mounted) return;

      // Pop the loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('language.change_success'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to previous screen
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      // Pop the loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'language.title'.tr(),
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildLanguageOption(
              'language.english'.tr(),
              'en',
              '🇺🇸',
              context.locale.languageCode == 'en',
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(
              'language.arabic'.tr(),
              'ar',
              '🇸🇦',
              context.locale.languageCode == 'ar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String label,
    String code,
    String flag,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _changeLanguage(code),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
