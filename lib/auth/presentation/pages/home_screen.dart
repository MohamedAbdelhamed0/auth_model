// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user.dart';
import '../manager/auth_cubit.dart';
import '../manager/auth_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    UserModel? user;

    // Get the user from the current state
    final state = authCubit.state;
    if (state is Authenticated) {
      user = state.user;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome, ${user?.username ?? 'User'}!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                authCubit.signOut();
                Navigator.pushReplacementNamed(context, '/signin');
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
