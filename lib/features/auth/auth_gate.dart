import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_exports.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.firebaseReady,
    this.bootstrapNotice,
  });

  final bool firebaseReady;
  final String? bootstrapNotice;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return FirebaseSetupScreen(message: bootstrapNotice);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthLoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        if (user.isAnonymous) {
          return const LegacyAnonymousSessionCleanupScreen();
        }

        return AuthenticatedBootstrap(
          user: user,
          bootstrapNotice: bootstrapNotice,
        );
      },
    );
  }
}
