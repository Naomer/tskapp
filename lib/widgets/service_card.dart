import 'package:flutter/material.dart';
import '../screens/service_taker/service_providers_screen.dart';

class ServiceCard extends StatelessWidget {
  final Icon? icon;
  final String title;
  final Color color;
  final String categoryId;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? iconBackground;

  const ServiceCard({
    super.key,
    this.icon,
    required this.title,
    required this.color,
    required this.categoryId,
    this.onTap,
    this.width = 110,
    this.height = 130,
    this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? screenWidth * 0.28;
    final cardHeight = height ?? screenWidth * 0.33;
    final iconSize = screenWidth * 0.07;
    final fontSize = screenWidth * 0.035;

    // Split the title into words and join with newlines
    final formattedTitle = title.split(' ').join('\n');

    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceProvidersScreen(
                  serviceCategory: title,
                ),
              ),
            );
          },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (icon != null)
              Expanded(
                flex: 3,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.035),
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon!.icon,
                      size: iconSize,
                      color: icon!.color,
                    ),
                  ),
                ),
              )
            else
              const Spacer(flex: 3),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  formattedTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
