import 'package:flutter/material.dart';
import '../../screens/prov_tabs/home_tab_prov.dart';
import '../../screens/prov_tabs/job_tab_prov.dart';
import '../../screens/prov_tabs/offers_tab_prov.dart';
import '../../screens/prov_tabs/profile_tab_prov.dart';

// Navigation items configuration
enum NavItem {
  home,
  job,
  offers,
  profile,
}

// Screen mappings
final navScreens = [
  const HomeTabProv(),
  const JobTabProvider(),
  const OffersTab(),
  const ProfileTabProv(),
];
