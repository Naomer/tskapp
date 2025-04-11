import 'package:flutter/material.dart';

class ServiceProviderHomeScreen extends StatelessWidget {
  const ServiceProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text('Service Provider Home Screen'),
      ),
    );
  }
}
