// main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spot_share2/features/users/bot/presentation/screens/bot.dart';
import 'package:spot_share2/features/users/bottom_nav/presentation/bloc/bottom_nav_bloc.dart';
import 'package:spot_share2/features/users/bottom_nav/presentation/bloc/bottom_nav_event.dart';
import 'package:spot_share2/features/users/bottom_nav/presentation/bloc/bottom_nav_state.dart';
import 'package:spot_share2/features/users/home/presentation/screens/home_screen.dart';
import 'package:spot_share2/features/users/map/presentation/screens/map_screen.dart';
import 'package:spot_share2/features/users/profile/presentation/screens/profile_screen.dart';

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
    ChatbotPage(),
    DriverProfileScreen(),
  ];

  static const List<NavItemData> _navItems = [
    NavItemData(icon: Icons.home_rounded, text: 'Home', index: 0),
    NavItemData(icon: Icons.map_rounded, text: 'Map', index: 1),
    NavItemData(icon: Icons.auto_awesome_rounded, text: 'Bot', index: 2),
    NavItemData(icon: Icons.person_rounded, text: 'Profile', index: 3),
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

