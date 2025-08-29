import 'package:spot_share2/core/di/service_locator.dart';
import 'package:spot_share2/core/router/app_router.dart';
import 'package:spot_share2/features/bottom_nav/presentation/bloc/bottom_nav_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Service Locator (DI)
  setUpServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Bottom Nav Bloc
        BlocProvider(create: (context) => getIt<BottomNavBloc>()),
      ],
      child: MaterialApp.router(
        title: 'spot_share2 Customer App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
