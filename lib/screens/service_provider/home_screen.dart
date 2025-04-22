import 'package:flutter/material.dart';
import '../prov_tabs/home_tab_prov.dart';
import '../prov_tabs/job_tab_prov.dart';
import '../prov_tabs/offers_tab_prov.dart';
import '../prov_tabs/profile_tab_prov.dart';
import '../../widgets/provider_navigation_bar.dart';
import '../../widgets/app_drawer.dart';

class ServiceProviderHomeScreen extends StatefulWidget {
  const ServiceProviderHomeScreen({super.key});

  @override
  State<ServiceProviderHomeScreen> createState() =>
      _ServiceProviderHomeScreenState();
}

class _ServiceProviderHomeScreenState extends State<ServiceProviderHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const HomeTabProv(),
    const JobTabProvider(),
    const OffersTab(),
    const ProfileTabProv(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(isProvider: true),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
