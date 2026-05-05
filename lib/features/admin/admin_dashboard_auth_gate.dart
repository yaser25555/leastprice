import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/auth/firebase_setup_screen.dart';
import 'package:leastprice/features/auth/auth_loading_screen.dart';
import 'admin_exports.dart';

class AdminDashboardAuthGate extends StatelessWidget {
  const AdminDashboardAuthGate({
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
          return AuthLoadingScreen(
            title:
                tr('جارٍ تجهيز لوحة التحكم', 'Preparing the admin dashboard'),
            message: tr(
              'نربط لوحة الإدارة بخدمات Firebase ونجهز صلاحيات المشرف.',
              'We are connecting the dashboard to Firebase and preparing admin access.',
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const AdminLoginScreen();
        }

        final isPrimaryAdmin = (user.email ?? '').trim().toLowerCase() ==
            LeastPriceDataConfig.adminEmail.toLowerCase();
        if (isPrimaryAdmin) {
          return AdminControlCenter(adminUser: user);
        }

        const service = FirestoreCatalogService();
        return StreamBuilder<UserSavingsProfile?>(
          stream: service.watchUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;
            if (profile != null && profile.isMarketingManager) {
              return AdminControlCenter(adminUser: user);
            }
            return AdminAccessDeniedScreen(user: user);
          },
        );
      },
    );
  }
}
