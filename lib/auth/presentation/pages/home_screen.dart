// lib/auth/presentation/pages/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user.dart';
import '../manager/auth_cubit.dart';
import '../manager/auth_state.dart';
import 'sign_in_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError || state is Unauthenticated) {
          // Navigate to sign-in screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
            (route) => false,
          );
          // Show error message if any
          if (state is AuthError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        }
      },
      child: _buildHomeContent(context),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
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
                // No need to navigate manually; BlocListener handles it
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

// In the code snippet above, we have the  HomeScreen  widget that displays the user's username and a button to sign out. The  HomeScreen  widget is wrapped in a  BlocListener  widget that listens to the  AuthCubit  state. If the state is  AuthError  or  Unauthenticated , the user is navigated to the sign-in screen.
// The  HomeScreen  widget is also used in the  SplashPage  widget to navigate to the home screen when the user is authenticated.
// Run the app and test the sign-out functionality.
// Conclusion
// In this tutorial, we learned how to implement user authentication in a Flutter app using Firebase Authentication and the BLoC pattern. We created a simple authentication flow with sign-in, sign-up, and sign-out functionality.
// We also learned how to use the  BlocListener  widget to listen to state changes in the  AuthCubit  and navigate to different screens based on the state.
// You can find the complete source code for this tutorial on  GitHub.
// Happy coding!
// Peer Review Contributions by:  Saiharsha Balasubramaniam
