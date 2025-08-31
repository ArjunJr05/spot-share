// main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spot_share2/features/users/bot/presentation/screens/bot.dart';
import 'package:spot_share2/features/users/bottom_nav/presentation/bloc/bottom_nav_bloc.dart';
import 'package:spot_share2/features/users/bottom_nav/presentation/bloc/bottom_nav_event.dart';
import 'package:spot_share2/features/users/bottom_nav/presentation/bloc/bottom_nav_state.dart';
import 'package:spot_share2/features/users/home/presentation/screens/home_screen.dart';
import 'package:spot_share2/features/users/map/presentation/screens/map_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _pages = const [
    EnhancedHomePage(),
    MapScreen(),
    ProfileScreen(),
    ChatbotPage()
  ];

  static const List<NavItemData> _navItems = [
    NavItemData(icon: Icons.home_rounded, text: 'Home', index: 0),
    NavItemData(icon: Icons.map_rounded, text: 'Map', index: 1),
    NavItemData(icon: Icons.person_rounded, text: 'Profile', index: 2),
    NavItemData(icon: Icons.auto_awesome_rounded, text: 'Bot', index: 3),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(
    BuildContext context,
    int tappedIndex,
    int currentIndex,
  ) {
    if (tappedIndex != currentIndex) {
      _animationController.reset();
      context.read<BottomNavBloc>().add(BottomNavIndexChanged(tappedIndex));
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BottomNavBloc(),
      child: BlocBuilder<BottomNavBloc, BottomNavState>(
        builder: (context, state) {
          final currentIndex = state.currentIndex;

          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: _pages[currentIndex],
            bottomNavigationBar: Container(
              margin: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 16.0,
              ),
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(25.0),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _navItems.map((item) {
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) => PillNavItem(
                          icon: item.icon,
                          text: item.text,
                          isSelected: currentIndex == item.index,
                          onTap: () => _onNavItemTapped(
                            context,
                            item.index,
                            currentIndex,
                          ),
                          scaleAnimation: _scaleAnimation,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Nav Item Data Model
class NavItemData {
  final IconData icon;
  final String text;
  final int index;

  const NavItemData({
    required this.icon,
    required this.text,
    required this.index,
  });
}

// Pill-style Nav Item Widget
class PillNavItem extends StatefulWidget {
  final IconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final Animation<double>? scaleAnimation;

  const PillNavItem({
    super.key,
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.scaleAnimation,
  });

  @override
  State<PillNavItem> createState() => _PillNavItemState();
}

class _PillNavItemState extends State<PillNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _pressController.forward();
  }

  void _onTapUp() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _onTapDown(),
        onTapUp: (_) => _onTapUp(),
        onTapCancel: () => _pressController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pressAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pressAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                height: 38,
                decoration: widget.isSelected
                    ? BoxDecoration(
                        color: const Color(0xFF3B46F1),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.icon,
                        key: ValueKey(
                            '${widget.icon.codePoint}-${widget.isSelected}'),
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                    if (widget.isSelected) ...[
  const SizedBox(width: 8),
  Flexible(  // 👈 prevents overflow
    child: AnimatedOpacity(
      opacity: widget.isSelected ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: FittedBox( // 👈 scales text if it's too long
        fit: BoxFit.scaleDown,
        child: Text(
  widget.text,
  maxLines: 1,
  overflow: TextOverflow.ellipsis, // 👈 adds "..." if too long
  style: const TextStyle(
    color: Colors.white,
    fontSize: 13, // 👈 slightly smaller
    fontWeight: FontWeight.w500,
  ),
),

      ),
    ),
  ),
],

                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


// Enhanced Profile Screen with Dark Theme
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'John Doe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'john.doe@example.com',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildProfileOption(
                      icon: Icons.edit_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update your information',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                    _buildProfileOption(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      subtitle: 'Manage your alerts',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                    ),
                    _buildProfileOption(
                      icon: Icons.security_rounded,
                      title: 'Privacy & Security',
                      subtitle: 'Control your privacy',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                    ),
                    _buildProfileOption(
                      icon: Icons.help_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get assistance',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      ),
                    ),
                    _buildProfileOption(
                      icon: Icons.info_rounded,
                      title: 'About',
                      subtitle: 'App information',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                      ),
                    ),
                    _buildProfileOption(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      isLogout: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: Colors.white.withOpacity(0.5),
        ),
        onTap: () {
          // Handle option tap
        },
      ),
    );
  }
}