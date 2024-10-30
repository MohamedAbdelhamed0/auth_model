// lib/auth/presentation/pages/home_screen.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/user.dart';
import '../manager/auth_cubit.dart';
import '../manager/auth_state.dart';
import 'sign_in_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError || state is Unauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
            (route) => false,
          );
          if (state is AuthError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        } else if (state is AuthSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));

          // Delay for 3 seconds before navigating back to the authenticated view
          Future.delayed(Duration(seconds: 3), () {
            context
                .read<AuthCubit>()
                .checkAuthStatus(); // Re-check authentication
          });
        }
      },
      builder: (context, state) {
        if (state is Authenticated) {
          UserModel user = state.user;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Home'),
              actions: [
                user.profilePhotoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user.profilePhotoUrl!),
                      )
                    : IconButton(
                        icon: Icon(Icons.account_circle),
                        onPressed: () {
                          _pickAndUploadProfilePhoto(context);
                        },
                      ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('Welcome, ${user.username}!'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Primary User:'),
                        Icon(IconData(user.isPrimary ? 0xe5ca : 0xe5cb,
                            fontFamily: 'MaterialIcons')),
                        Switch(
                          value: user.isPrimary,
                          onChanged: (value) {
                            context.read<AuthCubit>().updateIsPrimary(value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Subscription Start Date: ${user.subscriptionStartDate != null ? DateFormat('yyyy-MM-dd').format(user.subscriptionStartDate!) : 'Not Set'}',
                    ),
                    Text(
                      'Subscription End Date: ${user.subscriptionEndDate != null ? DateFormat('yyyy-MM-dd').format(user.subscriptionEndDate!) : 'Not Set'}',
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _selectSubscriptionDates(context);
                      },
                      child: Text('Update Subscription Dates'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _pickAndUploadProfilePhoto(context);
                      },
                      child: Text('Upload Profile Photo'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthCubit>().signOut();
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (state is AuthLoading || state is AuthInitial) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is AuthSuccess) {
          // Show success message for 3 seconds
          return Scaffold(
            body: Center(child: Text('Operation completed successfully.')),
          );
        } else {
          // Fallback for unexpected states
          return Scaffold(
            body: Center(child: Text('An error occurred.')),
          );
        }
      },
    );
  }

  void _selectSubscriptionDates(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime? startDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(Duration(days: 365)),
      lastDate: now.add(Duration(days: 365)),
    );

    if (startDate == null) return;

    DateTime? endDate = await showDatePicker(
      context: context,
      initialDate: startDate.add(Duration(days: 30)),
      firstDate: startDate,
      lastDate: startDate.add(Duration(days: 365)),
    );

    if (endDate == null) return;

    context.read<AuthCubit>().updateSubscriptionDates(startDate, endDate);
  }

  void _pickAndUploadProfilePhoto(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      PlatformFile file = result.files.first;
      context.read<AuthCubit>().updateProfilePhoto(file);
    }
  }
}
