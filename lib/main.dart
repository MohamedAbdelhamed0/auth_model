// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth/CacheHelper.dart';
import 'auth/presentation/manager/auth_cubit.dart';
import 'auth/presentation/pages/SplashPage.dart';
import 'auth/presentation/pages/home_screen.dart';
import 'auth/presentation/pages/sign_in_screen.dart';
import 'auth/presentation/pages/sign_up_screen.dart';
import 'firebase_options.dart';
import 'service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await CacheHelper.init(); // Initialize CacheHelper
  setupLocator();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final AuthCubit authCubit = AuthCubit();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (context) => authCubit,
      child: MaterialApp(
        title: 'Auth App',
        routes: {
          '/signin': (context) => SignInScreen(),
          '/signup': (context) => SignUpScreen(),
          '/home': (context) => HomeScreen(),
        },
        home: SplashPage(),
      ),
    );
  }
}
