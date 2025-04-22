import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/service_taker/home_screen.dart';
import 'screens/service_provider/home_screen.dart';
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/get_started_screen.dart';
import 'screens/auth/user_type_screen.dart';
import 'screens/auth/verification_screen.dart';
import 'screens/auth/pin_screen.dart';
import 'screens/auth/location_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/language_service.dart';
import 'screens/settings/language_settings_screen.dart';
import 'package:easy_localization/easy_localization.dart';

// Global key to access MyAppState
final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize easy_localization
  await EasyLocalization.ensureInitialized();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // Try to load .env file but continue if it fails
    await dotenv.load(fileName: ".env").catchError((e) {
      debugPrint("Warning: .env file not loaded, using default values");
    });
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final languageService = LanguageService(prefs);
  final storageService = StorageService(prefs);
  final apiService = ApiService(storageService);

  // Run app with localization support
  runApp(
    EasyLocalization(
      supportedLocales: languageService.supportedLocales,
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: languageService.currentLocale,
      child: MyApp(
        apiService: apiService,
        languageService: languageService,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final ApiService apiService;
  final LanguageService languageService;

  const MyApp({
    super.key,
    required this.apiService,
    required this.languageService,
  });

  @override
  State<MyApp> createState() => MyAppState();

  // Static method to rebuild the app
  static void rebuild(BuildContext context) {
    context.findAncestorStateOfType<MyAppState>()?.rebuild();
  }
}

class MyAppState extends State<MyApp> {
  // Key to force rebuild of the entire app
  Key _key = UniqueKey();

  // Method to rebuild the app
  void rebuild() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'Task App'.tr(),
            debugShowCheckedModeBanner: false,
            navigatorKey: widget.apiService.navigatorKey,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                background: Colors.white,
              ),
            ),
            // Localization support
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: child!,
              );
            },
            home: const SplashScreen(),
            routes: {
              '/language': (context) => const LanguageScreen(),
              '/settings/language': (context) => const LanguageSettingsScreen(),
              '/get-started': (context) => const GetStartedScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/service-taker/home': (context) =>
                  const ServiceTakerHomeScreen(),
              '/service-provider/home': (context) =>
                  const ServiceProviderHomeScreen(),
              '/splash': (context) => const SplashScreen(),
            },
          );
        },
      ),
    );
  }
}
