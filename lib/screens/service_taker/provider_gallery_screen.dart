import 'package:flutter/material.dart';

class ProviderGalleryScreen extends StatelessWidget {
  final String providerName;

  const ProviderGalleryScreen({
    super.key,
    required this.providerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 241, 247, 248),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          '$providerName\'s Gallery',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: 9, // Example count
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // TODO: Show full-screen image view
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                'https://picsum.photos/500/500?random=${index + 1}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image, size: 40, color: Colors.grey[400]);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
