import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/widgets/global_runtime_error_screen.dart';
import 'features/auth/auth_gate.dart';
import 'features/admin/admin_dashboard_auth_gate.dart';

import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/core/theme/app_palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalRuntimeErrorScreen(details: details);
  };

  String? firebaseBootstrapNotice;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    firebaseBootstrapNotice =
        'تعذر تهيئة Firebase حالياً. تأكد من اكتمال ملفات FlutterFire وإعداد مشروع Firebase على المنصة الحالية.';
  }

  runApp(
    ProviderScope(
      child: LeastPriceApp(firebaseBootstrapNotice: firebaseBootstrapNotice),
    ),
  );
}

class LeastPriceApp extends StatelessWidget {
  const LeastPriceApp({
    super.key,
    this.firebaseBootstrapNotice,
  });

  final String? firebaseBootstrapNotice;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.orange,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppPalette.orange,
      secondary: AppPalette.navy,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: AppPalette.softOrange,
    );

    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final isEnglish = lang == 'en';
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: isEnglish ? 'LeastPrice' : 'أرخص سعر',
          locale: Locale(lang),
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            scaffoldBackgroundColor: AppPalette.shellBackground,
            snackBarTheme: const SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFFFE8D2),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppPalette.paleOrange),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: AppPalette.orange,
                  width: 1.5,
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                foregroundColor: AppPalette.orange,
                side: const BorderSide(color: AppPalette.paleOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: isAdminDashboardRequest()
              ? AdminDashboardAuthGate(
                  firebaseReady: firebaseBootstrapNotice == null,
                  bootstrapNotice: firebaseBootstrapNotice,
                )
              : AuthGate(
                  firebaseReady: firebaseBootstrapNotice == null,
                  bootstrapNotice: firebaseBootstrapNotice,
                ),
        );
      }, // end ValueListenableBuilder
    );
  }
}
