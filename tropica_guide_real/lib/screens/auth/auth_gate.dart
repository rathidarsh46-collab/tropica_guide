import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../routes.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Auth state stream = best beginner-friendly pattern.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in
        if (!snapshot.hasData) {
          // Send to login screen
          Future.microtask(() {
            Navigator.pushReplacementNamed(context, Routes.login);
          });
          return const SizedBox.shrink();
        }

        // Logged in
        Future.microtask(() {
          Navigator.pushReplacementNamed(context, Routes.myTrips);
        });
        return const SizedBox.shrink();
      },
    );
  }
}
