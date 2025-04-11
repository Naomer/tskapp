import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

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
  final storageService = StorageService(prefs);
  final apiService = ApiService(storageService);

  // Run app
  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;

  const MyApp({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: apiService.navigatorKey,
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
      builder: (context, child) {
        return MediaQuery(
          // Prevent system text scaling
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      home: const SplashScreen(),
      routes: {
        '/language': (context) => const LanguageScreen(),
        '/get-started': (context) => const GetStartedScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/service-taker/home': (context) => const ServiceTakerHomeScreen(),
        '/service-provider/home': (context) =>
            const ServiceProviderHomeScreen(),
      },
    );
  }
}
