import 'package:spot_share2/core/constants/app_router_constants.dart';
import 'package:spot_share2/features/login/presentation/screens/login.dart';
import 'package:spot_share2/features/placeHolder/bottom_nav/presentation/screens/bottom_nav.dart';
import 'package:spot_share2/features/signin/presentation/screens/signin.dart';
import 'package:spot_share2/features/users/bottom_nav/presentation/screens/bottom_nav.dart';
import 'package:spot_share2/features/users/home/presentation/screens/home_screen.dart';
import 'package:spot_share2/features/users/splash/presentation/screens/splash_screen.dart';
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

    // GoRoute(
    //   path: '/clientHome',
    //   name: AppRouterConstants.clientHome,
    //   builder: (context, state) {
    //     return ClientHomeScreen();
    //   },
    // ),

    GoRoute(
      path: '/clientMainPage',
      name: AppRouterConstants.clientMainPage,
      builder: (context, state) {
        return ClientMainPage();
      },
    ),

    GoRoute(
      path: '/authLogIn',
      name: AppRouterConstants.authLogIn,
      builder: (context, state) {
        return LoginScreen();
      },
    ),

      GoRoute(
      path: '/authSignIn',
      name: AppRouterConstants.authSignIn,
      builder: (context, state) {
        return SignupScreen();
      },
    ),
  ],
);
