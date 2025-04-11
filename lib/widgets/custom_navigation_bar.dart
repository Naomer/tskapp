import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter/services.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
        child: ClipPath(
          clipper: BottomNotchClipper(),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF556A82),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavBarItem(
                  icon: IconlyBold.home,
                  unselectedIcon: IconlyLight.home,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(0);
                  },
                ),
                _NavBarItem(
                  icon: Icons.location_city,
                  unselectedIcon: Icons.location_city_outlined,
                  label: 'City',
                  isSelected: selectedIndex == 1,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(1);
                  },
                ),
                _NavBarItem(
                  icon: Icons.control_point,
                  unselectedIcon: Icons.control_point_outlined,
                  label: 'Jobs',
                  isSelected: selectedIndex == 2,
                  iconSize: 28,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(2);
                  },
                ),
                _NavBarItem(
                  icon: IconlyBold.bag,
                  unselectedIcon: IconlyLight.bag,
                  label: 'Order',
                  isSelected: selectedIndex == 3,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(3);
                  },
                ),
                _NavBarItem(
                  icon: IconlyBold.profile,
                  unselectedIcon: IconlyLight.profile,
                  label: 'Profile',
                  isSelected: selectedIndex == 4,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(4);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData unselectedIcon;
  final String label;
  final bool isSelected;
  final double iconSize;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.unselectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                isSelected ? icon : unselectedIcon,
                color: isSelected ? const Color(0xff18c0c1) : Colors.white,
                size: iconSize,
              ),
            ),
            if (!isSelected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BottomNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);

    // Start point of the notch with a smooth curve
    path.lineTo(size.width / 2 - 20, size.height);
    path.quadraticBezierTo(
      size.width / 2 - 15, // control point x
      size.height, // control point y
      size.width / 2 - 10, // end point x
      size.height - 2, // end point y
    );

    // Create curved top of the notch
    path.quadraticBezierTo(
      size.width / 2, // control point x
      size.height - 8, // control point y
      size.width / 2 + 10, // end point x
      size.height - 2, // end point y
    );

    // End point of the notch with a smooth curve
    path.quadraticBezierTo(
      size.width / 2 + 15, // control point x
      size.height, // control point y
      size.width / 2 + 20, // end point x
      size.height, // end point y
    );

    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
