import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_palette.dart';
import 'core/theme/least_price_scroll_behavior.dart';
import 'core/utils/helpers.dart';
import 'core/widgets/global_runtime_error_screen.dart';
import 'features/admin/admin_dashboard_auth_gate.dart';
import 'features/auth/auth_gate.dart';
import 'firebase_options.dart';
import 'services/notifications/push_notification_service.dart';
import 'services/preferences/user_preferences_service.dart';

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
    unawaited(PushNotificationService.initialize());
  } catch (_) {
    firebaseBootstrapNotice =
        'تعذر تهيئة Firebase حالياً. تأكد من اكتمال ملفات FlutterFire وإعداد مشروع Firebase على المنصة الحالية.';
  }

  // Load saved user preferences before running the app
  isFeminineTheme.value = await UserPreferencesService.loadFeminineTheme();

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
    final applePlatform = isAppleTargetPlatform;
    return ValueListenableBuilder<bool>(
      valueListenable: isFeminineTheme,
      builder: (context, isFeminine, _) {
        final scheme = ColorScheme.fromSeed(
          seedColor: AppPalette.orange,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppPalette.orange,
          secondary: AppPalette.navy,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          surface: AppPalette.cardBackground,
          onSurface: AppPalette.paleOrange,
        );

        return ValueListenableBuilder<String>(
          valueListenable: appLang,
          builder: (context, lang, _) {
            final isEnglish = lang == 'en';

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: isEnglish ? 'LeastPrice' : 'أرخص سعر',
              locale: Locale(lang),
              scrollBehavior: const LeastPriceScrollBehavior(),
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
                platform:
                    applePlatform ? TargetPlatform.iOS : TargetPlatform.android,
                colorScheme: scheme,
                scaffoldBackgroundColor: AppPalette.shellBackground,
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.android:
                        FadeForwardsPageTransitionsBuilder(),
                  },
                ),
                cupertinoOverrideTheme: CupertinoThemeData(
                  primaryColor: AppPalette.orange,
                  scaffoldBackgroundColor: AppPalette.shellBackground,
                  barBackgroundColor: AppPalette.softOrange,
                ),
                snackBarTheme: const SnackBarThemeData(
                  behavior: SnackBarBehavior.floating,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: AppPalette.cardBackground,
                  hintStyle: TextStyle(color: AppPalette.mutedText),
                  labelStyle: TextStyle(color: AppPalette.paleOrange),
                  prefixIconColor: AppPalette.orange,
                  suffixIconColor: AppPalette.orange,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(applePlatform ? 16 : 18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(applePlatform ? 16 : 18),
                    borderSide: BorderSide(
                      color: AppPalette.cardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(applePlatform ? 16 : 18),
                    borderSide: BorderSide(
                      color: AppPalette.orange,
                      width: 1.5,
                    ),
                  ),
                ),
                cardTheme: CardThemeData(
                  color: AppPalette.cardBackground,
                  surfaceTintColor: Colors.transparent,
                  elevation: applePlatform ? 2 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(applePlatform ? 24 : 20),
                    side: BorderSide(
                      color: AppPalette.cardBorder,
                    ),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(applePlatform ? 16 : 18),
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
                    foregroundColor: AppPalette.paleOrange,
                    side: BorderSide(
                      color: AppPalette.paleOrange,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(applePlatform ? 16 : 18),
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
                  textDirection:
                      isEnglish ? TextDirection.ltr : TextDirection.rtl,
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
          },
        );
      },
    );
  }
}
