import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconly/iconly.dart';
import '../services/storage_service.dart';
import '../../screens/service_taker/help_support_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class AppDrawer extends StatefulWidget {
  final bool isProvider;

  const AppDrawer({
    super.key,
    this.isProvider = false,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _drawerSlideAnimation;
  late Animation<double> _itemsSlideAnimation;
  late Animation<double> _itemsFadeAnimation;
  bool _initialized = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final user = storageService.getUser();
    if (mounted) {
      setState(() {
        _userName = user?.name;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final isRTL = context.locale.languageCode == 'ar';
      _drawerSlideAnimation = Tween<double>(
        begin: isRTL ? 1.0 : -1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));

      _itemsSlideAnimation = Tween<double>(
        begin: isRTL ? 0.5 : -0.5,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ));

      _itemsFadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ));

      _animationController.forward();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = context.locale.languageCode == 'ar';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_drawerSlideAnimation.value * 100, 0),
          child: Drawer(
            backgroundColor: Colors.white,
            elevation: 0,
            width: 280,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: isRTL ? Radius.zero : const Radius.circular(20),
                bottomRight: isRTL ? Radius.zero : const Radius.circular(20),
                topLeft: isRTL ? const Radius.circular(20) : Radius.zero,
                bottomLeft: isRTL ? const Radius.circular(20) : Radius.zero,
              ),
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Transform.translate(
                    offset: Offset(_itemsSlideAnimation.value * 100, 0),
                    child: Opacity(
                      opacity: _itemsFadeAnimation.value,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildDrawerItem(
                            icon: IconlyLight.home,
                            title: 'home'.tr(),
                            onTap: () => Navigator.pop(context),
                          ),
                          _buildDrawerItem(
                            icon: IconlyLight.document,
                            title: 'settings.language'.tr(),
                            onTap: () => Navigator.pushNamed(
                                context, '/settings/language'),
                          ),
                          _buildDrawerItem(
                            icon: IconlyLight.info_circle,
                            title: 'help_support'.tr(),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HelpSupportScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 32),
                          FutureBuilder<bool>(
                            future: _isUserLoggedIn(),
                            builder: (context, snapshot) {
                              final bool isLoggedIn = snapshot.data ?? false;
                              return _buildDrawerItem(
                                icon: isLoggedIn
                                    ? IconlyLight.logout
                                    : IconlyLight.login,
                                title:
                                    isLoggedIn ? 'logout'.tr() : 'login'.tr(),
                                isDestructive: isLoggedIn,
                                onTap: () async {
                                  Navigator.pop(context);
                                  if (isLoggedIn) {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final storageService =
                                        StorageService(prefs);
                                    await storageService.clearUserData();
                                    if (context.mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/login',
                                        (route) => false,
                                      );
                                    }
                                  } else {
                                    Navigator.pushNamed(context, '/login');
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final isRTL = context.locale.languageCode == 'ar';
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: widget.isProvider ? Colors.blue[600] : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: isRTL ? const Radius.circular(20) : Radius.zero,
          topRight: isRTL ? Radius.zero : const Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _userName != null && _userName!.isNotEmpty
                ? Center(
                    child: Text(
                      _userName![0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        color: widget.isProvider
                            ? Colors.blue[600]
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Icon(
                    IconlyLight.profile,
                    size: 40,
                    color:
                        widget.isProvider ? Colors.blue[600] : Colors.grey[600],
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName ?? 'welcome'.tr(),
            style: TextStyle(
              color: widget.isProvider ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isRTL = context.locale.languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (!isRTL) ...[
                  Icon(
                    icon,
                    size: 24,
                    color: isDestructive ? Colors.red : Colors.grey[700],
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDestructive ? Colors.red : Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDestructive ? Colors.red : Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    icon,
                    size: 24,
                    color: isDestructive ? Colors.red : Colors.grey[700],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    return !storageService.isGuest();
  }
}
