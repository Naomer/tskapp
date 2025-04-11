import 'package:flutter/material.dart';

class ProfessionScreen extends StatelessWidget {
  const ProfessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profession'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: const Center(
        child: Text('Profession Screen'),
      ),
    );
  }
}
