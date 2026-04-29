import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:leastprice/features/auth/auth_loading_screen.dart';
import 'auth_exports.dart';

class LegacyAnonymousSessionCleanupScreen extends StatefulWidget {
  const LegacyAnonymousSessionCleanupScreen({super.key});

  @override
  State<LegacyAnonymousSessionCleanupScreen> createState() =>
      _LegacyAnonymousSessionCleanupScreenState();
}

class _LegacyAnonymousSessionCleanupScreenState
    extends State<LegacyAnonymousSessionCleanupScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(FirebaseAuth.instance.signOut());
  }

  @override
  Widget build(BuildContext context) {
    return const AuthLoadingScreen(
      title: 'جارٍ إنهاء الجلسة القديمة',
      message:
          'نحدّث طريقة الدخول إلى البريد الإلكتروني حتى تظهر لك شاشة التسجيل الجديدة.',
    );
  }
}
