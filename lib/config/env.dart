import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl {
    try {
      return dotenv.env['API_BASE_URL'] ?? 'https://task-app-yopb.onrender.com';
    } catch (e) {
      return 'https://task-app-yopb.onrender.com';
    }
  }

  static String get googleMapsAndroidApiKey {
    try {
      return dotenv.env['GOOGLE_MAPS_ANDROID_API_KEY'] ?? '';
    } catch (e) {
      return '';
    }
  }

  static String get googleMapsIosApiKey {
    try {
      return dotenv.env['GOOGLE_MAPS_IOS_API_KEY'] ?? '';
    } catch (e) {
      return '';
    }
  }
}
