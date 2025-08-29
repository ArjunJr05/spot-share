import 'package:spot_share2/core/constants/app_router_constants.dart';
import 'package:spot_share2/features/bottom_nav/presentation/screens/bottom_nav.dart';
import 'package:spot_share2/features/home/presentation/screens/home_screen.dart';
import 'package:spot_share2/features/splash/presentation/screens/splash_screen.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash Screens
    GoRoute(
      path: '/splash',
      name: AppRouterConstants.splash,
      builder: (context, state) {
        return const SplashScreen();
      },
    ),


    // Home Screen
    GoRoute(
      path: '/home',
      name: AppRouterConstants.home,
      builder: (context, state) {
        return const EnhancedHomePage();
      },
    ),

    // bottomNav
    GoRoute(
      path: '/bottomNav',
      name: AppRouterConstants.bottomNav,
      builder: (context, state) {
        return MainPage();
      },
    ),
  ],
);
