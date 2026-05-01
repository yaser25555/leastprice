import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/core/utils/helpers.dart';

class AdminAccessDeniedScreen extends StatelessWidget {
  const AdminAccessDeniedScreen({super.key, 
    required this.user,
  });

  final User user;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppPalette.cardBackground,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.shadow,
                    blurRadius: 28,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_person_rounded,
                    size: 52,
                    color: Color(0xFFE0675A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('هذا الحساب ليس مشرفاً',
                        'This account is not an admin'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(
                      'البريد الحالي هو ${user.email ?? 'غير معروف'}، بينما اللوحة مسموحة فقط للبريد ${LeastPriceDataConfig.adminEmail}.',
                      'The current email is ${user.email ?? 'unknown'}, while this dashboard is only allowed for ${LeastPriceDataConfig.adminEmail}.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppPalette.softNavy,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(tr('تسجيل الخروج', 'Sign out')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
