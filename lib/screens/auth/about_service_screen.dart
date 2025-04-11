import 'package:flutter/material.dart';
import '../../models/service_provider_registration.dart';
import 'working_time_screen.dart';

class AboutServiceScreen extends StatefulWidget {
  final ServiceProviderRegistration registration;

  const AboutServiceScreen({
    super.key,
    required this.registration,
  });

  @override
  State<AboutServiceScreen> createState() => _AboutServiceScreenState();
}

class _AboutServiceScreenState extends State<AboutServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _professionController = TextEditingController();
  final _experienceController = TextEditingController();
  final List<String> _selectedServices = [];

  final List<String> _availableServices = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Cleaning',
    'Moving',
    'Gardening',
    'Other',
  ];

  @override
  void dispose() {
    _professionController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate() && _selectedServices.isNotEmpty) {
      widget.registration
        ..mainProfession = _professionController.text
        ..experience = _experienceController.text
        ..services = _selectedServices;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkingTimeScreen(
            registration: widget.registration,
          ),
        ),
      );
    } else if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(6),
          padding: EdgeInsets.zero,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 241, 247, 248),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.black,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About Your Services',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell us about your professional services',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _professionController,
                  decoration: InputDecoration(
                    labelText: 'Main Profession',
                    hintText: 'e.g. Plumber, Electrician',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your main profession';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _experienceController,
                  decoration: InputDecoration(
                    labelText: 'Years of Experience',
                    hintText: 'e.g. 5 years',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your experience';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Services Offered',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableServices.map((service) {
                    final isSelected = _selectedServices.contains(service);
                    return FilterChip(
                      label: Text(service),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedServices.add(service);
                          } else {
                            _selectedServices.remove(service);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: const Color(0xFF5D7A7F),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D7A7F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
