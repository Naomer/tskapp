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
      return dotenv.env['GOOGLE_MAPS_ANDROID_API_KEY'] ??
          'AIzaSyBPzc7TGvM4eT5AalOR4gG2EdMY3DF7JoY';
    } catch (e) {
      return 'AIzaSyBPzc7TGvM4eT5AalOR4gG2EdMY3DF7JoY';
    }
  }

  static String get googleMapsIosApiKey {
    try {
      return dotenv.env['GOOGLE_MAPS_IOS_API_KEY'] ??
          'AIzaSyCtgYALUdmZeaMtZg3wHzpH2RECPPRqSSM';
    } catch (e) {
      return 'AIzaSyCtgYALUdmZeaMtZg3wHzpH2RECPPRqSSM';
    }
  }
}
