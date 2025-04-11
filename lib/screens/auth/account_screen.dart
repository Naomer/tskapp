import 'package:flutter/material.dart';
import '../../models/service_provider_registration.dart';
import 'easypaisa_screen.dart';

class AccountScreen extends StatefulWidget {
  final ServiceProviderRegistration registration;

  const AccountScreen({
    super.key,
    required this.registration,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _selectedMethod;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'EasyPaisa',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
    },
    {
      'name': 'JazzCash',
      'icon': Icons.phone_android,
      'color': Colors.red,
    },
    {
      'name': 'Bank Account',
      'icon': Icons.account_balance,
      'color': Colors.blue,
    },
  ];

  void _handleNext() {
    if (_selectedMethod != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EasyPaisaScreen(
            registration: widget.registration,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
        ),
      );
    }
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final bool isSelected = _selectedMethod == method['name'];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? method['color'] : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method['name'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: method['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  method['icon'],
                  color: method['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                method['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: method['color'],
                ),
            ],
          ),
        ),
      ),
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your preferred payment method',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ..._paymentMethods.map(_buildPaymentMethodCard).toList(),
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
    );
  }
}
