import 'package:flutter/material.dart';
import '../../screens/taker_tabs/home_tab.dart';
import '../../screens/taker_tabs/city_tab.dart';
import '../../screens/taker_tabs/jobs_tab.dart';
import '../../screens/taker_tabs/orders_tab.dart';
import '../../screens/taker_tabs/profile_tab.dart';

// Navigation items configuration
enum NavItem {
  home,
  city,
  job,
  offers,
  profile,
}

// Screen mappings
final navScreens = [
  const HomeTab(),
  const CityTab(),
  const JobsTab(),
  const OrdersTab(),
  const ProfileTab(),
];
