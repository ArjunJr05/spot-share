import 'dart:async';
import 'package:spot_share2/core/constants/app_router_constants.dart';
import 'package:flutter/material.dart';
import 'package:spot_share2/core/constants/app_assets_constants.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      // Auth Login Screen
      GoRouter.of(context).pushReplacementNamed(AppRouterConstants.authLogIn);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          AppAssetsConstants.fitNoshSplashLogo,
          height: 320,
          width: 320,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
