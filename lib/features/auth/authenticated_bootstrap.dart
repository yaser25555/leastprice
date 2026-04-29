import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/features/home/least_price_home_page.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'auth_exports.dart';

class AuthenticatedBootstrap extends StatefulWidget {
  const AuthenticatedBootstrap({
    super.key,
    required this.user,
    this.bootstrapNotice,
  });

  final User user;
  final String? bootstrapNotice;

  @override
  State<AuthenticatedBootstrap> createState() => _AuthenticatedBootstrapState();
}

class _AuthenticatedBootstrapState extends State<AuthenticatedBootstrap> {
  final FirestoreCatalogService _catalogService =
      const FirestoreCatalogService();
  late Future<UserSavingsProfile> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _catalogService.ensureUserProfile(
      user: widget.user,
      pendingInviteCode: PendingAuthSession.consumeInviteCode(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserSavingsProfile>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AuthLoadingScreen(
            title:
                tr('جارٍ تجهيز حسابك', 'Preparing your account'),
            message: tr(
              'نربط ملفك الشخصي والدعوات والعروض قبل فتح التطبيق.',
              'We are linking your profile, invites, and offers before opening the app.',
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return AuthBootstrapErrorScreen(
            message: tr(
              'تعذر تجهيز ملف المستخدم من Firestore. تأكد من الاتصال ثم جرّب مرة أخرى.',
              'Unable to prepare your Firestore profile. Check the connection and try again.',
            ),
            onRetry: () {
              setState(() {
                _bootstrapFuture = _catalogService.ensureUserProfile(
                  user: widget.user,
                  pendingInviteCode: PendingAuthSession.consumeInviteCode(),
                );
              });
            },
            onSignOut: () => FirebaseAuth.instance.signOut(),
          );
        }

        return LeastPriceHomePage(
          firebaseReady: true,
          bootstrapNotice: widget.bootstrapNotice,
          currentUser: widget.user,
          initialUserProfile: snapshot.data!,
        );
      },
    );
  }
}
