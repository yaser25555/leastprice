import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

// ── Language System ──────────────────────────────────────────────────────────
final ValueNotifier<String> appLang = ValueNotifier<String>('ar');

bool get _isAr => appLang.value == 'ar';

String tr(String ar, String en) => _isAr ? ar : en;

String requiredFieldMessage(String arLabel, String enLabel) =>
    tr('$arLabel مطلوب.', '$enLabel is required.');

String validValueMessage(String arLabel, String enLabel) => tr(
      'أدخل قيمة صحيحة لـ $arLabel.',
      'Enter a valid value for $enLabel.',
    );

String validUrlMessage(String arLabel, String enLabel) => tr(
      'أدخل $arLabel صالحاً يبدأ بـ http أو https.',
      'Enter a valid $enLabel that starts with http or https.',
    );

String localizedCategoryLabelForId(
  String categoryId, {
  String? fallbackLabel,
}) {
  switch (categoryId.trim()) {
    case ProductCategoryCatalog.allId:
      return tr('الكل', 'All');
    case 'coffee':
      return tr('قهوة', 'Coffee');
    case 'roasters':
      return tr('محامص', 'Roasters');
    case 'restaurants':
      return tr('مطاعم', 'Restaurants');
    case 'perfumes':
      return tr('عطور', 'Perfumes');
    case 'cosmetics':
      return tr('تجميل', 'Beauty');
    case 'pharmacy':
      return tr('صيدلية', 'Pharmacy');
    case 'detergents':
      return tr('منظفات', 'Detergents');
    case 'dairy':
      return tr('ألبان', 'Dairy');
    case 'canned':
      return tr('معلبات', 'Canned');
    case 'tea':
      return tr('شاي', 'Tea');
    case 'juice':
      return tr('عصير', 'Juice');
    default:
      return localizedKnownLabel(fallbackLabel ?? categoryId);
  }
}

String localizedKnownLabel(String value) {
  final normalized = _normalizeArabic(value);

  if (normalized == 'الكل') return tr('الكل', 'All');
  if (normalized == 'قهوه') return tr('قهوة', 'Coffee');
  if (normalized == 'محامص') return tr('محامص', 'Roasters');
  if (normalized == 'مطاعم') return tr('مطاعم', 'Restaurants');
  if (normalized == 'عطور') return tr('عطور', 'Perfumes');
  if (normalized == 'تجميل') return tr('تجميل', 'Beauty');
  if (normalized == 'صيدليه') return tr('صيدلية', 'Pharmacy');
  if (normalized == 'منظفات') return tr('منظفات', 'Detergents');
  if (normalized == 'البان') return tr('ألبان', 'Dairy');
  if (normalized == 'معلبات') return tr('معلبات', 'Canned');
  if (normalized == 'شاي') return tr('شاي', 'Tea');
  if (normalized == 'عصير') return tr('عصير', 'Juice');
  if (normalized == _normalizeArabic(LeastPriceDataConfig.originalOnSaleTag)) {
    return tr(
      'المنتج الأصلي عليه عرض حالياً',
      'Original product is on sale now',
    );
  }
  if (normalized == _normalizeArabic('توفير خارق')) {
    return tr('توفير خارق', 'Super saving');
  }

  return value;
}

class AppPalette {
  const AppPalette._();

  static const Color navy = Color(0xFF1B2F5E);
  static const Color deepNavy = Color(0xFF12284D);
  static const Color softNavy = Color(0xFF6B7A9A);
  static const Color orange = Color(0xFFE8711A);
  static const Color paleOrange = Color(0xFFFFD9BA);
  static const Color softOrange = Color(0xFFFFF3E8);
  static const Color comparisonEmerald = Color(0xFF0F8F6A);
  static const Color comparisonSoftEmerald = Color(0xFFEAF8F3);
  static const Color comparisonBorder = Color(0xFFB6E6D7);
  static const Color dealsRed = Color(0xFFD94B45);
  static const Color dealsSoftRed = Color(0xFFFFF0EE);
  static const Color dealsBorder = Color(0xFFF5B2A7);
  static const Color shellBackground = Color(0xFFF5F7FF);
  static const Color cardBackground = Color(0xFFF8FAFF);
  static const Color cardBorder = Color(0xFFE1E7F4);
  static const Color panelText = Color(0xFF2A426D);
  static const Color mutedText = Color(0xFF6B7A9A);
  static const Color shadow = Color(0x141B2F5E);
}

enum HomeCatalogSection {
  offers,
  comparisons,
}

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({
    super.key,
    this.size = 58,
    this.padding = 8,
    this.backgroundColor = Colors.white,
    this.borderRadius = 20,
  });

  final double size;
  final double padding;
  final Color backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Image.asset(
        'assets/icons/app_icon_navy.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return _GlobalRuntimeErrorScreen(details: details);
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
    LeastPriceApp(firebaseBootstrapNotice: firebaseBootstrapNotice),
  );
}

bool _isAdminDashboardRequest([Uri? uri]) {
  final target = uri ?? Uri.base;
  final path = '/${target.pathSegments.join('/')}';
  final fragment = target.fragment;

  return _isAdminPathToken(path) ||
      _isAdminPathToken(fragment) ||
      target.queryParameters['admin'] == '1' ||
      target.queryParameters['view']?.toLowerCase() == 'admin';
}

bool _isAdminPathToken(String? rawValue) {
  final value = (rawValue ?? '').trim().toLowerCase().replaceAll('\\', '/');
  if (value.isEmpty) {
    return false;
  }

  return value == 'admin' ||
      value == '/admin' ||
      value.endsWith('/admin') ||
      value.startsWith('/admin?');
}

bool _isAllowedAdminEmail(String? email) {
  return (email ?? '').trim().toLowerCase() ==
      LeastPriceDataConfig.adminEmail.toLowerCase();
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
      surface: Colors.white,
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
              fillColor: Colors.white,
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
          home: _isAdminDashboardRequest()
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

class _GlobalRuntimeErrorScreen extends StatelessWidget {
  const _GlobalRuntimeErrorScreen({
    required this.details,
  });

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: AppPalette.shellBackground,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: AppPalette.shadow,
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFD14B4B),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr(
                              'حدث خطأ أثناء بناء الواجهة',
                              'A runtime UI error occurred',
                            ),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr(
                        'بدلاً من الصفحة البيضاء، يعرض التطبيق الآن سبب الخطأ ليسهل علينا إصلاحه بسرعة.',
                        'Instead of a blank page, the app now shows the error details so we can fix it faster.',
                      ),
                      style: const TextStyle(
                        color: AppPalette.softNavy,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPalette.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppPalette.cardBorder),
                      ),
                      child: SelectableText(
                        details.exceptionAsString(),
                        style: const TextStyle(
                          color: AppPalette.panelText,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      details.library ?? 'Flutter',
                      style: const TextStyle(
                        color: AppPalette.softNavy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      return _FirebaseSetupScreen(message: bootstrapNotice);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        if (user.isAnonymous) {
          return const _LegacyAnonymousSessionCleanupScreen();
        }

        return AuthenticatedBootstrap(
          user: user,
          bootstrapNotice: bootstrapNotice,
        );
      },
    );
  }
}

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
  final FirestoreCatalogService _catalogService = const FirestoreCatalogService();
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
          return _AuthLoadingScreen(
            title: tr('جارٍ تجهيز حسابك', 'Preparing your account'),
            message: tr(
              'نربط ملفك الشخصي والدعوات والعروض قبل فتح التطبيق.',
              'We are linking your profile, invites, and offers before opening the app.',
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _AuthBootstrapErrorScreen(
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
      return _FirebaseSetupScreen(message: bootstrapNotice);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _AuthLoadingScreen(
            title: tr('جارٍ تجهيز لوحة التحكم', 'Preparing the admin dashboard'),
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

        if (!_isAllowedAdminEmail(user.email)) {
          return _AdminAccessDeniedScreen(user: user);
        }

        return AdminDashboardScreen(adminUser: user);
      },
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: LeastPriceDataConfig.adminEmail,
  );
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _statusMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _submit() async {
    final normalizedEmail = _normalizeEmailAddress(_emailController.text);
    final password = _passwordController.text.trim();

    if (normalizedEmail == null) {
      setState(() {
        _statusMessage = tr(
          'أدخل بريد المشرف الإلكتروني بصيغة صحيحة.',
          'Enter a valid admin email address.',
        );
      });
      return;
    }

    if (!_isAllowedAdminEmail(normalizedEmail)) {
      setState(() {
        _statusMessage = tr(
          'هذه اللوحة مقيدة ببريد المشرف ${LeastPriceDataConfig.adminEmail} فقط.',
          'This dashboard is restricted to ${LeastPriceDataConfig.adminEmail} only.',
        );
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _statusMessage = tr(
          'أدخل كلمة المرور للمتابعة.',
          'Enter the password to continue.',
        );
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = tr(
          'تم تسجيل دخول المشرف بنجاح.',
          'Admin signed in successfully.',
        );
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = _arabicAuthMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = tr(
          'تعذر فتح لوحة التحكم حالياً: $error',
          'Unable to open the admin dashboard right now: $error',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
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
                  const Center(child: AppBrandMark(size: 72, borderRadius: 24)),
                  const SizedBox(height: 16),
                  Text(
                    tr('لوحة تحكم LeastPrice', 'LeastPrice Admin Dashboard'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(
                      'سجّل ببريد المشرف لإدارة البنرات والمنتجات مباشرة من المتصفح. هذه اللوحة محمية ببريد ${LeastPriceDataConfig.adminEmail}.',
                      'Sign in with the admin email to manage banners and products directly from the browser. This dashboard is protected for ${LeastPriceDataConfig.adminEmail}.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppPalette.softNavy,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: tr('بريد المشرف', 'Admin email'),
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: tr('كلمة المرور', 'Password'),
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _isSubmitting ? null : _submit(),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPalette.softOrange,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppPalette.paleOrange),
                      ),
                      child: Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppPalette.panelText,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(
                      _isSubmitting
                          ? tr('جارٍ الدخول...', 'Signing in...')
                          : tr('دخول المشرف', 'Admin sign in'),
                    ),
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

class _AdminAccessDeniedScreen extends StatelessWidget {
  const _AdminAccessDeniedScreen({
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
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
                    tr('هذا الحساب ليس مشرفاً', 'This account is not an admin'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                    style: const TextStyle(
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

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.adminUser,
  });

  final User adminUser;

  @override
  Widget build(BuildContext context) {
    const service = FirestoreCatalogService();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 24,
        toolbarHeight: 82,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('لوحة تحكم LeastPrice', 'LeastPrice Admin Dashboard'),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2F5E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              adminUser.email ?? LeastPriceDataConfig.adminEmail,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7A9A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: Text(tr('خروج', 'Exit')),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _AdminDashboardBody(service: service),
    );
  }
}

class _AdminDashboardBody extends StatefulWidget {
  const _AdminDashboardBody({required this.service});
  final FirestoreCatalogService service;

  @override
  State<_AdminDashboardBody> createState() => _AdminDashboardBodyState();
}

class _AdminDashboardBodyState extends State<_AdminDashboardBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.view_carousel_rounded),
                text: tr('البنرات', 'Banners'),
              ),
              Tab(
                icon: const Icon(Icons.compare_arrows_rounded),
                text: tr('المقارنات', 'Comparisons'),
              ),
              Tab(
                icon: const Icon(Icons.local_offer_rounded),
                text: tr('العروض', 'Deals'),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AdminBannersTable(catalogService: widget.service),
              _AdminProductsTable(catalogService: widget.service),
              _AdminExclusiveDealsTable(catalogService: widget.service),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── لوحة البنرات البسيطة ────────────────────────────────────────────────────
class _AdminSimpleBannersPanel extends StatefulWidget {
  const _AdminSimpleBannersPanel({required this.service});
  final FirestoreCatalogService service;

  @override
  State<_AdminSimpleBannersPanel> createState() =>
      _AdminSimpleBannersPanelState();
}

class _AdminSimpleBannersPanelState extends State<_AdminSimpleBannersPanel> {
  Future<void> _add() async {
    final banner = await showDialog<AdBannerItem>(
      context: context,
      builder: (_) => const _AdminBannerEditorDialog(),
    );
    if (banner == null || !mounted) return;
    try {
      await widget.service.saveAdBanner(banner);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تمت إضافة البنر بنجاح.', 'Banner added successfully.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _edit(AdBannerItem banner) async {
    final updated = await showDialog<AdBannerItem>(
      context: context,
      builder: (_) => _AdminBannerEditorDialog(initialBanner: banner),
    );
    if (updated == null || !mounted) return;
    try {
      await widget.service.saveAdBanner(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم تحديث البنر بنجاح.', 'Banner updated successfully.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _delete(AdBannerItem banner) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr('حذف البنر', 'Delete banner')),
            content: Text(tr('هل تريد حذف "${banner.title}"؟', 'Do you want to delete "${banner.title}"?')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(tr('إلغاء', 'Cancel'))),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(tr('حذف', 'Delete'))),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    try {
      await widget.service.deleteAdBanner(banner.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم حذف البنر.', 'Banner deleted.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _publishMockToFirestore() async {
    try {
      for (final b in AdBannerItem.mockData) {
        await widget.service.saveAdBanner(b);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم نشر البنرات التجريبية في Firestore.', 'Mock banners were published to Firestore.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('خطأ أثناء النشر: $e', 'Publishing error: $e'))));
      }
    }
  }

  Widget _buildBannerCard(AdBannerItem b, {bool isMock = false}) {
    return Card(
      color: isMock ? const Color(0xFFFFF8E1) : null,
      child: ListTile(
        leading: b.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(b.imageUrl,
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported_rounded)),
              )
            : const Icon(Icons.image_rounded, size: 40),
        title: Text(b.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            isMock ? '📦 تجريبي — ${b.storeName}' : b.storeName,
            style: TextStyle(
                color: isMock ? Colors.orange[800] : null)),
        trailing: isMock
            ? ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await widget.service.saveAdBanner(b);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(tr('تم نشر "${b.title}" في Firestore.', '"${b.title}" was published to Firestore.'))),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
                    }
                  }
                },
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(tr('نشر', 'Publish')),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _edit(b)),
                  IconButton(
                      icon: const Icon(Icons.delete_rounded,
                          color: Colors.red),
                      onPressed: () => _delete(b)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: StreamBuilder<List<AdBannerItem>>(
        stream: widget.service.watchAdminAdBanners(),
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final firestoreList = snap.data ?? [];
          final isMock = !isLoading && firestoreList.isEmpty;
          final displayList =
              isMock ? AdBannerItem.mockData : firestoreList;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'البنرات الإعلانية',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2F5E)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMock)
                          OutlinedButton.icon(
                            onPressed: _publishMockToFirestore,
                            icon: const Icon(Icons.cloud_upload_rounded),
                            label: Text(tr('نشر الكل في Firestore', 'Publish all to Firestore')),
                          ),
                        if (isMock) const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _add,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(tr('إضافة بنر', 'Add banner')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isMock)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Firestore فارغة — تعرض البنرات التجريبية. اضغط "نشر" لحفظها.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(tr('خطأ: ${snap.error}', 'Error: ${snap.error}'),
                      style: const TextStyle(color: Colors.red)),
                ),
              if (isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _buildBannerCard(displayList[i], isMock: isMock),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr('إضافة بنر', 'Add banner')),
      ),
    );
  }
}

// ─── لوحة المنتجات البسيطة ───────────────────────────────────────────────────
class _AdminSimpleProductsPanel extends StatefulWidget {
  const _AdminSimpleProductsPanel({required this.service});
  final FirestoreCatalogService service;

  @override
  State<_AdminSimpleProductsPanel> createState() =>
      _AdminSimpleProductsPanelState();
}

class _AdminSimpleProductsPanelState
    extends State<_AdminSimpleProductsPanel> {
  Future<void> _add() async {
    final product = await showDialog<ProductComparison>(
      context: context,
      builder: (_) => const _AdminProductEditorDialog(),
    );
    if (product == null || !mounted) return;
    try {
      await widget.service.saveProduct(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تمت إضافة المنتج بنجاح.', 'Product added successfully.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _edit(ProductComparison product) async {
    final updated = await showDialog<ProductComparison>(
      context: context,
      builder: (_) => _AdminProductEditorDialog(initialProduct: product),
    );
    if (updated == null || !mounted) return;
    try {
      await widget.service.saveProduct(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم تحديث المنتج بنجاح.', 'Product updated successfully.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _delete(ProductComparison product) async {
    final docId = product.documentId;
    if (docId == null) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr('حذف المنتج', 'Delete product')),
            content: Text(tr('هل تريد حذف "${product.expensiveName}"؟', 'Do you want to delete "${product.expensiveName}"?')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(tr('إلغاء', 'Cancel'))),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(tr('حذف', 'Delete'))),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    try {
      await widget.service.deleteProduct(docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم حذف المنتج.', 'Product deleted.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
      }
    }
  }

  Future<void> _publishMockToFirestore() async {
    try {
      for (final p in ProductComparison.mockData) {
        await widget.service.saveProduct(p);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم نشر المنتجات التجريبية في Firestore.', 'Mock products were published to Firestore.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('خطأ أثناء النشر: $e', 'Publishing error: $e'))));
      }
    }
  }

  Widget _buildProductCard(ProductComparison p, {bool isMock = false}) {
    return Card(
      color: isMock ? const Color(0xFFFFF8E1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1B2F5E),
          child: Text(
            p.categoryLabel.isNotEmpty ? p.categoryLabel[0] : '؟',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          '${p.expensiveName}  →  ${p.alternativeName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          isMock
              ? '📦 تجريبي — ${p.categoryLabel} | ${p.expensivePrice} ر.س  →  ${p.alternativePrice} ر.س'
              : '${p.categoryLabel} | ${p.expensivePrice} ر.س  →  ${p.alternativePrice} ر.س',
          style: TextStyle(color: isMock ? Colors.orange[800] : null),
        ),
        trailing: isMock
            ? ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await widget.service.saveProduct(p);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('تم نشر "${p.expensiveName}".', '"${p.expensiveName}" was published.'))),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(tr('خطأ: $e', 'Error: $e'))));
                    }
                  }
                },
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(tr('نشر', 'Publish')),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _edit(p)),
                  IconButton(
                      icon: const Icon(Icons.delete_rounded,
                          color: Colors.red),
                      onPressed: () => _delete(p)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: StreamBuilder<List<ProductComparison>>(
        stream: widget.service.watchAllProducts(),
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final firestoreList = snap.data ?? [];
          final isMock = !isLoading && firestoreList.isEmpty;
          final displayList =
              isMock ? ProductComparison.mockData : firestoreList;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'بطاقات المقارنة',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2F5E)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMock)
                          OutlinedButton.icon(
                            onPressed: _publishMockToFirestore,
                            icon: const Icon(Icons.cloud_upload_rounded),
                            label: Text(tr('نشر الكل في Firestore', 'Publish all to Firestore')),
                          ),
                        if (isMock) const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _add,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(tr('إضافة منتج', 'Add product')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isMock)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Firestore فارغة — تعرض المنتجات التجريبية. اضغط "نشر" لحفظها.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(tr('خطأ: ${snap.error}', 'Error: ${snap.error}'),
                      style: const TextStyle(color: Colors.red)),
                ),
              if (isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _buildProductCard(displayList[i], isMock: isMock),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr('إضافة منتج', 'Add product')),
      ),
    );
  }
}

class AdminControlCenter extends StatelessWidget {
  const AdminControlCenter({
    super.key,
    required this.adminUser,
  });

  final User adminUser;

  @override
  Widget build(BuildContext context) {
    const service = FirestoreCatalogService();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 24,
        toolbarHeight: 82,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'لوحة تحكم LeastPrice',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2F5E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              adminUser.email ?? LeastPriceDataConfig.adminEmail,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7A9A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: Text(tr('خروج', 'Sign out')),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _AdminBannerManagerPanel(catalogService: service),
            SizedBox(height: 24),
            _AdminProductManagerPanel(catalogService: service),
          ],
        ),
      ),
    );
  }
}

class _AdminBannerManagerPanel extends StatefulWidget {
  const _AdminBannerManagerPanel({
    required this.catalogService,
  });

  final FirestoreCatalogService catalogService;

  @override
  State<_AdminBannerManagerPanel> createState() =>
      _AdminBannerManagerPanelState();
}

class _AdminBannerManagerPanelState extends State<_AdminBannerManagerPanel> {
  Future<void> _openEditor({AdBannerItem? initialBanner}) async {
    final banner = await showDialog<AdBannerItem>(
      context: context,
      builder: (context) => _AdminBannerEditorDialog(initialBanner: initialBanner),
    );

    if (banner == null || !mounted) {
      return;
    }

    try {
      await widget.catalogService.saveAdBanner(banner);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initialBanner == null
                ? tr('تمت إضافة البنر بنجاح.', 'Banner added successfully.')
                : tr('تم تحديث البنر بنجاح.', 'Banner updated successfully.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حفظ البنر حالياً: $error',
              'Unable to save the banner right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _publishBanner(AdBannerItem banner) async {
    try {
      await widget.catalogService.publishAdBanner(banner.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تم تحديث lastUpdated للبنر بنجاح.',
              'Banner lastUpdated was refreshed successfully.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر نشر البنر حالياً: $error',
              'Unable to publish the banner right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteBanner(AdBannerItem banner) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('حذف البنر', 'Delete banner')),
            content: Text(
              tr(
                'هل تريد حذف البنر "${banner.title}" نهائياً؟',
                'Do you want to permanently delete the banner "${banner.title}"?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(tr('حذف', 'Delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await widget.catalogService.deleteAdBanner(banner.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('تم حذف البنر.', 'Banner deleted.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حذف البنر حالياً: $error',
              'Unable to delete the banner right now: $error',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة البنرات الإعلانية',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'أضف أو عدّل أو احذف البنرات في ad_banners مع نشر التحديث فوراً للمستخدمين.',
                    style: TextStyle(
                      color: Color(0xFF667C74),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('إضافة بنر', 'Add banner')),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _AdminDashboardSectionCard(
          child: StreamBuilder<List<AdBannerItem>>(
            stream: widget.catalogService.watchAdminAdBanners(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'تعذر تحميل البنرات من Firestore: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7A9A)),
                  ),
                );
              }

              final banners = snapshot.data ?? const <AdBannerItem>[];
              if (banners.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا توجد بنرات بعد. أضف أول بنر من الزر العلوي.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7A9A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: banners.map((banner) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FCFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2EFEA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AdminNetworkThumbnail(
                            imageUrl: banner.imageUrl,
                            label: banner.title,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF17332B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (banner.subtitle.trim().isNotEmpty)
                                  Text(
                                    banner.subtitle,
                                    style: const TextStyle(
                                      color: Color(0xFF61756D),
                                      height: 1.4,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _AdminStatusChip(
                                      label: banner.active ? 'نشط' : 'مخفي',
                                      color: banner.active
                                          ? const Color(0xFFE8711A)
                                          : const Color(0xFF9A6B6B),
                                    ),
                                    _AdminStatusChip(
                                      label: 'الترتيب ${banner.order}',
                                      color: const Color(0xFF375F54),
                                    ),
                                  ],
                                ),
                                if (banner.targetUrl.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    banner.targetUrl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF6D8079),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 210,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _openEditor(initialBanner: banner),
                                  child: Text(tr('تعديل', 'Edit')),
                                ),
                                OutlinedButton(
                                  onPressed: () => _publishBanner(banner),
                                  child: Text(tr('نشر', 'Publish')),
                                ),
                                OutlinedButton(
                                  onPressed: () => _deleteBanner(banner),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFC24E4E),
                                  ),
                                  child: Text(tr('حذف', 'Delete')),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminProductManagerPanel extends StatefulWidget {
  const _AdminProductManagerPanel({
    required this.catalogService,
  });

  final FirestoreCatalogService catalogService;

  @override
  State<_AdminProductManagerPanel> createState() =>
      _AdminProductManagerPanelState();
}

class _AdminProductManagerPanelState extends State<_AdminProductManagerPanel> {
  Future<void> _openEditor({ProductComparison? initialProduct}) async {
    final product = await showDialog<ProductComparison>(
      context: context,
      builder: (context) =>
          _AdminProductEditorDialog(initialProduct: initialProduct),
    );

    if (product == null || !mounted) {
      return;
    }

    try {
      await widget.catalogService.saveProduct(product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initialProduct == null
                ? tr('تمت إضافة المنتج بنجاح.', 'Product added successfully.')
                : tr('تم تحديث المنتج بنجاح.', 'Product updated successfully.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حفظ المنتج حالياً: $error',
              'Unable to save the product right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _publishProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'احفظ المنتج أولاً قبل نشره.',
              'Save the product first before publishing it.',
            ),
          ),
        ),
      );
      return;
    }

    try {
      await widget.catalogService.publishProduct(documentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تم تحديث lastUpdated للمنتج بنجاح.',
              'Product lastUpdated was refreshed successfully.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر نشر المنتج حالياً: $error',
              'Unable to publish the product right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'هذا المنتج غير مرتبط بوثيقة Firestore.',
              'This product is not linked to a Firestore document.',
            ),
          ),
        ),
      );
      return;
    }

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('حذف المنتج', 'Delete product')),
            content: Text(
              tr(
                'هل تريد حذف "${product.expensiveName}" و"${product.alternativeName}" نهائياً؟',
                'Do you want to permanently delete "${product.expensiveName}" and "${product.alternativeName}"?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(tr('حذف', 'Delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await widget.catalogService.deleteProduct(documentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('تم حذف المنتج.', 'Product deleted.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حذف المنتج حالياً: $error',
              'Unable to delete the product right now: $error',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة المنتجات',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'عدّل الأسماء والأسعار والصور ثم انشر التحديث ليظهر فوراً داخل التطبيق.',
                    style: TextStyle(
                      color: Color(0xFF667C74),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('إضافة منتج', 'Add product')),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _AdminDashboardSectionCard(
          child: StreamBuilder<List<ProductComparison>>(
            stream: widget.catalogService.watchAllProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'تعذر تحميل المنتجات من Firestore: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7A9A)),
                  ),
                );
              }

              final products = snapshot.data ?? const <ProductComparison>[];
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا توجد منتجات بعد. أضف أول منتج من الزر العلوي.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7A9A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: products.map((product) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FCFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2EFEA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AdminNetworkThumbnail(
                                imageUrl: product.expensiveImageUrl,
                                label: product.expensiveName,
                              ),
                              const SizedBox(width: 10),
                              _AdminNetworkThumbnail(
                                imageUrl: product.alternativeImageUrl,
                                label: product.alternativeName,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.categoryLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF6A7C74),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${product.expensiveName}  •  ${formatAmountValue(product.expensivePrice)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF17332B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${product.alternativeName}  •  ${formatAmountValue(product.alternativePrice)}',
                                      style: const TextStyle(
                                        color: Color(0xFF436459),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (product.buyUrl.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        product.buyUrl,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF6D8079),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    _openEditor(initialProduct: product),
                                child: Text(tr('تعديل', 'Edit')),
                              ),
                              OutlinedButton(
                                onPressed: () => _publishProduct(product),
                                child: Text(tr('نشر', 'Publish')),
                              ),
                              OutlinedButton(
                                onPressed: () => _deleteProduct(product),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFC24E4E),
                                ),
                                child: Text(tr('حذف', 'Delete')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminDashboardSectionCard extends StatelessWidget {
  const _AdminDashboardSectionCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110C3B2E),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _rememberMePrefKey = 'remember_login_enabled';
  static const String _rememberedEmailPrefKey = 'remembered_login_email';
  final FirestoreCatalogService _catalogService = const FirestoreCatalogService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  bool _isSendingPasswordReset = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRememberedLoginInfo());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberMePrefKey) ?? false;
    final email = prefs.getString(_rememberedEmailPrefKey) ?? '';
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember && email.trim().isNotEmpty) {
        _emailController.text = email.trim();
      }
    });
  }

  Future<void> _persistRememberedLoginInfo(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_rememberMePrefKey, true);
      await prefs.setString(_rememberedEmailPrefKey, email.trim());
      return;
    }

    await prefs.setBool(_rememberMePrefKey, false);
    await prefs.remove(_rememberedEmailPrefKey);
  }

  Future<void> _submitAuth() async {
    final messenger = ScaffoldMessenger.of(context);
    final normalizedPhone = _isRegisterMode
        ? _formatSaudiPhoneNumber(_phoneController.text)
        : null;
    final normalizedEmail = _normalizeEmailAddress(_emailController.text);
    final password = _passwordController.text.trim();
    final referralCode = _isRegisterMode
        ? _referralController.text.trim().toUpperCase()
        : '';

    if (_isRegisterMode && normalizedPhone == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'رقم الجوال إلزامي. أدخله بصيغة 05XXXXXXXX أو +9665XXXXXXXX.',
              'Phone number is required. Enter it as 05XXXXXXXX or +9665XXXXXXXX.',
            ),
          ),
        ),
      );
      return;
    }

    if (normalizedEmail == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'أدخل بريداً إلكترونياً صحيحاً لتسجيل الدخول وإنشاء الحساب.',
              'Enter a valid email address to sign in or create an account.',
            ),
          ),
        ),
      );
      return;
    }

    if (password.length < 6) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'كلمة المرور يجب أن تكون 6 أحرف على الأقل.',
              'Password must be at least 6 characters.',
            ),
          ),
        ),
      );
      return;
    }

    PendingAuthSession.setInviteCode(referralCode);
    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    try {
      UserCredential credential;
      if (_isRegisterMode) {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      } else {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      }

      final user = credential.user;
      if (user == null) {
        throw FormatException(
          tr(
            'لم يتم إنشاء جلسة مستخدم في Firebase.',
            'Firebase did not create a user session.',
          ),
        );
      }

      await _catalogService.ensureUserProfile(
        user: user,
        pendingInviteCode: PendingAuthSession.consumeInviteCode(),
        requiredPhoneNumber: _isRegisterMode ? normalizedPhone : null,
        emailAddress: normalizedEmail,
      );
      await _persistRememberedLoginInfo(normalizedEmail);
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _statusMessage = _isRegisterMode
            ? tr(
                'تم إنشاء الحساب بنجاح. يمكنك الدخول مباشرة باستخدام البريد الإلكتروني وكلمة المرور.',
                'Your account was created successfully. You can now sign in using your email and password.',
              )
            : tr('تم تسجيل الدخول بنجاح.', 'Signed in successfully.');
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = _arabicAuthMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = tr(
          'تعذر إكمال تسجيل الدخول حالياً: $error',
          'Unable to complete sign-in right now: $error',
        );
      });
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final normalizedEmail = _normalizeEmailAddress(_emailController.text);
    if (normalizedEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'أدخل البريد الإلكتروني أولاً لإرسال رابط إعادة تعيين كلمة المرور.',
              'Enter your email first to send the password reset link.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSendingPasswordReset = true;
      _statusMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: normalizedEmail);
      if (!mounted) return;
      setState(() {
        _isSendingPasswordReset = false;
        _statusMessage =
            tr(
              'أرسلنا إلى $normalizedEmail رابطاً لإعادة تعيين كلمة المرور. افحص البريد وصندوق الرسائل غير المرغوبة.',
              'We sent a password reset link to $normalizedEmail. Check your inbox and spam folder.',
            );
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSendingPasswordReset = false;
        _statusMessage = _arabicAuthMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSendingPasswordReset = false;
        _statusMessage = tr(
          'تعذر إرسال رابط استعادة كلمة المرور: $error',
          'Unable to send the password reset link: $error',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppPalette.navy, AppPalette.shellBackground],
            stops: [0.18, 0.18],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: AppPalette.shadow,
                            blurRadius: 26,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppBrandMark(size: 64, borderRadius: 20),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'LeastPrice',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppPalette.navy,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isRegisterMode
                                          ? tr(
                                              'أنشئ حسابك بسرعة.',
                                              'Create your account in seconds.',
                                            )
                                          : tr(
                                              'سجّل دخولك للمتابعة.',
                                              'Sign in to continue.',
                                            ),
                                      style: const TextStyle(
                                        color: AppPalette.softNavy,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: tr('البريد الإلكتروني', 'Email'),
                              hintText: 'name@example.com',
                              prefixIcon: const Icon(Icons.alternate_email_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: tr('كلمة المرور', 'Password'),
                              hintText: tr('6 أحرف أو أكثر', '6 characters or more'),
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          CheckboxListTile(
                            value: _rememberMe,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppPalette.orange,
                            title: Text(
                              tr(
                                'تذكر البريد الإلكتروني على هذا الجهاز',
                                'Remember my email on this device',
                              ),
                              style: const TextStyle(
                                color: AppPalette.panelText,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                          ),
                          if (_isRegisterMode) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: tr('رقم الجوال', 'Phone number'),
                                hintText: '05XXXXXXXX',
                                prefixIcon: const Icon(Icons.phone_android_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _referralController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: tr(
                                  'كود الدعوة (اختياري)',
                                  'Referral code (optional)',
                                ),
                                hintText: 'LP-AB12',
                                prefixIcon: const Icon(Icons.card_giftcard_rounded),
                              ),
                            ),
                          ],
                          if (_statusMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppPalette.softOrange,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppPalette.paleOrange),
                              ),
                              child: Text(
                                _statusMessage!,
                                style: const TextStyle(
                                  color: AppPalette.panelText,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting || _isSendingPasswordReset
                                ? null
                                : _submitAuth,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isRegisterMode
                                        ? Icons.person_add_alt_1_rounded
                                        : Icons.login_rounded,
                                  ),
                            label: Text(
                              _isSubmitting
                                  ? tr('جارٍ التنفيذ...', 'Processing...')
                                  : (_isRegisterMode
                                      ? tr('إنشاء الحساب', 'Create account')
                                      : tr('دخول', 'Sign in')),
                            ),
                          ),
                          if (!_isRegisterMode) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                TextButton(
                                  onPressed:
                                      _isSubmitting || _isSendingPasswordReset
                                          ? null
                                          : () {
                                              setState(() {
                                                _isRegisterMode = true;
                                                _statusMessage = null;
                                              });
                                            },
                                  child: Text(tr('إنشاء حساب', 'Create account')),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed:
                                      _isSubmitting || _isSendingPasswordReset
                                          ? null
                                          : _sendPasswordResetEmail,
                                  child: Text(
                                    _isSendingPasswordReset
                                        ? tr(
                                            'جارٍ إرسال الرابط...',
                                            'Sending link...',
                                          )
                                        : tr(
                                            'نسيت كلمة المرور؟',
                                            'Forgot password?',
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        setState(() {
                                          _isRegisterMode = false;
                                          _statusMessage = null;
                                        });
                                      },
                                child: Text(
                                  tr(
                                    'لديك حساب؟ تسجيل الدخول',
                                    'Already have an account? Sign in',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegacyAnonymousSessionCleanupScreen extends StatefulWidget {
  const _LegacyAnonymousSessionCleanupScreen();

  @override
  State<_LegacyAnonymousSessionCleanupScreen> createState() =>
      _LegacyAnonymousSessionCleanupScreenState();
}

class _LegacyAnonymousSessionCleanupScreenState
    extends State<_LegacyAnonymousSessionCleanupScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(FirebaseAuth.instance.signOut());
  }

  @override
  Widget build(BuildContext context) {
    return const _AuthLoadingScreen(
      title: 'جارٍ إنهاء الجلسة القديمة',
      message: 'نحدّث طريقة الدخول إلى البريد الإلكتروني حتى تظهر لك شاشة التسجيل الجديدة.',
    );
  }
}

class _EmailVerificationPendingScreen extends StatefulWidget {
  const _EmailVerificationPendingScreen({
    required this.user,
  });

  final User user;

  @override
  State<_EmailVerificationPendingScreen> createState() =>
      _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState
    extends State<_EmailVerificationPendingScreen> {
  bool _isRefreshing = false;
  bool _isResending = false;
  String? _statusMessage;

  Future<void> _refreshVerificationStatus() async {
    setState(() {
      _isRefreshing = true;
      _statusMessage = null;
    });

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (!mounted) return;

      setState(() {
        _isRefreshing = false;
        _statusMessage = refreshedUser?.emailVerified == true
            ? 'تم التحقق من البريد الإلكتروني بنجاح. سننقلك الآن إلى التطبيق.'
            : 'لم يتم تفعيل البريد بعد. افتح الرسالة الواردة ثم ارجع واضغط "تحققت من البريد".';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _statusMessage = _arabicAuthMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _statusMessage = 'تعذر تحديث حالة التفعيل: $error';
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
      _statusMessage = null;
    });

    try {
      await widget.user.sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _statusMessage =
            'أعدنا إرسال رابط التفعيل إلى ${widget.user.email ?? 'بريدك الإلكتروني'}. افحص البريد الأساسي والرسائل غير المرغوبة.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _statusMessage = _arabicAuthMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _statusMessage = 'تعذر إعادة إرسال رسالة التفعيل: $error';
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140C3B2E),
                    blurRadius: 26,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 52,
                    color: Color(0xFFE8711A),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'فعّل بريدك الإلكتروني أولاً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'أرسلنا رابط تفعيل إلى ${widget.user.email ?? 'بريدك الإلكتروني'}. التفعيل عبر البريد أوفر من رسائل الجوال، لذلك لن ندخلك قبل تأكيد الإيميل.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF61756D),
                      height: 1.55,
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2FBF7),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD6EEE6)),
                      ),
                      child: Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF245044),
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isRefreshing || _isResending
                        ? null
                        : _refreshVerificationStatus,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.verified_rounded),
                label: Text(tr('تحققت من البريد', 'I verified my email')),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isRefreshing || _isResending
                        ? null
                        : _resendVerificationEmail,
                    icon: _isResending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.forward_to_inbox_rounded),
                label: Text(tr('إعادة إرسال رابط التفعيل', 'Resend verification link')),
                  ),
                  TextButton(
                    onPressed: _isRefreshing || _isResending ? null : _signOut,
                  child: Text(tr('استخدام بريد إلكتروني آخر', 'Use another email')),
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

class PendingAuthSession {
  const PendingAuthSession._();

  static String? _inviteCode;

  static void setInviteCode(String rawInviteCode) {
    final normalized = rawInviteCode.trim().toUpperCase();
    _inviteCode = normalized.isEmpty ? null : normalized;
  }

  static String? consumeInviteCode() {
    final value = _inviteCode;
    _inviteCode = null;
    return value;
  }
}

String? _formatSaudiPhoneNumber(String rawNumber) {
  final digits = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+9665') && digits.length == 13) {
    return digits;
  }
  if (digits.startsWith('9665') && digits.length == 12) {
    return '+$digits';
  }
  if (digits.startsWith('05') && digits.length == 10) {
    return '+966${digits.substring(1)}';
  }
  if (digits.startsWith('5') && digits.length == 9) {
    return '+966$digits';
  }
  return null;
}

String? _normalizeEmailAddress(String rawEmail) {
  final value = rawEmail.trim().toLowerCase();
  if (value.isEmpty) {
    return null;
  }

  const pattern = r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$';
  return RegExp(pattern, caseSensitive: false).hasMatch(value) ? value : null;
}

String _normalizedImageUrl(
  String? rawUrl, {
  String fallbackLabel = 'LeastPrice',
}) {
  final value = (rawUrl ?? '').trim();

  // رابط فارغ أو localhost أو غير صالح → placeholder آمنة
  final isLocalhost = value.contains('localhost') ||
      value.contains('127.0.0.1') ||
      value.contains('0.0.0.0');
  final isValidScheme =
      value.startsWith('http://') || value.startsWith('https://');

  if (value.isEmpty || isLocalhost || !isValidScheme) {
    final encoded = Uri.encodeComponent(
        fallbackLabel.isNotEmpty ? fallbackLabel : 'LeastPrice');
    return 'https://placehold.co/900x600/EAF3EF/17332B?text=$encoded';
  }

  const brokenTokens = <String>[
    'photo-1570194065650-d99fb4d8a5c8',
    'photo-1556228578-dd6c36f7737d',
    'photo-1588405748880-12d1d2a59df9',
  ];

  for (final token in brokenTokens) {
    if (value.contains(token)) {
      final encoded = Uri.encodeComponent(fallbackLabel);
      return 'https://placehold.co/900x600/EAF3EF/17332B?text=$encoded';
    }
  }

  return value;
}

String _arabicAuthMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return tr(
        'صيغة البريد الإلكتروني غير صحيحة.',
        'The email format is invalid.',
      );
    case 'email-already-in-use':
      return tr(
        'هذا البريد مستخدم بالفعل. جرّب تسجيل الدخول بدلاً من إنشاء حساب جديد.',
        'This email is already in use. Try signing in instead of creating a new account.',
      );
    case 'weak-password':
      return tr(
        'كلمة المرور ضعيفة جداً. اختر كلمة مرور أقوى.',
        'The password is too weak. Choose a stronger password.',
      );
    case 'user-not-found':
    case 'invalid-credential':
      return tr(
        'بيانات الدخول غير صحيحة. تأكد من البريد وكلمة المرور.',
        'Your sign-in details are incorrect. Check your email and password.',
      );
    case 'wrong-password':
      return tr('كلمة المرور غير صحيحة.', 'Incorrect password.');
    case 'operation-not-allowed':
      return tr(
        'تسجيل الدخول بالبريد الإلكتروني وكلمة المرور غير مفعّل في Firebase Authentication بعد. فعّل مزود Email/Password من لوحة Firebase ثم أعد المحاولة.',
        'Email/password sign-in is not enabled in Firebase Authentication yet. Enable the Email/Password provider in Firebase, then try again.',
      );
    case 'internal-error':
      final details = (error.message ?? '').toUpperCase();
      if (details.contains('CONFIGURATION_NOT_FOUND')) {
        return tr(
          'إعدادات Firebase Authentication غير مكتملة لهذا النوع من تسجيل الدخول. فعّل Email/Password من Firebase Console ثم أعد المحاولة.',
          'Firebase Authentication is not fully configured for this sign-in method. Enable Email/Password in Firebase Console and try again.',
        );
      }
      return tr(
        'حدث خطأ داخلي في Firebase Authentication. تحقق من إعدادات تسجيل الدخول ثم أعد المحاولة.',
        'A Firebase Authentication internal error occurred. Check your sign-in settings and try again.',
      );
    case 'too-many-requests':
      return tr(
        'تم إجراء محاولات كثيرة. انتظر قليلاً ثم أعد المحاولة.',
        'Too many attempts were made. Please wait a moment and try again.',
      );
    case 'network-request-failed':
      return tr(
        'تعذر الاتصال بـ Firebase حالياً. تحقق من الإنترنت ثم أعد المحاولة.',
        'Unable to reach Firebase right now. Check your internet connection and try again.',
      );
    default:
      return error.message ??
          tr('حدث خطأ في المصادقة. حاول مرة أخرى.', 'Authentication failed. Try again.');
  }
}

DateTime? _dateTimeValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

String _formatHealthTimestamp(DateTime? value) {
  if (value == null) {
    return tr('بانتظار أول تحديث', 'Waiting for first update');
  }

  final local = value.toLocal();
  final twoDigitsHour = local.hour.toString().padLeft(2, '0');
  final twoDigitsMinute = local.minute.toString().padLeft(2, '0');
  final twoDigitsDay = local.day.toString().padLeft(2, '0');
  final twoDigitsMonth = local.month.toString().padLeft(2, '0');
  return '$twoDigitsHour:$twoDigitsMinute - $twoDigitsDay/$twoDigitsMonth';
}

String _formatDealExpiryLabel(DateTime? value) {
  if (value == null) {
    return tr('بدون تاريخ', 'No date');
  }

  final local = value.toLocal();
  final twoDigitsDay = local.day.toString().padLeft(2, '0');
  final twoDigitsMonth = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$twoDigitsDay/$twoDigitsMonth/$year';
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen({
    this.title = '',
    this.message = '',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFFE8711A),
              ),
              const SizedBox(height: 18),
              Text(
                title.isNotEmpty
                    ? title
                    : tr(
                        'جارٍ الاتصال بخدمات الدخول',
                        'Connecting to sign-in services',
                      ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF18352C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.isNotEmpty
                    ? message
                    : tr(
                        'نجهز جلسة Firebase ونربط حسابك بالتطبيق...',
                        'We are preparing your Firebase session and linking your account to the app...',
                      ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF61756D),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen({
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120C3B2E),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Color(0xFFB44B42),
                  size: 48,
                ),
                const SizedBox(height: 14),
                Text(
                  tr('Firebase غير جاهز', 'Firebase is not ready'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18352C),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message ??
                      tr(
                        'تعذر تهيئة Firebase حالياً. أكمل إعداد المصادقة وFirestore ثم أعد تشغيل التطبيق.',
                        'Firebase could not be initialized right now. Complete the Authentication and Firestore setup, then restart the app.',
                      ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF63766F),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBootstrapErrorScreen extends StatelessWidget {
  const _AuthBootstrapErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120C3B2E),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 50,
                  color: Color(0xFFB44B42),
                ),
                const SizedBox(height: 14),
                Text(
                  tr('تعذر فتح حسابك', 'Unable to open your account'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18352C),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF63766F),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(tr('إعادة المحاولة', 'Try again')),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(tr('تسجيل الخروج', 'Sign out')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LeastPriceHomePage extends StatefulWidget {
  const LeastPriceHomePage({
    super.key,
    required this.firebaseReady,
    required this.currentUser,
    required this.initialUserProfile,
    this.bootstrapNotice,
  });

  final bool firebaseReady;
  final User currentUser;
  final UserSavingsProfile initialUserProfile;
  final String? bootstrapNotice;

  @override
  State<LeastPriceHomePage> createState() => _LeastPriceHomePageState();
}

class _LeastPriceHomePageState extends State<LeastPriceHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreCatalogService _catalogService =
      const FirestoreCatalogService();
  final ProductRepository _fallbackRepository = const ProductRepository();
  final SerpApiShoppingSearchService _comparisonSearchService =
      const SerpApiShoppingSearchService();
  final Connectivity _connectivity = Connectivity();
  late Stream<List<ProductComparison>> _productsStream;
  StreamSubscription<dynamic>? _connectivitySubscription;
  StreamSubscription<UserSavingsProfile?>? _userProfileSubscription;
  StreamSubscription<List<AdBannerItem>>? _bannerSubscription;
  StreamSubscription<AutomationHealthStatus?>? _systemHealthSubscription;
  Timer? _smartSearchDebounce;
  String _query = '';
  String _selectedCategoryId = ProductCategoryCatalog.allId;
  HomeCatalogSection _selectedHomeSection = HomeCatalogSection.comparisons;
  bool _hasInternet = true;
  bool _isRefreshing = false;
  bool _isSearchingOnline = false;
  String? _dataNotice;
  String? _smartSearchNotice;
  String _comparisonSearchSourceLabel = tr('بحث السوق', 'Market search');
  ProductDataSource _dataSource = ProductDataSource.remote;
  UserSavingsProfile _userProfile = UserSavingsProfile.initial();
  AutomationHealthStatus _systemHealth = AutomationHealthStatus.initial();
  List<AdBannerItem> _activeBanners = AdBannerItem.mockData;
  List<ComparisonSearchResult> _comparisonSearchResults =
      const <ComparisonSearchResult>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _userProfile = widget.initialUserProfile;
    _dataNotice = widget.bootstrapNotice;
    _dataSource = widget.firebaseReady
        ? ProductDataSource.remote
        : ProductDataSource.asset;
    _productsStream = _buildProductsStream();

    if (widget.firebaseReady) {
      _userProfileSubscription = _catalogService
          .watchUserProfile(widget.currentUser.uid)
          .listen((profile) {
        if (!mounted || profile == null) {
          return;
        }
        setState(() {
          _userProfile = profile;
        });
      });
      _bannerSubscription = _catalogService.watchAdBanners().listen((banners) {
        if (!mounted) {
          return;
        }
        setState(() {
          _activeBanners = banners.isEmpty ? AdBannerItem.mockData : banners;
        });
      });
      _systemHealthSubscription = _catalogService.watchSystemHealth().listen((
        status,
      ) {
        if (!mounted || status == null) {
          return;
        }
        setState(() {
          _systemHealth = status;
        });
      });
      unawaited(_setupConnectivityMonitoring());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_refreshCatalog(showSuccessMessage: false));
      });
    }
  }

  Stream<List<ProductComparison>> _loadFallbackProducts() async* {
    try {
      final result = await _fallbackRepository.loadProducts();
      if (mounted) {
        setState(() {
          _userProfile = result.referralProfile ?? _userProfile;
          _dataSource = result.source;
          _dataNotice = _mergeNotices(
            widget.bootstrapNotice,
            result.notice ??
                tr(
                  'يتم عرض بيانات بديلة حالياً حتى يكتمل ربط Firebase على هذا الجهاز.',
                  'Fallback data is being shown for now until Firebase is fully connected on this device.',
                ),
          );
        });
      }

      yield result.products;
    } catch (error) {
      debugPrint('LeastPrice fallback catalog failed: $error');
      if (mounted) {
        setState(() {
          _dataSource = ProductDataSource.mock;
          _dataNotice = _mergeNotices(
            widget.bootstrapNotice,
            tr(
              'تعذر تحميل البيانات البديلة، لذا تم الرجوع إلى البيانات التجريبية المدمجة.',
              'Fallback data could not be loaded, so the app returned to bundled mock data.',
            ),
          );
        });
      }

      yield ProductComparison.mockData;
    }
  }

  Stream<List<ProductComparison>> _buildProductsStream() {
    if (!widget.firebaseReady) {
      return _loadFallbackProducts();
    }

    return _catalogService.watchProducts(
      categoryId: _selectedCategoryId,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _userProfileSubscription?.cancel();
    _bannerSubscription?.cancel();
    _systemHealthSubscription?.cancel();
    _smartSearchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _setupConnectivityMonitoring() async {
    try {
      final initialStatus = await _connectivity.checkConnectivity();
      if (!mounted) return;
      _handleConnectivityChange(initialStatus, showFeedback: false);

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (dynamic status) {
          _handleConnectivityChange(status, showFeedback: true);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dataNotice =
            tr(
              'تعذر التحقق من حالة الشبكة تلقائياً، لكن التطبيق سيحاول متابعة تحميل البيانات السحابية.',
              'Network status could not be verified automatically, but the app will still try to load cloud data.',
            );
      });
    }
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text;
    setState(() {
      _query = nextQuery;
      if (nextQuery.trim().isNotEmpty) {
        _selectedHomeSection = HomeCatalogSection.comparisons;
      }
    });

    _scheduleSmartSearch(nextQuery);
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _selectHomeSection(HomeCatalogSection section) {
    if (_selectedHomeSection == section) {
      return;
    }

    setState(() {
      _selectedHomeSection = section;
    });
  }

  void _scheduleSmartSearch(String rawQuery) {
    _smartSearchDebounce?.cancel();

    final normalizedQuery = _normalizeArabic(rawQuery);
    if (normalizedQuery.isEmpty || normalizedQuery.length < 2 || !_hasInternet) {
      _clearSmartSearchState();
      return;
    }

    _smartSearchDebounce = Timer(const Duration(milliseconds: 650), () {
      unawaited(_runSmartSearch(rawQuery));
    });
  }

  void _clearSmartSearchState() {
    if (_comparisonSearchResults.isEmpty &&
        _smartSearchNotice == null &&
        !_isSearchingOnline) {
      return;
    }

    if (!mounted) {
      _comparisonSearchResults = const <ComparisonSearchResult>[];
      _smartSearchNotice = null;
      _comparisonSearchSourceLabel = tr('بحث السوق', 'Market search');
      _isSearchingOnline = false;
      return;
    }

    setState(() {
      _comparisonSearchResults = const <ComparisonSearchResult>[];
      _smartSearchNotice = null;
      _comparisonSearchSourceLabel = tr('بحث السوق', 'Market search');
      _isSearchingOnline = false;
    });
  }

  Future<void> _runSmartSearch(
    String rawQuery, {
    bool forceRefresh = false,
  }) async {
    final trimmedQuery = rawQuery.trim();
    if (trimmedQuery.isEmpty || !mounted || !_hasInternet) {
      _clearSmartSearchState();
      return;
    }

    setState(() {
      _isSearchingOnline = true;
      _smartSearchNotice = null;
    });

    try {
      final result = await _comparisonSearchService.search(
        query: trimmedQuery,
        firebaseReady: widget.firebaseReady,
        forceRefresh: forceRefresh,
      );

      if (!mounted || _normalizeArabic(trimmedQuery) != _normalizeArabic(_query)) {
        return;
      }

      setState(() {
        _comparisonSearchResults = result.results;
        _smartSearchNotice = result.notice;
        _comparisonSearchSourceLabel = result.fromCache
            ? tr('كاش Firestore', 'Firestore cache')
            : tr('SerpApi مباشر', 'Live SerpApi');
      });
    } catch (error) {
      debugPrint('LeastPrice marketplace search failed: $error');
      if (!mounted || _normalizeArabic(trimmedQuery) != _normalizeArabic(_query)) {
        return;
      }

      setState(() {
        _comparisonSearchResults = const <ComparisonSearchResult>[];
        _comparisonSearchSourceLabel = tr('بحث السوق', 'Market search');
        _smartSearchNotice = tr(
          'تعذر جلب نتائج التسوق الآن. تحقق من الاتصال أو جرّب بعد قليل.',
          'Unable to fetch shopping results right now. Check the connection or try again shortly.',
        );
      });

    } finally {
      if (mounted && _normalizeArabic(trimmedQuery) == _normalizeArabic(_query)) {
        setState(() {
          _isSearchingOnline = false;
        });
      }
    }
  }

  void _handleConnectivityChange(
    dynamic rawStatus, {
    required bool showFeedback,
  }) {
    final results = _normalizeConnectivityResults(rawStatus);
    final hasInternet = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (_hasInternet == hasInternet) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _hasInternet = hasInternet;
      _dataNotice = hasInternet
          ? tr(
              'عاد الاتصال بالشبكة. يمكنك السحب للأسفل للتأكد من جلب أحدث الأسعار من Firestore.',
              'Connection is back. Pull down to make sure you get the latest prices from Firestore.',
            )
          : tr(
              'الاتصال غير متوفر حالياً. سنعرض آخر البيانات المخزنة، وعند عودة الشبكة يمكنك السحب للتحديث.',
              'Connection is currently unavailable. We will show the latest saved data, and you can pull to refresh when the network returns.',
            );
    });

    if (!showFeedback) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasInternet
              ? tr('تمت استعادة الاتصال بالشبكة.', 'Connection restored.')
              : tr('لا يوجد اتصال بالإنترنت حالياً.', 'No internet connection right now.'),
        ),
      ),
    );

    if (hasInternet) {
      unawaited(_refreshCatalog(showSuccessMessage: false));
      _scheduleSmartSearch(_query);
    } else {
      _clearSmartSearchState();
    }
  }

  List<ConnectivityResult> _normalizeConnectivityResults(dynamic rawStatus) {
    if (rawStatus is ConnectivityResult) {
      return [rawStatus];
    }

    if (rawStatus is List<ConnectivityResult>) {
      return rawStatus;
    }

    if (rawStatus is List) {
      return rawStatus.whereType<ConnectivityResult>().toList();
    }

    return const [ConnectivityResult.none];
  }

  Future<void> _refreshCatalog({bool showSuccessMessage = true}) async {
    if (!widget.firebaseReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'أكمل إعداد Firebase أولاً حتى يتمكن التطبيق من التحديث من Cloud Firestore.',
              'Complete the Firebase setup first so the app can refresh from Cloud Firestore.',
            ),
          ),
        ),
      );
      return;
    }

    if (!_hasInternet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'لا يوجد اتصال حالياً. سنعرض آخر البيانات المتاحة حتى تعود الشبكة.',
              'There is no connection right now. We will keep showing the latest available data until the network returns.',
            ),
          ),
        ),
      );
      return;
    }

    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      _dataNotice = tr(
        'يتم الآن التحقق من أحدث الأسعار والمنتجات من Cloud Firestore.',
        'Checking the latest prices and products from Cloud Firestore.',
      );
    });

    try {
      await _catalogService.refreshProductsFromServer();
      if (_query.trim().isNotEmpty) {
        await _runSmartSearch(_query, forceRefresh: true);
      }
      if (!mounted) return;

      setState(() {
        _dataNotice = tr(
          'تمت مزامنة البيانات السحابية بنجاح.',
          'Cloud data synced successfully.',
        );
      });

      if (showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تم تحديث قائمة المنتجات من الإنترنت بنجاح.',
                'Product list updated successfully from the internet.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _dataNotice =
            tr(
              'تعذر جلب آخر تحديث من Cloud Firestore حالياً. سنواصل عرض آخر نسخة متاحة لديك.',
              'Unable to fetch the latest update from Cloud Firestore right now. We will keep showing your latest available copy.',
            );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر الوصول إلى قاعدة البيانات حالياً. تحقق من الاتصال ثم أعد السحب.',
              'Unable to reach the database right now. Check your connection, then pull to refresh again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openExternalUrl(
    String url, {
    bool enforceSupportedStore = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final preparedUrl = enforceSupportedStore
          ? AffiliateLinkService.prepareForOpen(url)
          : url;
      final preparedUri = Uri.parse(preparedUrl);

      if (enforceSupportedStore &&
          !AffiliateLinkService.isSupportedStore(preparedUri)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'الرابط الحالي لا يوجّه إلى متجر سعودي مدعوم.',
                'This link does not point to a supported Saudi store.',
              ),
            ),
          ),
        );
        return;
      }

      final opened = await launchUrl(
        preparedUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تعذر فتح رابط الشراء حالياً.',
                'Unable to open the purchase link right now.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'الرابط غير صالح أو غير متاح حالياً.',
              'The link is invalid or unavailable right now.',
            ),
          ),
        ),
      );
    }
  }

  double _estimatedInviteSavingsFor(List<ProductComparison> products) {
    if (products.isEmpty) {
      return 0;
    }

    final topSavings = [...products]
      ..sort((a, b) => b.savingsAmount.compareTo(a.savingsAmount));

    return topSavings
        .take(math.min(3, topSavings.length))
        .fold<double>(0, (total, item) => total + item.savingsAmount);
  }

  Future<void> _inviteFriend(List<ProductComparison> products) async {
    final inviteLink =
        '${_userProfile.shareBaseUrl}/invite/${_userProfile.inviteCode}';
    final savedAmount = formatAmountValue(_estimatedInviteSavingsFor(products));
    final message = _userProfile.inviteMessageTemplate
        .replaceAll('{SAVED_AMOUNT}', savedAmount)
        .replaceAll('{USER_CODE}', _userProfile.inviteCode)
        .replaceAll('{APP_LINK}', inviteLink);

    await Share.share(
      message,
      subject: tr(
        'ادعُ صديقاً للتوفير مع أرخص سعر',
        'Invite a friend to save with LeastPrice',
      ),
    );
  }

  Future<void> _openBanner(AdBannerItem banner) async {
    if (banner.targetUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'لا يوجد رابط مفعل لهذا الإعلان حالياً.',
              'There is no active link for this ad right now.',
            ),
          ),
        ),
      );
      return;
    }

    await _openExternalUrl(banner.targetUrl);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _openAdminDashboard() async {
    final draft = await showDialog<AdminProductDraft>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AdminAddProductDialog(),
    );

    if (draft == null || !mounted) {
      return;
    }

    final product = draft.toProductComparison();

    try {
      await _catalogService.addProduct(product);
      if (!mounted) return;

      _clearSearch();
      setState(() {
        _selectedCategoryId = ProductCategoryCatalog.allId;
        _dataNotice = tr(
          'تمت إضافة المنتج إلى Cloud Firestore وسيظهر مباشرة لكل من يستخدم التطبيق.',
          'The product was added to Cloud Firestore and will appear immediately for app users.',
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تمت إضافة "${product.alternativeName}" بنجاح.',
              '"${product.alternativeName}" was added successfully.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر إضافة المنتج إلى Cloud Firestore. تحقق من الإعدادات أو الاتصال.',
              'Unable to add the product to Cloud Firestore. Check the setup or the connection.',
            ),
          ),
        ),
      );
    }
  }

  void _showFirebaseSetupRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'التطبيق يحتاج تهيئة Firebase وCloud Firestore أولاً قبل استخدام قاعدة البيانات.',
            'The app needs Firebase and Cloud Firestore setup before using the database.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'admin-dashboard-fab',
        tooltip: tr('لوحة المسؤول', 'Admin panel'),
        backgroundColor: AppPalette.navy,
        foregroundColor: Colors.white,
        onPressed: widget.firebaseReady
            ? _openAdminDashboard
            : _showFirebaseSetupRequired,
        child: const Icon(Icons.admin_panel_settings_rounded),
      ),
      body: StreamBuilder<List<ProductComparison>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          final products = snapshot.data ?? const <ProductComparison>[];
          final hasQuery = _query.trim().isNotEmpty;
          final showOffersSection = _selectedHomeSection == HomeCatalogSection.offers;
          final showComparisonsSection =
              _selectedHomeSection == HomeCatalogSection.comparisons;
          final comparisonResults = _comparisonSearchResults;
          final comparisonDataSourceLabel = showComparisonsSection
              ? _comparisonSearchSourceLabel
              : _dataSource.label;

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppPalette.softOrange, Colors.white],
              ),
            ),
            child: RefreshIndicator(
              color: const Color(0xFFE8711A),
              onRefresh: _refreshCatalog,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HeaderSection(
                      query: _query,
                      currentUserLabel:
                          _userProfile.phoneNumber.isNotEmpty
                              ? _userProfile.phoneNumber
                              : (widget.currentUser.email?.trim().isNotEmpty == true
                              ? widget.currentUser.email!.trim()
                                  : tr('مستخدم موثّق', 'Verified user')),
                      searchController: _searchController,
                      resultsCount:
                          showComparisonsSection ? comparisonResults.length : 0,
                      quickTags: const <String>[],
                      categories: const <ProductCategory>[],
                      selectedCategoryId: _selectedCategoryId,
                      dataSourceLabel: comparisonDataSourceLabel,
                      inviteCode: _userProfile.inviteCode,
                      invitedFriendsCount: _userProfile.invitedFriendsCount,
                      estimatedSavingsText: formatAmountValue(
                        _estimatedInviteSavingsFor(products),
                      ),
                      systemHealthLabel: _systemHealth.statusLabel,
                      searchHintText: tr(
                        'ابحث عن أي منتج: دواء، عطر، طعام، إلكترونيات...',
                        'Search any product: medicine, perfume, food, electronics...',
                      ),
                      showDiscoveryControls: false,
                      onTagTap: (_) {},
                      onCategorySelected: (_) {},
                      onInviteTap: () => _inviteFriend(products),
                      onLogoutTap: _signOut,
                      onClearSearch: _clearSearch,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _HomeSectionSwitcher(
                        selectedSection: _selectedHomeSection,
                        onSectionSelected: _selectHomeSection,
                      ),
                    ),
                  ),
                  if (!_hasInternet)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _StatusBanner(
                          icon: Icons.wifi_off_rounded,
                          title: tr('الاتصال غير متوفر', 'No connection'),
                          message: tr(
                            'سيعرض التطبيق آخر البيانات المحفوظة، وعند عودة الإنترنت يمكنك السحب للأسفل لتحديث الأسعار.',
                            'The app will show the latest saved data. Once the internet returns, pull down to refresh prices.',
                          ),
                          backgroundColor: Color(0xFFFFF8E8),
                          borderColor: Color(0xFFF2D38D),
                          accentColor: Color(0xFF9A6700),
                        ),
                      ),
                    ),
                  if (!widget.firebaseReady)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: _StatusBanner(
                          icon: Icons.cloud_off_rounded,
                          title: tr(
                            'Firebase غير مهيأ',
                            'Firebase is not configured',
                          ),
                          message: tr(
                            'أضف إعدادات Firebase وملفات Android ثم أعد تشغيل التطبيق ليبدأ جلب المنتجات من Cloud Firestore.',
                            'Add Firebase settings and Android files, then restart the app to start loading products from Cloud Firestore.',
                          ),
                          backgroundColor: Color(0xFFFFF1F0),
                          borderColor: Color(0xFFF4C7C3),
                          accentColor: Color(0xFFB44B42),
                        ),
                      ),
                    )
                  else if (snapshot.hasError && products.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: _StatusBanner(
                          icon: Icons.cloud_off_rounded,
                          title: tr(
                            'تعذر قراءة البيانات',
                            'Unable to read data',
                          ),
                          message: tr(
                            'لم نتمكن من الوصول إلى Cloud Firestore حالياً. تأكد من إعداد القاعدة والاتصال بالشبكة ثم جرّب مرة أخرى.',
                            'We could not reach Cloud Firestore right now. Check the database setup and your network, then try again.',
                          ),
                          backgroundColor: Color(0xFFFFF1F0),
                          borderColor: Color(0xFFF4C7C3),
                          accentColor: Color(0xFFB44B42),
                        ),
                      ),
                    ),
                  if (showOffersSection)
                    SliverToBoxAdapter(
                      child: _ExclusiveDealsSection(
                        stream: widget.firebaseReady
                            ? _catalogService.watchExclusiveDeals()
                            : Stream<List<ExclusiveDeal>>.value(
                                ExclusiveDeal.mockData,
                              ),
                      ),
                    ),
                  if (showOffersSection)
                    SliverToBoxAdapter(
                      child: _AdBannersSection(
                        banners: _activeBanners,
                        onBannerTap: _openBanner,
                      ),
                    ),
                  if (showComparisonsSection)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: _SectionIntroCard(
                          title: tr(
                            'محرك المقارنة الشامل',
                            'Universal comparison search',
                          ),
                          subtitle: tr(
                            'اكتب أي اسم منتج، وسنجلب أفضل نتائج التسوق من السوق السعودي مباشرة عبر SerpApi مع كاش 24 ساعة من Firestore.',
                            'Type any product name and we will fetch the best Saudi shopping results directly through SerpApi with a 24-hour Firestore cache.',
                          ),
                          backgroundColor: AppPalette.comparisonSoftEmerald,
                          borderColor: AppPalette.comparisonBorder,
                          accentColor: AppPalette.comparisonEmerald,
                          icon: Icons.travel_explore_rounded,
                        ),
                      ),
                    ),
                  if (showComparisonsSection && !hasQuery && !_isSearchingOnline)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: _ComparisonSearchPlaceholder(
                          title: tr(
                            'ابدأ بكتابة اسم المنتج',
                            'Start by typing the product name',
                          ),
                          message: tr(
                            'هذا القسم لم يعد يعرض أصنافاً ثابتة. اكتب أي منتج وسنرتب لك النتائج من الأرخص إلى الأعلى سعراً.',
                            'This section no longer shows fixed products. Type any item and we will sort the results from the cheapest to the highest price.',
                          ),
                          icon: Icons.search_rounded,
                        ),
                      ),
                    )
                  else if (showComparisonsSection &&
                      _isSearchingOnline &&
                      comparisonResults.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 32, 20, 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppPalette.comparisonEmerald,
                          ),
                        ),
                      ),
                    )
                  else if (showComparisonsSection && comparisonResults.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: _ComparisonSearchPlaceholder(
                          title: tr(
                            'لا توجد نتائج مناسبة الآن',
                            'No matching results right now',
                          ),
                          message: tr(
                            'جرّب كلمات أوضح أو اسم المنتج كما يظهر في المتجر، وسنحاول جلب النتائج مرة أخرى.',
                            'Try clearer keywords or the product name as it appears in stores, and we will fetch the results again.',
                          ),
                          icon: Icons.manage_search_rounded,
                        ),
                      ),
                    )
                  else if (showComparisonsSection)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final result = comparisonResults[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == comparisonResults.length - 1
                                    ? 0
                                    : 18,
                              ),
                              child: _ComparisonSearchResultCard(
                                result: result,
                                onTap: () => _openExternalUrl(result.productUrl),
                              ),
                            );
                          },
                          childCount: comparisonResults.length,
                        ),
                      ),
                    ),
                  if (showComparisonsSection)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasQuery
                                  ? tr(
                                      'نتائج التسوق عن "${_query.trim()}"',
                                      'Search results for "${_query.trim()}"',
                                    )
                                  : tr(
                                      'اكتب المنتج في شريط البحث بالأعلى لبدء مقارنة الأسعار فوراً.',
                                      'Type the product in the search bar above to start price comparison instantly.',
                                    ),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_dataNotice != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _dataNotice!,
                                style: const TextStyle(
                                  color: Color(0xFFE8711A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            if (_isRefreshing) ...[
                              const SizedBox(height: 6),
                              Text(
                                tr(
                                  'جارٍ تحديث نتائج السوق والتحقق من أحدث البيانات...',
                                  'Refreshing the market results and checking the latest data...',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF9A6700),
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (_isSearchingOnline) ...[
                              const SizedBox(height: 6),
                              Text(
                                tr(
                                  'جارٍ جلب نتائج التسوق الحية من SerpApi...',
                                  'Fetching live shopping results from SerpApi...',
                                ),
                                style: const TextStyle(
                                  color: AppPalette.orange,
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (_smartSearchNotice != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _smartSearchNotice!,
                                style: const TextStyle(
                                  color: AppPalette.softNavy,
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w700,
                                  height: 1.45,
                                ),
                              ),
                            ],
                            if (snapshot.hasError && products.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                tr(
                                  'حدثت مشكلة مؤقتة في مزامنة قسم المنتجات الآلي، لكن البحث الشامل سيواصل العمل بشكل مستقل.',
                                  'A temporary sync issue affected the automated products section, but universal search will keep working independently.',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFB44B42),
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF5E625F),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonSearchPlaceholder extends StatelessWidget {
  const _ComparisonSearchPlaceholder({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppPalette.comparisonBorder),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppPalette.comparisonSoftEmerald,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              icon,
              color: AppPalette.comparisonEmerald,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.softNavy,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonSearchResultCard extends StatelessWidget {
  const _ComparisonSearchResultCard({
    required this.result,
    required this.onTap,
  });

  final ComparisonSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppPalette.comparisonBorder),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: result.imageUrl.trim().isNotEmpty
                  ? Image.network(
                      result.imageUrl,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ComparisonImageFallback(),
                    )
                  : const _ComparisonImageFallback(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.comparisonSoftEmerald,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tr('محدث آلياً', 'Updated automatically'),
                      style: const TextStyle(
                        color: AppPalette.comparisonEmerald,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result.title,
                    style: const TextStyle(
                      color: AppPalette.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatPrice(result.price),
                    style: const TextStyle(
                      color: AppPalette.comparisonEmerald,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 16,
                        color: AppPalette.softNavy,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          result.storeName,
                          style: const TextStyle(
                            color: AppPalette.softNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.comparisonEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(tr('فتح المتجر', 'Open store')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonImageFallback extends StatelessWidget {
  const _ComparisonImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      color: AppPalette.cardBackground,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_search_rounded,
        color: AppPalette.softNavy,
        size: 34,
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.query,
    required this.currentUserLabel,
    required this.searchController,
    required this.resultsCount,
    required this.quickTags,
    required this.categories,
    required this.selectedCategoryId,
    required this.dataSourceLabel,
    required this.inviteCode,
    required this.invitedFriendsCount,
    required this.estimatedSavingsText,
    required this.systemHealthLabel,
    required this.searchHintText,
    required this.onTagTap,
    required this.onCategorySelected,
    required this.onInviteTap,
    required this.onLogoutTap,
    required this.onClearSearch,
    this.showDiscoveryControls = true,
  });

  final String query;
  final String currentUserLabel;
  final TextEditingController searchController;
  final int resultsCount;
  final List<String> quickTags;
  final List<ProductCategory> categories;
  final String selectedCategoryId;
  final String dataSourceLabel;
  final String inviteCode;
  final int invitedFriendsCount;
  final String estimatedSavingsText;
  final String systemHealthLabel;
  final String searchHintText;
  final ValueChanged<String> onTagTap;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onInviteTap;
  final Future<void> Function() onLogoutTap;
  final VoidCallback onClearSearch;
  final bool showDiscoveryControls;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppPalette.navy, AppPalette.deepNavy],
            ),
            boxShadow: const [
              BoxShadow(
                color: AppPalette.shadow,
                blurRadius: 28,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                top: -20,
                left: -10,
                child: _BackgroundBubble(size: 96, color: Color(0x22FFFFFF)),
              ),
              const Positioned(
                bottom: -28,
                right: -10,
                child: _BackgroundBubble(size: 130, color: Color(0x18FFFFFF)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppBrandMark(size: 60, borderRadius: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('أرخص سعر - LeastPrice', 'LeastPrice'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tr('مرحباً', 'Hello')} $currentUserLabel',
                              style: const TextStyle(
                                color: Color(0xD9FFFFFF),
                                fontSize: 13.5,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<String>(
                        valueListenable: appLang,
                        builder: (context, lang, _) => GestureDetector(
                          onTap: () {
                            appLang.value =
                                lang == 'ar' ? 'en' : 'ar';
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0x33FFFFFF)),
                            ),
                            child: Text(
                              lang == 'ar' ? 'EN' : 'AR',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: onLogoutTap,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0x1AFFFFFF),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: tr('تسجيل الخروج', 'Sign Out'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'واجهة تجارية تجمع عروض المتاجر، المقارنات اليومية، والدعوات الذكية في مكان واحد.',
                      'A business-style experience that brings offers, daily comparisons, and smart invites into one place.',
                    ),
                    style: const TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: searchHintText,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: hasQuery
                          ? IconButton(
                              onPressed: onClearSearch,
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                    ),
                  ),
                  if (showDiscoveryControls && categories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      tr('الأقسام البارزة', 'Featured categories'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category.id == selectedCategoryId;

                          return _CategoryChip(
                            category: category,
                            isSelected: isSelected,
                            onTap: () => onCategorySelected(category.id),
                          );
                        },
                      ),
                    ),
                  ],
                  if (showDiscoveryControls && quickTags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickTags
                          .map(
                            (tag) => ActionChip(
                              onPressed: () => onTagTap(tag),
                              backgroundColor: const Color(0x14FFFFFF),
                              side: const BorderSide(color: Color(0x30FFFFFF)),
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              label: Text(localizedKnownLabel(tag)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatPill(
                        icon: Icons.inventory_2_outlined,
                        label: tr(
                          '$resultsCount نتيجة',
                          '$resultsCount results',
                        ),
                      ),
                      _StatPill(
                        icon: Icons.bolt_rounded,
                        label: hasQuery
                            ? tr('بحث سوق حي', 'Live market search')
                            : tr('محرك المقارنة', 'Comparison engine'),
                      ),
                      _StatPill(
                        icon: Icons.cloud_done_rounded,
                        label: dataSourceLabel,
                      ),
                      _StatPill(
                        icon: Icons.monitor_heart_rounded,
                        label: systemHealthLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0x28FFFFFF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr(
                                  'ملف المستخدم ودعوات التوفير',
                                  'Profile and invite savings',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              tr('كودك: $inviteCode', 'Your code: $inviteCode'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                            'شارك رابط الدعوة الخاص بك ووسّع دائرة التوفير بين أصدقائك.',
                            'Share your invite link and grow the savings circle with your friends.',
                          ),
                          style: const TextStyle(
                            color: Color(0xD9FFFFFF),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _InviteMetric(
                                icon: Icons.group_add_rounded,
                                label: tr(
                                  '$invitedFriendsCount دعوة',
                                  '$invitedFriendsCount invites',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _InviteMetric(
                                icon: Icons.savings_rounded,
                                label: '$estimatedSavingsText ${tr('ر.س توفير', 'SAR saved')}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onInviteTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0x55FFFFFF)),
                              backgroundColor: const Color(0x10FFFFFF),
                            ),
                            icon: const Icon(Icons.share_rounded),
                            label: Text(
                              tr(
                                'ادعُ صديقاً للتوفير',
                                'Invite a friend to save',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ProductCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 88,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : category.color.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : category.color.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                category.icon,
                size: 20,
                color: isSelected ? category.color : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizedCategoryLabelForId(
                category.id,
                fallbackLabel: category.label,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? const Color(0xFFE8711A) : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({
    required this.banners,
    required this.onTap,
  });

  final List<AdBannerItem> banners;
  final ValueChanged<AdBannerItem> onTap;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant _BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _autoPlayTimer?.cancel();
      _currentIndex = 0;
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    if (widget.banners.length <= 1) {
      return;
    }

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final nextIndex = (_currentIndex + 1) % widget.banners.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 186,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: InkWell(
                  onTap: () => widget.onTap(banner),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 16,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                color: AppPalette.softOrange,
                              );
                            },
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xE61B2F5E), Color(0x66264A88)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  banner.storeName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                banner.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xE8FFFFFF),
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            final isActive = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isActive ? 22 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AdBannersSection extends StatelessWidget {
  const _AdBannersSection({
    required this.banners,
    required this.onBannerTap,
  });

  final List<AdBannerItem> banners;
  final ValueChanged<AdBannerItem> onBannerTap;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: _BannerCarousel(
        banners: banners,
        onTap: onBannerTap,
      ),
    );
  }
}

class _ExclusiveDealsCarousel extends StatefulWidget {
  const _ExclusiveDealsCarousel({
    required this.deals,
    required this.now,
  });

  final List<ExclusiveDeal> deals;
  final DateTime now;

  @override
  State<_ExclusiveDealsCarousel> createState() => _ExclusiveDealsCarouselState();
}

class _ExclusiveDealsCarouselState extends State<_ExclusiveDealsCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant _ExclusiveDealsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deals.length != widget.deals.length) {
      _autoPlayTimer?.cancel();
      _currentIndex = 0;
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    if (widget.deals.length <= 1) {
      return;
    }

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final nextIndex = (_currentIndex + 1) % widget.deals.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 236,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.deals.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final deal = widget.deals[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: _ExclusiveDealCard(
                  deal: deal,
                  now: widget.now,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.deals.length, (index) {
            final isActive = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isActive ? 22 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isActive ? AppPalette.dealsRed : AppPalette.dealsBorder,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ExclusiveDealCard extends StatelessWidget {
  const _ExclusiveDealCard({
    required this.deal,
    required this.now,
  });

  final ExclusiveDeal deal;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final remaining = deal.expiryDate.difference(now);
    final remainingLabel = remaining.inHours >= 24
        ? tr(
            'ينتهي خلال ${remaining.inDays + 1} يوم',
            'Ends in ${remaining.inDays + 1} day(s)',
          )
        : tr(
            'ينتهي خلال ${remaining.inHours.clamp(0, 23)} ساعة',
            'Ends in ${remaining.inHours.clamp(0, 23)} hour(s)',
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFF4ED), Color(0xFFFFE7E1)],
        ),
        border: Border.all(color: AppPalette.dealsBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18D94B45),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                deal.imageUrl,
                width: 122,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 122,
                    color: AppPalette.softOrange,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: AppPalette.dealsRed,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      tr('عرض مؤقت', 'Limited deal'),
                      style: const TextStyle(
                        color: AppPalette.dealsRed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    deal.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1B2F5E),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        formatPrice(deal.afterPrice),
                        style: const TextStyle(
                          color: AppPalette.dealsRed,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatPrice(deal.beforePrice),
                        style: const TextStyle(
                          color: AppPalette.softNavy,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'وفرت ${deal.savingsPercent}% • $remainingLabel',
                      'Saved ${deal.savingsPercent}% • $remainingLabel',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF8A3E2F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComparisonCard extends StatelessWidget {
  const ComparisonCard({
    super.key,
    required this.comparison,
    required this.onBuyTap,
    required this.onShareTap,
    required this.onRateTap,
    this.onLocationTap,
  });

  final ProductComparison comparison;
  final VoidCallback? onBuyTap;
  final VoidCallback onShareTap;
  final VoidCallback onRateTap;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110C3B2E),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.comparisonSoftEmerald,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    localizedCategoryLabelForId(
                      comparison.categoryId,
                      fallbackLabel: comparison.categoryLabel,
                    ),
                    style: const TextStyle(
                      color: AppPalette.comparisonEmerald,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (comparison.isAutomated) ...[
                  const SizedBox(width: 8),
                  const _AutomatedComparisonBadge(),
                ],
                if (comparison.isSuperSaving) ...[
                  const SizedBox(width: 8),
                  const _SuperSavingBadge(),
                ],
                if (comparison.hasOriginalOfferTag) ...[
                  const SizedBox(width: 8),
                  const _OriginalOnSaleBadge(),
                ],
                const Spacer(),
                _SavingBadge(savingsPercent: comparison.savingsPercent),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;

                if (isCompact) {
                  return Column(
                    children: [
                      ProductPane(
                        label: tr('الخيار الأعلى سعراً', 'Higher-priced option'),
                        name: comparison.expensiveName,
                        price: comparison.expensivePrice,
                        imageUrl: comparison.expensiveImageUrl,
                        highlighted: false,
                        icon: Icons.trending_up_rounded,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Icon(
                          Icons.compare_arrows_rounded,
                          color: Color(0xFFE8711A),
                          size: 28,
                        ),
                      ),
                      ProductPane(
                        label: tr('الخيار الأفضل قيمة', 'Best value option'),
                        name: comparison.alternativeName,
                        price: comparison.alternativePrice,
                        imageUrl: comparison.alternativeImageUrl,
                        highlighted: true,
                        icon: Icons.check_circle_rounded,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: ProductPane(
                        label: tr('الخيار الأعلى سعراً', 'Higher-priced option'),
                        name: comparison.expensiveName,
                        price: comparison.expensivePrice,
                        imageUrl: comparison.expensiveImageUrl,
                        highlighted: false,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        color: Color(0xFFE8711A),
                        size: 30,
                      ),
                    ),
                    Expanded(
                      child: ProductPane(
                        label: tr('الخيار الأفضل قيمة', 'Best value option'),
                        name: comparison.alternativeName,
                        price: comparison.alternativePrice,
                        imageUrl: comparison.alternativeImageUrl,
                        highlighted: true,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFFE8711A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      comparison.hasOriginalOfferTag
                          ? tr(
                              'المنتج الأصلي أصبح الأرخص حالياً، لذلك ننصح بمراجعة العرض قبل الشراء.',
                              'The original product is currently cheaper, so we recommend checking this offer before buying.',
                            )
                          : tr(
                              'فرق السعر: ${formatPrice(comparison.savingsAmount)} لصالح الخيار الأفضل قيمة.',
                              'Price difference: ${formatPrice(comparison.savingsAmount)} in favor of the best value option.',
                            ),
                      style: const TextStyle(
                        color: Color(0xFF224238),
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (comparison.isAutomated) ...[
                    const SizedBox(width: 10),
                    const _AutomatedComparisonBadge(compact: true),
                  ],
                ],
              ),
            ),
            if (comparison.hasDetailHighlights || comparison.hasLocationLink) ...[
              const SizedBox(height: 14),
              _ComparisonInsights(
                comparison: comparison,
                onLocationTap: onLocationTap,
              ),
            ],
            const SizedBox(height: 14),
            _RatingSummary(
              comparison: comparison,
              onTap: onRateTap,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 430;

                if (isNarrow) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onShareTap,
                          icon: const Icon(Icons.share_rounded),
                          label: Text(tr('مشاركة التوفير', 'Share savings')),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onBuyTap,
                          icon: const Icon(Icons.shopping_cart_checkout_rounded),
                          label: Text(
                            comparison.hasBuyUrl
                                ? tr('فتح رابط الشراء', 'Open buy link')
                                : tr('بدون رابط شراء', 'No buy link'),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShareTap,
                        icon: const Icon(Icons.share_rounded),
                        label: Text(tr('مشاركة التوفير', 'Share savings')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onBuyTap,
                        icon: const Icon(Icons.shopping_cart_checkout_rounded),
                        label: Text(
                          comparison.hasBuyUrl
                              ? tr('فتح رابط الشراء', 'Open buy link')
                              : tr('بدون رابط شراء', 'No buy link'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProductPane extends StatelessWidget {
  const ProductPane({
    super.key,
    required this.label,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.highlighted,
    required this.icon,
  });

  final String label;
  final String name;
  final double price;
  final String imageUrl;
  final bool highlighted;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accentColor = highlighted
        ? const Color(0xFFE8711A)
        : const Color(0xFFB54D4D);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF2FBF7) : const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFB5E4D4)
              : const Color(0xFFE2EBE7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.35,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFFFF0E6)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        size: 34,
                        color: Color(0xFF7E9A8F),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF17332B),
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatPrice(price),
            style: TextStyle(
              color: highlighted
                  ? const Color(0xFF0B7A5E)
                  : const Color(0xFF394A44),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({
    required this.comparison,
    required this.onTap,
  });

  final ProductComparison comparison;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reviewText = comparison.reviewCount > 0
        ? tr(
            '${comparison.rating.toStringAsFixed(1)} ⭐ - ${comparison.reviewCount} تقييم',
            '${comparison.rating.toStringAsFixed(1)} ⭐ - ${comparison.reviewCount} reviews',
          )
        : tr('ابدأ أول تقييم لهذا الخيار', 'Be the first to rate this option');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF4D37B)),
        ),
        child: Row(
          children: [
            _RatingStars(rating: comparison.rating),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reviewText,
                    style: const TextStyle(
                      color: Color(0xFF7A5A00),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'اضغط على النجوم لتقييم الجودة والقيمة مقارنة بالخيار الأعلى سعراً.',
                      'Tap the stars to rate quality and value compared to the higher-priced option.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF8B7331),
                      fontSize: 12.8,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFB79020),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({
    required this.rating,
  });

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        IconData icon;

        if (rating >= starNumber) {
          icon = Icons.star_rounded;
        } else if (rating >= starNumber - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }

        return Icon(
          icon,
          color: const Color(0xFFF5B400),
          size: 20,
        );
      }),
    );
  }
}

class _ComparisonInsights extends StatelessWidget {
  const _ComparisonInsights({
    required this.comparison,
    required this.onLocationTap,
  });

  final ProductComparison comparison;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comparison.fragranceNotes != null &&
              comparison.fragranceNotes!.trim().isNotEmpty)
            _InsightRow(
              icon: Icons.spa_rounded,
              title: tr('نوتة العطر', 'Fragrance notes'),
              value: comparison.fragranceNotes!,
            ),
          if (comparison.activeIngredients != null &&
              comparison.activeIngredients!.trim().isNotEmpty)
            _InsightRow(
              icon: Icons.science_rounded,
              title: tr('المادة الفعالة', 'Active ingredient'),
              value: comparison.activeIngredients!,
            ),
          if (comparison.localLocationLabel != null &&
              comparison.localLocationLabel!.trim().isNotEmpty)
            _InsightRow(
              icon: Icons.place_rounded,
              title: tr('موقع المتجر', 'Store location'),
              value: comparison.localLocationLabel!,
              actionLabel: comparison.localLocationUrl == null
                  ? null
                  : tr('رابط الموقع', 'Open location'),
              onActionTap: onLocationTap,
            ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.title,
    required this.value,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFE8711A), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF224238),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF5E756D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton.icon(
              onPressed: onActionTap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _SavingBadge extends StatelessWidget {
  const _SavingBadge({required this.savingsPercent});

  final int savingsPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.comparisonEmerald, Color(0xFF16AA83)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tr('وفرت $savingsPercent%', 'Saved $savingsPercent%'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SuperSavingBadge extends StatelessWidget {
  const _SuperSavingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0C56B)),
      ),
      child: Text(
        tr('توفير خارق', 'Super saving'),
        style: const TextStyle(
          color: Color(0xFF9A6700),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OriginalOnSaleBadge extends StatelessWidget {
  const _OriginalOnSaleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA6D0F2)),
      ),
      child: Text(
        tr(
          'المنتج الأصلي عليه عرض حالياً',
          'Original product is on sale now',
        ),
        style: const TextStyle(
          color: Color(0xFF185A8B),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InviteMetric extends StatelessWidget {
  const _InviteMetric({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundBubble extends StatelessWidget {
  const _BackgroundBubble({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ignore: unused_element
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.query,
    required this.selectedCategoryLabel,
    required this.hasCategoryFilter,
    required this.onReset,
  });

  final String query;
  final String selectedCategoryLabel;
  final bool hasCategoryFilter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    final hasQueuedSearchDemand = DateTime.now().microsecondsSinceEpoch < 0;

    final title = hasQuery
        ? hasQueuedSearchDemand
            ? tr(
                'تم تسجيل طلب البحث عن "${query.trim()}".',
                'Your search request for "${query.trim()}" was recorded.',
              )
            : tr(
                'نحضّر لك نتائج أدق عن "${query.trim()}".',
                'We are preparing more accurate results for "${query.trim()}".',
              )
        : hasCategoryFilter
            ? tr(
                'لا توجد منتجات حالياً ضمن تصنيف "$selectedCategoryLabel".',
                'There are currently no products in the "$selectedCategoryLabel" category.',
              )
            : tr(
                'لا توجد منتجات متاحة حالياً.',
                'No products are currently available.',
              );

    final description = hasQuery
        ? hasQueuedSearchDemand
            ? tr(
                'Ø¬Ø§Ø±Ù ØªØ¬Ù‡ÙŠØ² Ù†ØªØ§Ø¦Ø¬ Ø£Ø¯Ù‚ Ù„Ùƒ.',
                'We are preparing more accurate results for you.',
              )
            : hasCategoryFilter
                ? tr(
                    'قد يكون المنتج موجوداً في تصنيف آخر، ويمكنك إعادة ضبط الفلاتر الآن. وإذا كان غير موجود بعد، فسنسجل طلبه ليضيفه روبوت التحديث اليومي لاحقاً.',
                    'The product may exist under another category, and you can reset filters now. If it is still missing, your request will be logged for the daily bot to add later.',
                  )
                : tr(
                    'إذا لم يكن هذا المنتج موجوداً بعد في القاعدة أو في نتائج الويب اللحظية، فسيتم تسجيل طلبك لإضافته تلقائياً في الجولة القادمة.',
                    'If this product is not yet available in the database or live web results, your request will be recorded to add it automatically in the next round.',
                  )
        : tr(
            'يمكنك تغيير التصنيف أو البحث عن اسم المنتج أو الخيار المقارن أو حتى المكوّنات لإظهار النتائج المناسبة.',
            'You can change the category or search by product name, compared option, or even ingredients to find the right results.',
          );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110C3B2E),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Color(0xFFE8711A),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18352C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667C74),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(tr('إعادة ضبط الفلاتر', 'Reset filters')),
          ),
        ],
      ),
    );
  }
}

class _AdminBannersTable extends StatefulWidget {
  const _AdminBannersTable({
    required this.catalogService,
  });

  final FirestoreCatalogService catalogService;

  @override
  State<_AdminBannersTable> createState() => _AdminBannersTableState();
}

class _AdminBannersTableState extends State<_AdminBannersTable> {
  Future<void> _openEditor({AdBannerItem? initialBanner}) async {
    final banner = await showDialog<AdBannerItem>(
      context: context,
      builder: (context) => _AdminBannerEditorDialog(initialBanner: initialBanner),
    );

    if (banner == null || !mounted) {
      return;
    }

    try {
      await widget.catalogService.saveAdBanner(banner);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initialBanner == null
                ? 'تمت إضافة البنر بنجاح.'
                : 'تم تحديث البنر بنجاح.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تعذر حفظ البنر حالياً: $error', 'Unable to save the banner right now: $error'))),
      );
    }
  }

  Future<void> _publishBanner(AdBannerItem banner) async {
    try {
      await widget.catalogService.publishAdBanner(banner.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم تحديث lastUpdated للبنر بنجاح.', 'Banner lastUpdated was refreshed successfully.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تعذر نشر البنر حالياً: $error', 'Unable to publish the banner right now: $error'))),
      );
    }
  }

  Future<void> _deleteBanner(AdBannerItem banner) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('حذف البنر', 'Delete banner')),
        content: Text(tr('هل تريد حذف البنر "${banner.title}" نهائياً؟', 'Do you want to permanently delete the banner "${banner.title}"?')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(tr('حذف', 'Delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await widget.catalogService.deleteAdBanner(banner.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم حذف البنر.', 'Banner deleted.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تعذر حذف البنر حالياً: $error', 'Unable to delete the banner right now: $error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return LayoutBuilder(
        builder: (context, constraints) {
          final fallbackHeight = math.max(
            520.0,
            MediaQuery.sizeOf(context).height - 220,
          );
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : fallbackHeight;
          final sectionHeight = math.max(520.0, availableHeight - 64);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('إدارة البنرات الإعلانية', 'Banner management'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2F5E),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      tr(
                        'أضف أو عدّل أو احذف البنرات في مجموعة ad_banners، ثم استخدم زر النشر لتحديث lastUpdated.',
                        'Add, edit, or delete banners in the ad_banners collection, then use Publish to refresh lastUpdated.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF667C74),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: Text(tr('إضافة بنر', 'Add banner')),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: sectionHeight,
            child: _AdminDashboardSectionCard(
              child: StreamBuilder<List<AdBannerItem>>(
                stream: widget.catalogService.watchAdminAdBanners(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          tr(
                            'تعذر تحميل البنرات من Firestore: ${snapshot.error}',
                            'Unable to load banners from Firestore: ${snapshot.error}',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6B7A9A)),
                        ),
                      ),
                    );
                  }

                  final banners = snapshot.data ?? const <AdBannerItem>[];
                  if (banners.isEmpty) {
                    return Center(
                      child: Text(
                        tr(
                          'لا توجد بنرات بعد. أضف أول بنر من الزر العلوي.',
                          'No banners yet. Add the first banner from the top button.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF6B7A9A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 18,
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF2FBF7),
                        ),
                        columns: [
                          DataColumn(label: Text(tr('المتجر', 'Store'))),
                          DataColumn(label: Text(tr('العنوان', 'Title'))),
                          DataColumn(label: Text(tr('الترتيب', 'Order'))),
                          DataColumn(label: Text(tr('الحالة', 'Status'))),
                          DataColumn(label: Text(tr('الصورة', 'Image'))),
                          DataColumn(label: Text(tr('الإجراءات', 'Actions'))),
                        ],
                        rows: banners.map((banner) {
                          return DataRow(
                            cells: [
                              DataCell(Text(banner.storeName)),
                              DataCell(
                                SizedBox(
                                  width: 240,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        banner.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (banner.subtitle.trim().isNotEmpty)
                                        Text(
                                          banner.subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF667C74),
                                            fontSize: 12.5,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(Text(banner.order.toString())),
                              DataCell(
                                _AdminStatusChip(
                                  label: banner.active
                                      ? tr('نشط', 'Active')
                                      : tr('مخفي', 'Hidden'),
                                  color: banner.active
                                      ? const Color(0xFFE8711A)
                                      : const Color(0xFF9A6B6B),
                                ),
                              ),
                              DataCell(
                                _AdminNetworkThumbnail(
                                  imageUrl: banner.imageUrl,
                                  label: banner.title,
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 250,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () =>
                                            _openEditor(initialBanner: banner),
                                        child: Text(tr('تعديل', 'Edit')),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _publishBanner(banner),
                                        child: Text(tr('نشر', 'Publish')),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _deleteBanner(banner),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFC24E4E),
                                        ),
                                        child: Text(tr('حذف', 'Delete')),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
            ),
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Admin banners table build failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return _AdminBuildFailurePanel(message: error.toString());
    }
  }
}

class _AdminProductsTable extends StatefulWidget {
  const _AdminProductsTable({
    required this.catalogService,
  });

  final FirestoreCatalogService catalogService;

  @override
  State<_AdminProductsTable> createState() => _AdminProductsTableState();
}

class _AdminProductsTableState extends State<_AdminProductsTable> {
  Future<void> _openEditor({ProductComparison? initialProduct}) async {
    final product = await showDialog<ProductComparison>(
      context: context,
      builder: (context) =>
          _AdminProductEditorDialog(initialProduct: initialProduct),
    );

    if (product == null || !mounted) {
      return;
    }

    try {
      await widget.catalogService.saveProduct(product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initialProduct == null
                ? 'تمت إضافة المنتج بنجاح.'
                : 'تم تحديث المنتج بنجاح.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تعذر حفظ المنتج حالياً: $error', 'Unable to save the product right now: $error'))),
      );
    }
  }

  Future<void> _publishProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('احفظ المنتج أولاً قبل نشره.', 'Save the product first before publishing it.'))),
      );
      return;
    }

    try {
      await widget.catalogService.publishProduct(documentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم تحديث lastUpdated للمنتج بنجاح.', 'Product lastUpdated was refreshed successfully.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تعذر نشر المنتج حالياً: $error', 'Unable to publish the product right now: $error'))),
      );
    }
  }

  Future<void> _deleteProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('هذا المنتج غير مرتبط بوثيقة Firestore.', 'This product is not linked to a Firestore document.'))),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('حذف المنتج', 'Delete product')),
            content: Text(
              'هل تريد حذف "${product.expensiveName}" و"${product.alternativeName}" نهائياً؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(tr('حذف', 'Delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await widget.catalogService.deleteProduct(documentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تم حذف المنتج.', 'Product deleted.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('تعذر حذف المنتج حالياً: $error', 'Unable to delete the product right now: $error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return LayoutBuilder(
        builder: (context, constraints) {
          final fallbackHeight = math.max(
            520.0,
            MediaQuery.sizeOf(context).height - 220,
          );
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : fallbackHeight;
          final sectionHeight = math.max(520.0, availableHeight - 64);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('إدارة المنتجات', 'Product management'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2F5E),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      tr(
                        'هذه هي بطاقات المقارنة المستمرة من مجموعة products. يتم وسمها كبيانات آلية مع تحديث lastUpdated عند النشر.',
                        'These are the ongoing comparison cards from the products collection. They are tagged as automated data and refresh lastUpdated when published.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF667C74),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: Text(tr('إضافة منتج', 'Add product')),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: sectionHeight,
            child: _AdminDashboardSectionCard(
              child: StreamBuilder<List<ProductComparison>>(
                stream: widget.catalogService.watchAllProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          tr(
                            'تعذر تحميل المنتجات من Firestore: ${snapshot.error}',
                            'Unable to load products from Firestore: ${snapshot.error}',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6B7A9A)),
                        ),
                      ),
                    );
                  }

                  final products = snapshot.data ?? const <ProductComparison>[];
                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        tr(
                          'لا توجد منتجات بعد. أضف أول منتج من الزر العلوي.',
                          'No products yet. Add the first product from the top button.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF6B7A9A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 18,
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF2FBF7),
                        ),
                        columns: [
                          DataColumn(label: Text(tr('القسم', 'Category'))),
                          DataColumn(label: Text(tr('النوع', 'Type'))),
                          DataColumn(
                            label: Text(tr('المنتج المرجعي', 'Reference product')),
                          ),
                          DataColumn(label: Text(tr('سعره', 'Price'))),
                          DataColumn(
                            label: Text(tr('الخيار المقارن', 'Compared option')),
                          ),
                          DataColumn(label: Text(tr('سعره', 'Price'))),
                          DataColumn(label: Text(tr('الصور', 'Images'))),
                          DataColumn(label: Text(tr('الرابط', 'Link'))),
                          DataColumn(label: Text(tr('الإجراءات', 'Actions'))),
                        ],
                        rows: products.map((product) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  localizedCategoryLabelForId(
                                    product.categoryId,
                                    fallbackLabel: product.categoryLabel,
                                  ),
                                ),
                              ),
                              DataCell(
                                _AdminStatusChip(
                                  label: product.isAutomated
                                      ? tr('آلي', 'Automated')
                                      : tr('يدوي', 'Manual'),
                                  color: product.isAutomated
                                      ? AppPalette.comparisonEmerald
                                      : AppPalette.orange,
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    product.expensiveName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(formatAmountValue(product.expensivePrice))),
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    product.alternativeName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(formatAmountValue(product.alternativePrice)),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _AdminNetworkThumbnail(
                                      imageUrl: product.expensiveImageUrl,
                                      label: product.expensiveName,
                                    ),
                                    const SizedBox(width: 8),
                                    _AdminNetworkThumbnail(
                                      imageUrl: product.alternativeImageUrl,
                                      label: product.alternativeName,
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    product.buyUrl.trim().isEmpty
                                        ? tr('بدون رابط', 'No link')
                                        : product.buyUrl,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 270,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () =>
                                            _openEditor(initialProduct: product),
                                        child: Text(tr('تعديل', 'Edit')),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _publishProduct(product),
                                        child: Text(tr('نشر', 'Publish')),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _deleteProduct(product),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFC24E4E),
                                        ),
                                        child: Text(tr('حذف', 'Delete')),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
            ),
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Admin products table build failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return _AdminBuildFailurePanel(message: error.toString());
    }
  }
}

class _AutomatedComparisonBadge extends StatelessWidget {
  const _AutomatedComparisonBadge({
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: AppPalette.comparisonSoftEmerald,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.comparisonBorder),
      ),
      child: Text(
        tr('محدث آلياً', 'Auto-updated'),
        style: const TextStyle(
          color: AppPalette.comparisonEmerald,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionIntroCard extends StatelessWidget {
  const _SectionIntroCard({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF5E625F),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSectionSwitcher extends StatelessWidget {
  const _HomeSectionSwitcher({
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final HomeCatalogSection selectedSection;
  final ValueChanged<HomeCatalogSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _HomeSectionSwitcherButton(
              label: tr('العروض', 'Offers'),
              icon: Icons.local_offer_rounded,
              isSelected: selectedSection == HomeCatalogSection.offers,
              activeColor: AppPalette.dealsRed,
              activeBackground: AppPalette.dealsSoftRed,
              onTap: () => onSectionSelected(HomeCatalogSection.offers),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HomeSectionSwitcherButton(
              label: tr('المقارنة', 'Comparison'),
              icon: Icons.compare_arrows_rounded,
              isSelected: selectedSection == HomeCatalogSection.comparisons,
              activeColor: AppPalette.comparisonEmerald,
              activeBackground: AppPalette.comparisonSoftEmerald,
              onTap: () => onSectionSelected(HomeCatalogSection.comparisons),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSectionSwitcherButton extends StatelessWidget {
  const _HomeSectionSwitcherButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.activeBackground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color activeBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : AppPalette.softNavy,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : AppPalette.navy,
                fontWeight: FontWeight.w900,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExclusiveDealsSection extends StatefulWidget {
  const _ExclusiveDealsSection({
    required this.stream,
  });

  final Stream<List<ExclusiveDeal>> stream;

  @override
  State<_ExclusiveDealsSection> createState() => _ExclusiveDealsSectionState();
}

class _ExclusiveDealsSectionState extends State<_ExclusiveDealsSection> {
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: StreamBuilder<List<ExclusiveDeal>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
            return const SizedBox.shrink();
          }

          final activeDeals = (snapshot.data ?? const <ExclusiveDeal>[])
              .where((deal) => !deal.isExpiredAt(_now))
              .toList()
            ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

          if (activeDeals.isEmpty) {
            return const SizedBox.shrink();
          }

          return _ExclusiveDealsCarousel(deals: activeDeals, now: _now);
        },
      ),
    );
  }
}

class _AdminExclusiveDealsTable extends StatefulWidget {
  const _AdminExclusiveDealsTable({
    required this.catalogService,
  });

  final FirestoreCatalogService catalogService;

  @override
  State<_AdminExclusiveDealsTable> createState() =>
      _AdminExclusiveDealsTableState();
}

class _AdminExclusiveDealsTableState extends State<_AdminExclusiveDealsTable> {
  Future<void> _openEditor({ExclusiveDeal? initialDeal}) async {
    final deal = await showDialog<ExclusiveDeal>(
      context: context,
      builder: (context) =>
          _AdminExclusiveDealEditorDialog(initialDeal: initialDeal),
    );

    if (deal == null || !mounted) {
      return;
    }

    try {
      await widget.catalogService.saveExclusiveDeal(deal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initialDeal == null
                ? tr('تمت إضافة العرض بنجاح.', 'Deal added successfully.')
                : tr('تم تحديث العرض بنجاح.', 'Deal updated successfully.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حفظ العرض حالياً: $error',
              'Unable to save the deal right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _publishDeal(ExclusiveDeal deal) async {
    if (deal.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'احفظ العرض أولاً قبل نشره.',
              'Save the deal first before publishing it.',
            ),
          ),
        ),
      );
      return;
    }

    try {
      await widget.catalogService.publishExclusiveDeal(deal.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تم نشر العرض وتحديث lastUpdated.',
              'The deal was published and lastUpdated was refreshed.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر نشر العرض حالياً: $error',
              'Unable to publish the deal right now: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteDeal(ExclusiveDeal deal) async {
    if (deal.id.trim().isEmpty) {
      return;
    }

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('حذف العرض', 'Delete deal')),
            content: Text(
              tr(
                'هل تريد حذف "${deal.title}" نهائياً؟',
                'Do you want to permanently delete "${deal.title}"?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(tr('حذف', 'Delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await widget.catalogService.deleteExclusiveDeal(deal.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('تم حذف العرض.', 'Deal deleted.'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر حذف العرض حالياً: $error',
              'Unable to delete the deal right now: $error',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackHeight = math.max(
      520.0,
      MediaQuery.sizeOf(context).height - 220,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('إدارة العروض الحصرية', 'Exclusive deals management'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2F5E),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      tr(
                        'أضف عروض exclusive_deals يدوياً مع السعر قبل وبعد وتاريخ الانتهاء، ثم استخدم زر النشر لتحديث lastUpdated فوراً.',
                        'Add exclusive_deals manually with before and after prices plus the expiry date, then use Publish to refresh lastUpdated immediately.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF667C74),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: Text(tr('إضافة عرض', 'Add deal')),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: fallbackHeight,
            child: _AdminDashboardSectionCard(
              child: StreamBuilder<List<ExclusiveDeal>>(
                stream: widget.catalogService.watchAdminExclusiveDeals(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          tr(
                            'تعذر تحميل العروض من Firestore: ${snapshot.error}',
                            'Unable to load deals from Firestore: ${snapshot.error}',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6B7A9A)),
                        ),
                      ),
                    );
                  }

                  final deals = snapshot.data ?? const <ExclusiveDeal>[];
                  if (deals.isEmpty) {
                    return Center(
                      child: Text(
                        tr(
                          'لا توجد عروض حصرية بعد. أضف أول عرض من الزر العلوي.',
                          'No exclusive deals yet. Add the first deal from the top button.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF6B7A9A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  final now = DateTime.now();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 18,
                        headingRowColor: WidgetStateProperty.all(
                          AppPalette.dealsSoftRed,
                        ),
                        columns: [
                          DataColumn(label: Text(tr('العنوان', 'Title'))),
                          DataColumn(label: Text(tr('السعر قبل', 'Before price'))),
                          DataColumn(label: Text(tr('السعر بعد', 'After price'))),
                          DataColumn(label: Text(tr('التوفير', 'Savings'))),
                          DataColumn(label: Text(tr('الانتهاء', 'Expiry'))),
                          DataColumn(label: Text(tr('الحالة', 'Status'))),
                          DataColumn(label: Text(tr('الصورة', 'Image'))),
                          DataColumn(label: Text(tr('الإجراءات', 'Actions'))),
                        ],
                        rows: deals.map((deal) {
                          final isExpired = deal.isExpiredAt(now);
                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 240,
                                  child: Text(
                                    deal.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(formatAmountValue(deal.beforePrice))),
                              DataCell(Text(formatAmountValue(deal.afterPrice))),
                              DataCell(
                                Text(
                                  '${formatAmountValue(deal.savingsAmount)} • ${deal.savingsPercent}%',
                                ),
                              ),
                              DataCell(Text(_formatDealExpiryLabel(deal.expiryDate))),
                              DataCell(
                                _AdminStatusChip(
                                  label: isExpired
                                      ? tr('منتهي', 'Expired')
                                      : tr('ساري', 'Active'),
                                  color: isExpired
                                      ? AppPalette.dealsRed
                                      : AppPalette.orange,
                                ),
                              ),
                              DataCell(
                                _AdminNetworkThumbnail(
                                  imageUrl: deal.imageUrl,
                                  label: deal.title,
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 270,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _openEditor(initialDeal: deal),
                                        child: Text(tr('تعديل', 'Edit')),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _publishDeal(deal),
                                        child: Text(tr('نشر', 'Publish')),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _deleteDeal(deal),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFC24E4E),
                                        ),
                                        child: Text(tr('حذف', 'Delete')),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBuildFailurePanel extends StatelessWidget {
  const _AdminBuildFailurePanel({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _AdminDashboardSectionCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFD14B4B),
                  size: 34,
                ),
                const SizedBox(height: 14),
                Text(
                  tr(
                    'تعذر بناء واجهة الإدارة',
                    'Unable to build the admin interface',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF17332B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7A9A),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminStatusChip extends StatelessWidget {
  const _AdminStatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AdminNetworkThumbnail extends StatelessWidget {
  const _AdminNetworkThumbnail({
    required this.imageUrl,
    required this.label,
  });

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF2FBF7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_not_supported_rounded),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 52,
            height: 52,
            color: const Color(0xFFF2FBF7),
            alignment: Alignment.center,
            child: Text(
              label.trim().isNotEmpty ? label.trim()[0] : '?',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          );
        },
      ),
    );
  }
}

class _AdminBannerEditorDialog extends StatefulWidget {
  const _AdminBannerEditorDialog({
    this.initialBanner,
  });

  final AdBannerItem? initialBanner;

  @override
  State<_AdminBannerEditorDialog> createState() => _AdminBannerEditorDialogState();
}

class _AdminBannerEditorDialogState extends State<_AdminBannerEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _storeNameController;
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _targetUrlController;
  late final TextEditingController _orderController;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final banner = widget.initialBanner;
    _storeNameController = TextEditingController(text: banner?.storeName ?? '');
    _titleController = TextEditingController(text: banner?.title ?? '');
    _subtitleController = TextEditingController(text: banner?.subtitle ?? '');
    _imageUrlController = TextEditingController(text: banner?.imageUrl ?? '');
    _targetUrlController = TextEditingController(text: banner?.targetUrl ?? '');
    _orderController = TextEditingController(
      text: banner?.order.toString() ?? '1',
    );
    _active = banner?.active ?? true;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _imageUrlController.dispose();
    _targetUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return requiredFieldMessage(label, label);
    }
    return null;
  }

  String? _validateUrl(String? value, {bool required = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return required
          ? tr('هذا الرابط مطلوب.', 'This URL is required.')
          : null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return validUrlMessage('رابطاً', 'URL');
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      AdBannerItem(
        id: widget.initialBanner?.id ?? '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        targetUrl: _targetUrlController.text.trim(),
        storeName: _storeNameController.text.trim(),
        active: _active,
        order: int.tryParse(_orderController.text.trim()) ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.initialBanner == null
                        ? tr('إضافة بنر جديد', 'Add new banner')
                        : tr('تعديل البنر', 'Edit banner'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _storeNameController,
                    decoration: InputDecoration(
                      labelText: tr('اسم المتجر', 'Store name'),
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                    validator: (value) =>
                        _validateRequired(value, tr('اسم المتجر', 'Store name')),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: tr('عنوان البنر', 'Banner title'),
                      prefixIcon: Icon(Icons.campaign_rounded),
                    ),
                    validator: (value) => _validateRequired(
                      value,
                      tr('عنوان البنر', 'Banner title'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _subtitleController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: tr('الوصف المختصر', 'Short description'),
                      prefixIcon: Icon(Icons.subject_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _imageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: tr('رابط الصورة', 'Image URL'),
                      prefixIcon: Icon(Icons.image_rounded),
                    ),
                    validator: (value) => _validateUrl(value, required: true),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _targetUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: tr('رابط الوجهة', 'Target URL'),
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _orderController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr('الترتيب', 'Order'),
                      prefixIcon: Icon(Icons.format_list_numbered_rounded),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 0) {
                        return tr(
                          'أدخل رقماً صحيحاً للترتيب.',
                          'Enter a valid number for the order.',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _active,
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('البنر نشط', 'Banner is active')),
                    subtitle: Text(
                      tr(
                        'البنرات غير النشطة لن تظهر للمستخدمين.',
                        'Inactive banners will not appear for users.',
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _active = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(tr('إلغاء', 'Cancel')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text(tr('حفظ', 'Save')),
                        ),
                      ),
                    ],
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

class _AdminProductEditorDialog extends StatefulWidget {
  const _AdminProductEditorDialog({
    this.initialProduct,
  });

  final ProductComparison? initialProduct;

  @override
  State<_AdminProductEditorDialog> createState() => _AdminProductEditorDialogState();
}

class _AdminProductEditorDialogState extends State<_AdminProductEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _expensiveNameController;
  late final TextEditingController _expensivePriceController;
  late final TextEditingController _expensiveImageUrlController;
  late final TextEditingController _alternativeNameController;
  late final TextEditingController _alternativePriceController;
  late final TextEditingController _alternativeImageUrlController;
  late final TextEditingController _buyUrlController;
  late String _selectedCategoryId;
  late final List<ProductCategory> _categories;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProduct;
    _expensiveNameController = TextEditingController(
      text: initial?.expensiveName ?? '',
    );
    _expensivePriceController = TextEditingController(
      text: initial != null ? initial.expensivePrice.toString() : '',
    );
    _expensiveImageUrlController = TextEditingController(
      text: initial?.expensiveImageUrl ?? '',
    );
    _alternativeNameController = TextEditingController(
      text: initial?.alternativeName ?? '',
    );
    _alternativePriceController = TextEditingController(
      text: initial != null ? initial.alternativePrice.toString() : '',
    );
    _alternativeImageUrlController = TextEditingController(
      text: initial?.alternativeImageUrl ?? '',
    );
    _buyUrlController = TextEditingController(text: initial?.buyUrl ?? '');

    _categories = ProductCategoryCatalog.defaults
        .where((category) => category.id != ProductCategoryCatalog.allId)
        .toList();

    final currentCategoryId =
        initial?.categoryId ?? ProductCategoryCatalog.defaults[1].id;
    if (!_categories.any((category) => category.id == currentCategoryId)) {
      _categories.insert(
        0,
        ProductCategoryCatalog.lookup(
          currentCategoryId,
          fallbackLabel: initial?.categoryLabel ?? currentCategoryId,
        ),
      );
    }
    _selectedCategoryId = currentCategoryId;
  }

  @override
  void dispose() {
    _expensiveNameController.dispose();
    _expensivePriceController.dispose();
    _expensiveImageUrlController.dispose();
    _alternativeNameController.dispose();
    _alternativePriceController.dispose();
    _alternativeImageUrlController.dispose();
    _buyUrlController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label مطلوب.';
    }
    return null;
  }

  String? _validatePrice(String? value, String label) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'أدخل قيمة صحيحة لـ $label.';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return validUrlMessage('رابطاً', 'URL');
    }
    return null;
  }

  List<String> _composeTags(ProductCategory category) {
    final tags = <String>{
      category.label,
      _expensiveNameController.text.trim(),
      _alternativeNameController.text.trim(),
      ...?widget.initialProduct?.tags,
    };

    return tags.where((tag) => tag.trim().isNotEmpty).toList();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final selectedCategory = ProductCategoryCatalog.lookup(_selectedCategoryId);
    final initial = widget.initialProduct;

    Navigator.of(context).pop(
      ProductComparison(
        documentId: initial?.documentId,
        categoryId: selectedCategory.id,
        categoryLabel: selectedCategory.label,
        expensiveName: _expensiveNameController.text.trim(),
        expensivePrice: double.parse(_expensivePriceController.text.trim()),
        expensiveImageUrl: _expensiveImageUrlController.text.trim(),
        alternativeName: _alternativeNameController.text.trim(),
        alternativePrice: double.parse(_alternativePriceController.text.trim()),
        alternativeImageUrl: _alternativeImageUrlController.text.trim(),
        buyUrl: _buyUrlController.text.trim(),
        rating: initial?.rating ?? 0,
        reviewCount: initial?.reviewCount ?? 0,
        tags: _composeTags(selectedCategory),
        fragranceNotes: initial?.fragranceNotes,
        activeIngredients: initial?.activeIngredients,
        localLocationLabel: initial?.localLocationLabel,
        localLocationUrl: initial?.localLocationUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.initialProduct == null
                        ? tr('إضافة منتج جديد', 'Add new product')
                        : tr('تعديل المنتج', 'Edit product'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: tr('القسم', 'Category'),
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(
                              localizedCategoryLabelForId(
                                category.id,
                                fallbackLabel: category.label,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expensiveNameController,
                    decoration: InputDecoration(
                      labelText: tr('اسم المنتج المرجعي', 'Reference product name'),
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) =>
                        _validateRequired(
                          value,
                          tr('اسم المنتج المرجعي', 'Reference product name'),
                        ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expensivePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: tr('سعر المنتج المرجعي', 'Reference product price'),
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    validator: (value) =>
                        _validatePrice(
                          value,
                          tr('سعر المنتج المرجعي', 'Reference product price'),
                        ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expensiveImageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: tr(
                        'رابط صورة المنتج المرجعي',
                        'Reference product image URL',
                      ),
                      prefixIcon: Icon(Icons.image_search_rounded),
                    ),
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativeNameController,
                    decoration: InputDecoration(
                      labelText: tr('اسم الخيار المقارن', 'Compared option name'),
                      prefixIcon: Icon(Icons.swap_horiz_rounded),
                    ),
                    validator: (value) =>
                        _validateRequired(
                          value,
                          tr('اسم الخيار المقارن', 'Compared option name'),
                        ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: tr('سعر الخيار المقارن', 'Compared option price'),
                      prefixIcon: Icon(Icons.savings_rounded),
                    ),
                    validator: (value) =>
                        _validatePrice(
                          value,
                          tr('سعر الخيار المقارن', 'Compared option price'),
                        ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativeImageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: tr(
                        'رابط صورة الخيار المقارن',
                        'Compared option image URL',
                      ),
                      prefixIcon: Icon(Icons.image_search_rounded),
                    ),
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _buyUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: tr('رابط الشراء أو الإعلان', 'Purchase or ad URL'),
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(tr('إلغاء', 'Cancel')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text(tr('حفظ', 'Save')),
                        ),
                      ),
                    ],
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

class _AdminExclusiveDealEditorDialog extends StatefulWidget {
  const _AdminExclusiveDealEditorDialog({
    this.initialDeal,
  });

  final ExclusiveDeal? initialDeal;

  @override
  State<_AdminExclusiveDealEditorDialog> createState() =>
      _AdminExclusiveDealEditorDialogState();
}

class _AdminExclusiveDealEditorDialogState
    extends State<_AdminExclusiveDealEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _beforePriceController;
  late final TextEditingController _afterPriceController;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDeal;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _imageUrlController = TextEditingController(text: initial?.imageUrl ?? '');
    _beforePriceController = TextEditingController(
      text: initial != null ? initial.beforePrice.toString() : '',
    );
    _afterPriceController = TextEditingController(
      text: initial != null ? initial.afterPrice.toString() : '',
    );
    _expiryDate = initial?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _beforePriceController.dispose();
    _afterPriceController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return requiredFieldMessage(label, label);
    }
    return null;
  }

  String? _validatePrice(String? value, String label) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return validValueMessage(label, label);
    }
    return null;
  }

  String? _validateDiscountPrice(String? value) {
    final afterPrice = double.tryParse(value?.trim() ?? '');
    final beforePrice = double.tryParse(_beforePriceController.text.trim());
    if (afterPrice == null || afterPrice <= 0) {
      return tr(
        'أدخل قيمة صحيحة للسعر بعد الخصم.',
        'Enter a valid value for the discounted price.',
      );
    }
    if (beforePrice != null && afterPrice >= beforePrice) {
      return tr(
        'يجب أن يكون السعر بعد الخصم أقل من السعر قبل الخصم.',
        'The discounted price must be lower than the original price.',
      );
    }
    return null;
  }

  String? _validateUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return requiredFieldMessage(
        tr('رابط صورة العرض', 'Deal image URL'),
        tr('رابط صورة العرض', 'Deal image URL'),
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return validUrlMessage('رابط صورة', 'image URL');
    }
    return null;
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _expiryDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
      );
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      ExclusiveDeal(
        id: widget.initialDeal?.id ?? '',
        title: _titleController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        beforePrice: double.parse(_beforePriceController.text.trim()),
        afterPrice: double.parse(_afterPriceController.text.trim()),
        expiryDate: _expiryDate,
        active: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.initialDeal == null
                        ? tr('إضافة عرض حصري', 'Add exclusive deal')
                        : tr('تعديل العرض الحصري', 'Edit exclusive deal'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: tr('عنوان العرض', 'Deal title'),
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (value) =>
                        _validateRequired(value, tr('عنوان العرض', 'Deal title')),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _imageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: tr('رابط صورة العرض', 'Deal image URL'),
                      prefixIcon: Icon(Icons.image_search_rounded),
                    ),
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _beforePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: tr('السعر قبل', 'Before price'),
                      prefixIcon: Icon(Icons.money_off_csred_rounded),
                    ),
                    validator: (value) =>
                        _validatePrice(value, tr('السعر قبل', 'Before price')),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _afterPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: tr('السعر بعد', 'After price'),
                      prefixIcon: Icon(Icons.local_offer_rounded),
                    ),
                    validator: _validateDiscountPrice,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickExpiryDate,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppPalette.dealsSoftRed,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppPalette.dealsBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, color: AppPalette.dealsRed),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('تاريخ انتهاء العرض', 'Deal expiry date'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1B2F5E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDealExpiryLabel(_expiryDate),
                                  style: const TextStyle(
                                    color: Color(0xFF6B7A9A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_calendar_rounded, color: AppPalette.dealsRed),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(tr('إلغاء', 'Cancel')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text(tr('حفظ', 'Save')),
                        ),
                      ),
                    ],
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

class AdminProductDraft {
  const AdminProductDraft({
    required this.referenceName,
    required this.referencePrice,
    required this.comparisonName,
    required this.comparisonPrice,
    required this.buyUrl,
    required this.categoryLabel,
  });

  final String referenceName;
  final double referencePrice;
  final String comparisonName;
  final double comparisonPrice;
  final String buyUrl;
  final String categoryLabel;

  ProductComparison toProductComparison() {
    final normalizedCategory = categoryLabel.trim();
    final normalizedUrl = buyUrl.trim();
    return ProductComparison(
      categoryId: ProductCategoryCatalog.inferId(normalizedCategory),
      categoryLabel: normalizedCategory,
      expensiveName: referenceName.trim(),
      expensivePrice: referencePrice,
      expensiveImageUrl: '',
      alternativeName: comparisonName.trim(),
      alternativePrice: comparisonPrice,
      alternativeImageUrl: '',
      buyUrl: normalizedUrl.isEmpty
          ? ''
          : AffiliateLinkService.attachAffiliateTag(normalizedUrl),
      rating: 0,
      reviewCount: 0,
      tags: [
        normalizedCategory,
        referenceName.trim(),
        comparisonName.trim(),
        'admin-entry',
      ],
    );
  }
}

class _AdminAddProductDialog extends StatefulWidget {
  const _AdminAddProductDialog();

  @override
  State<_AdminAddProductDialog> createState() => _AdminAddProductDialogState();
}

class _AdminAddProductDialogState extends State<_AdminAddProductDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _originalNameController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _alternativeNameController =
      TextEditingController();
  final TextEditingController _alternativePriceController =
      TextEditingController();
  final TextEditingController _affiliateUrlController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  bool _obscurePassword = true;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _categoryController.text = localizedCategoryLabelForId('coffee');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _originalNameController.dispose();
    _originalPriceController.dispose();
    _alternativeNameController.dispose();
    _alternativePriceController.dispose();
    _affiliateUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (_passwordController.text.trim() != LeastPriceDataConfig.adminPassword) {
      setState(() {
        _passwordError = tr(
          'كلمة المرور غير صحيحة.',
          'The admin password is incorrect.',
        );
      });
      return;
    }

    final draft = AdminProductDraft(
      referenceName: _originalNameController.text,
      referencePrice: _parsePrice(_originalPriceController.text),
      comparisonName: _alternativeNameController.text,
      comparisonPrice: _parsePrice(_alternativePriceController.text),
      buyUrl: _affiliateUrlController.text,
      categoryLabel: _categoryController.text,
    );

    Navigator.of(context).pop(draft);
  }

  double _parsePrice(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  String? _validateRequired(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return requiredFieldMessage(label, label);
    }

    return null;
  }

  String? _validatePrice(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return requiredFieldMessage(label, label);
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return validValueMessage(label, label);
    }

    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return tr(
        'أدخل رابطاً صالحاً يبدأ بـ http أو https، أو اترك الحقل فارغاً.',
        'Enter a valid URL that starts with http or https, or leave it empty.',
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2FBF7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Color(0xFFE8711A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('لوحة المسؤول', 'Admin panel'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF17332B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr(
                                'أضف منتجاً جديداً ليظهر فوراً داخل التطبيق.',
                                'Add a new product and publish it instantly inside the app.',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF667C74),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: tr('كلمة المرور', 'Password'),
                      prefixIcon: const Icon(Icons.lock_rounded),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() {
                          _passwordError = null;
                        });
                      }
                    },
                    validator: (value) => _validateRequired(
                      value,
                      label: tr('كلمة المرور', 'Password'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _originalNameController,
                    decoration: InputDecoration(
                      labelText: tr(
                        'اسم المنتج المرجعي',
                        'Reference product name',
                      ),
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) => _validateRequired(
                      value,
                      label: tr('اسم المنتج المرجعي', 'Reference product name'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _originalPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: tr(
                        'سعر المنتج المرجعي',
                        'Reference product price',
                      ),
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                    ),
                    validator: (value) => _validatePrice(
                      value,
                      label: tr('سعر المنتج المرجعي', 'Reference product price'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativeNameController,
                    decoration: InputDecoration(
                      labelText: tr(
                        'اسم الخيار المقارن',
                        'Compared option name',
                      ),
                      prefixIcon: const Icon(Icons.swap_horiz_rounded),
                    ),
                    validator: (value) => _validateRequired(
                      value,
                      label: tr('اسم الخيار المقارن', 'Compared option name'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: tr(
                        'سعر الخيار المقارن',
                        'Compared option price',
                      ),
                      prefixIcon: const Icon(Icons.savings_rounded),
                    ),
                    validator: (value) => _validatePrice(
                      value,
                      label: tr('سعر الخيار المقارن', 'Compared option price'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _affiliateUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: tr(
                        'رابط الشراء أو الإعلان (اختياري)',
                        'Purchase or ad URL (optional)',
                      ),
                      prefixIcon: const Icon(Icons.link_rounded),
                    ),
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: tr('القسم', 'Category'),
                      prefixIcon: const Icon(Icons.category_rounded),
                    ),
                    validator: (value) => _validateRequired(
                      value,
                      label: tr('القسم', 'Category'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(tr('إلغاء', 'Cancel')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text(tr('حفظ', 'Save')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(
                      'يمكن تغيير كلمة المرور من الثابت adminPassword داخل LeastPriceDataConfig.',
                      'You can change the admin password from the adminPassword constant in LeastPriceDataConfig.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF667C74),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
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

class _RateAlternativeDialog extends StatefulWidget {
  const _RateAlternativeDialog({
    required this.product,
  });

  final ProductComparison product;

  @override
  State<_RateAlternativeDialog> createState() => _RateAlternativeDialogState();
}

class _RateAlternativeDialogState extends State<_RateAlternativeDialog> {
  late double _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.product.rating > 0 ? widget.product.rating : 4.0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('تقييم جودة الخيار المقارن', 'Rate the compared option'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17332B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'كيف ترى "${widget.product.alternativeName}" من حيث الجودة والمكوّنات مقارنةً بـ "${widget.product.expensiveName}"؟',
                'How do you rate "${widget.product.alternativeName}" in quality and ingredients compared with "${widget.product.expensiveName}"?',
              ),
              style: const TextStyle(
                color: Color(0xFF667C74),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                spacing: 8,
                children: List.generate(5, (index) {
                  final value = index + 1.0;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedRating = value;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _selectedRating >= value
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFF5B400),
                        size: 34,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                tr(
                  '${_selectedRating.toStringAsFixed(1)} من 5',
                  '${_selectedRating.toStringAsFixed(1)} out of 5',
                ),
                style: const TextStyle(
                  color: Color(0xFF7A5A00),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr('إلغاء', 'Cancel')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selectedRating),
                    child: Text(tr('إرسال التقييم', 'Submit rating')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserSavingsProfile {
  const UserSavingsProfile({
    required this.userId,
    required this.phoneNumber,
    required this.inviteCode,
    required this.invitedBy,
    required this.invitedFriendsCount,
    required this.referralRewardApplied,
    required this.shareBaseUrl,
    required this.inviteMessageTemplate,
  });

  final String userId;
  final String phoneNumber;
  final String inviteCode;
  final String invitedBy;
  final int invitedFriendsCount;
  final bool referralRewardApplied;
  final String shareBaseUrl;
  final String inviteMessageTemplate;

  factory UserSavingsProfile.initial() {
    return const UserSavingsProfile(
      userId: '',
      phoneNumber: '',
      inviteCode: 'LP-RIY-204',
      invitedBy: '',
      invitedFriendsCount: 0,
      referralRewardApplied: false,
      shareBaseUrl: LeastPriceDataConfig.appShareUrl,
      inviteMessageTemplate:
          'أنا وفرت {SAVED_AMOUNT} ريال باستخدام تطبيق أرخص سعر! '
          'حمل التطبيق الآن واستخدم كود الدعوة الخاص بي: {USER_CODE}\n{APP_LINK}',
    );
  }

  factory UserSavingsProfile.fromJson(Map<String, dynamic> json) {
    return UserSavingsProfile(
      userId: _stringValue(json['userId']) ?? '',
      phoneNumber: _stringValue(json['phoneNumber']) ?? '',
      inviteCode: _stringValue(json['referralCode'] ?? json['inviteCode']) ??
          'LP-RIY-204',
      invitedBy: _stringValue(json['invitedBy']) ?? '',
      invitedFriendsCount:
          _intValue(json['invitedCount'] ?? json['invitedFriendsCount']),
      referralRewardApplied:
          _boolValue(json['referralRewardApplied'] ?? json['rewardApplied']),
      shareBaseUrl:
          _stringValue(json['shareBaseUrl']) ?? LeastPriceDataConfig.appShareUrl,
      inviteMessageTemplate: _stringValue(json['inviteMessageTemplate']) ??
          'أنا وفرت {SAVED_AMOUNT} ريال باستخدام تطبيق أرخص سعر! '
              'حمل التطبيق الآن واستخدم كود الدعوة الخاص بي: {USER_CODE}\n{APP_LINK}',
    );
  }

  factory UserSavingsProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return UserSavingsProfile.fromJson({
      ...?document.data(),
      'userId': document.id,
    });
  }

  UserSavingsProfile copyWith({
    String? userId,
    String? phoneNumber,
    String? inviteCode,
    String? invitedBy,
    int? invitedFriendsCount,
    bool? referralRewardApplied,
    String? shareBaseUrl,
    String? inviteMessageTemplate,
  }) {
    return UserSavingsProfile(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      inviteCode: inviteCode ?? this.inviteCode,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedFriendsCount: invitedFriendsCount ?? this.invitedFriendsCount,
      referralRewardApplied:
          referralRewardApplied ?? this.referralRewardApplied,
      shareBaseUrl: shareBaseUrl ?? this.shareBaseUrl,
      inviteMessageTemplate:
          inviteMessageTemplate ?? this.inviteMessageTemplate,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'phoneNumber': phoneNumber,
      'referralCode': inviteCode,
      if (invitedBy.trim().isNotEmpty) 'invitedBy': invitedBy,
      'invitedCount': invitedFriendsCount,
      'referralRewardApplied': referralRewardApplied,
      'shareBaseUrl': shareBaseUrl,
      'inviteMessageTemplate': inviteMessageTemplate,
    };
  }
}

class AutomationHealthStatus {
  const AutomationHealthStatus({
    required this.service,
    required this.status,
    required this.lastRunAt,
    required this.lastSuccessAt,
    required this.summary,
  });

  final String service;
  final String status;
  final DateTime? lastRunAt;
  final DateTime? lastSuccessAt;
  final String summary;

  factory AutomationHealthStatus.initial() {
    return const AutomationHealthStatus(
      service: 'daily_price_bot',
      status: 'unknown',
      lastRunAt: null,
      lastSuccessAt: null,
      summary: '',
    );
  }

  factory AutomationHealthStatus.fromJson(Map<String, dynamic> json) {
    return AutomationHealthStatus(
      service: _stringValue(json['service']) ?? 'daily_price_bot',
      status: _stringValue(json['status']) ?? 'unknown',
      lastRunAt: _dateTimeValue(json['lastRunAt'] ?? json['lastAttemptAt']),
      lastSuccessAt: _dateTimeValue(json['lastSuccessAt']),
      summary: _stringValue(json['message']) ?? '',
    );
  }

  String get statusLabel {
    if (lastSuccessAt == null) {
      return tr(
        'الروبوت: بانتظار أول تشغيل',
        'Bot: waiting for first run',
      );
    }
    return tr(
      'آخر تحديث ${_formatHealthTimestamp(lastSuccessAt)}',
      'Last update ${_formatHealthTimestamp(lastSuccessAt)}',
    );
  }
}

enum ProductDataSource {
  remote,
  asset,
  mock,
}

extension ProductDataSourceLabel on ProductDataSource {
  String get label {
    switch (this) {
      case ProductDataSource.remote:
        return tr('رابط خارجي', 'Remote feed');
      case ProductDataSource.asset:
        return tr('ملف JSON', 'JSON file');
      case ProductDataSource.mock:
        return tr('بيانات تجريبية', 'Mock data');
    }
  }
}

class LeastPriceDataConfig {
  const LeastPriceDataConfig._();

  static const String productsCollectionName = 'products';
  static const String adBannersCollectionName = 'ad_banners';
  static const String exclusiveDealsCollectionName = 'exclusive_deals';
  static const String comparisonSearchCacheCollectionName =
      'comparison_search_cache';
  static const String usersCollectionName = 'users';
  static const String popularProductsCollectionName = 'popular_products';
  static const String searchRequestsCollectionName = 'search_requests';
  static const String systemHealthCollectionName = 'system_health';
  static const String systemHealthDocumentId = 'daily_price_bot';
  static const String remoteJsonUrl =
      'https://leastprice-yaser.web.app/assets/assets/data/products.json';
  static const String assetJsonPath = 'assets/data/products.json';
  static const String appShareUrl = 'https://leastprice-yaser.web.app/';
  static const String adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: 'yaser.haroon79@gmail.com',
  );
  static const String adminPassword = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: 'leastprice123',
  );
  static const String affiliateTag = 'myid-21';
  static const int comparisonSearchCacheHours = 24;
  static const String serpApiKey = String.fromEnvironment(
    'SERPAPI_KEY',
    defaultValue:
        '8f5e0a4c11cb0e6972f549ee390b083531ca2545ef1c02593c20efae8e917861',
  );
  static const String originalOnSaleTag = 'المنتج الأصلي عليه عرض حالياً';
  static const SearchProviderType searchProviderType = SearchProviderType.serper;
  static const String serperApiKey =
      String.fromEnvironment('SERPER_API_KEY', defaultValue: '');
  static const String tavilyApiKey =
      String.fromEnvironment('TAVILY_API_KEY', defaultValue: '');
  static const bool enableAutomaticPriceRefresh = true;
}

class ProductLoadResult {
  const ProductLoadResult({
    required this.products,
    required this.source,
    this.referralProfile,
    this.notice,
  });

  final List<ProductComparison> products;
  final ProductDataSource source;
  final UserSavingsProfile? referralProfile;
  final String? notice;
}

class CatalogRefreshResult {
  const CatalogRefreshResult({
    required this.products,
    this.notice,
  });

  final List<ProductComparison> products;
  final String? notice;
}

enum SearchProviderType {
  serper,
  tavily,
}

class SearchResultItem {
  const SearchResultItem({
    required this.title,
    required this.link,
    required this.snippet,
  });

  final String title;
  final String link;
  final String snippet;
}

class ComparisonSearchResult {
  const ComparisonSearchResult({
    required this.title,
    required this.price,
    required this.storeName,
    required this.imageUrl,
    required this.productUrl,
  });

  final String title;
  final double price;
  final String storeName;
  final String imageUrl;
  final String productUrl;

  factory ComparisonSearchResult.fromJson(Map<String, dynamic> json) {
    final title = _stringValue(json['title'])?.trim() ?? '';
    final storeName =
            _stringValue(
              json['storeName'] ?? json['source'] ?? json['seller'],
            )?.trim() ??
        '';
    final productUrl =
            _stringValue(
              json['productUrl'] ?? json['product_link'] ?? json['link'],
            )?.trim() ??
        '';
    final thumbnails = json['thumbnails'];
    final imageUrl = _normalizedImageUrl(
      _stringValue(json['imageUrl'] ?? json['thumbnail']) ??
          (thumbnails is List && thumbnails.isNotEmpty
              ? _stringValue(thumbnails.first) ?? ''
              : ''),
      fallbackLabel: title.isEmpty ? 'LeastPrice Result' : title,
    );
    final rawPriceText = _stringValue(json['price']);
    final parsedFallbackPrice = rawPriceText == null
        ? null
        : _extractMarketplacePrice(rawPriceText);
    final rawExtractedPrice = json['priceValue'] ?? json['extracted_price'];
    final extractedPrice = rawExtractedPrice == null
        ? null
        : _doubleValue(rawExtractedPrice);
    final price = extractedPrice ?? parsedFallbackPrice ?? 0;

    return ComparisonSearchResult(
      title: title,
      price: price,
      storeName: storeName.isEmpty ? tr('متجر إلكتروني', 'Online store') : storeName,
      imageUrl: imageUrl,
      productUrl: productUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'priceValue': price,
      'price': formatPrice(price),
      'storeName': storeName,
      'imageUrl': imageUrl,
      'productUrl': productUrl,
    };
  }
}

class ComparisonSearchCacheEntry {
  const ComparisonSearchCacheEntry({
    required this.query,
    required this.normalizedQuery,
    required this.cachedAt,
    required this.results,
  });

  final String query;
  final String normalizedQuery;
  final DateTime cachedAt;
  final List<ComparisonSearchResult> results;

  bool get isFresh =>
      DateTime.now().difference(cachedAt) <
      Duration(hours: LeastPriceDataConfig.comparisonSearchCacheHours);

  factory ComparisonSearchCacheEntry.fromJson(Map<String, dynamic> json) {
    final items = json['results'];
    return ComparisonSearchCacheEntry(
      query: _stringValue(json['query']) ?? '',
      normalizedQuery: _stringValue(json['normalizedQuery']) ?? '',
      cachedAt:
          _dateTimeValue(json['cachedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      results: items is List
          ? items
                .whereType<Map>()
                .map(
                  (item) => ComparisonSearchResult.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where(
                  (result) =>
                      result.title.trim().isNotEmpty &&
                      result.productUrl.trim().isNotEmpty &&
                      result.price > 0,
                )
                .toList()
          : const <ComparisonSearchResult>[],
    );
  }
}

class ComparisonSearchResponse {
  const ComparisonSearchResponse({
    required this.results,
    required this.fromCache,
    this.notice,
  });

  final List<ComparisonSearchResult> results;
  final bool fromCache;
  final String? notice;
}

class SerpApiShoppingSearchService {
  const SerpApiShoppingSearchService({
    FirestoreCatalogService? catalogService,
  }) : _catalogService = catalogService;

  final FirestoreCatalogService? _catalogService;

  FirestoreCatalogService get _service =>
      _catalogService ?? const FirestoreCatalogService();

  Future<ComparisonSearchResponse> search({
    required String query,
    required bool firebaseReady,
    bool forceRefresh = false,
  }) async {
    final trimmedQuery = query.trim();
    final normalizedQuery = _normalizeArabic(trimmedQuery);
    if (normalizedQuery.length < 2) {
      return const ComparisonSearchResponse(
        results: <ComparisonSearchResult>[],
        fromCache: false,
      );
    }

    ComparisonSearchCacheEntry? cachedEntry;
    if (firebaseReady) {
      cachedEntry = await _service.fetchComparisonSearchCache(trimmedQuery);
      if (!forceRefresh &&
          cachedEntry != null &&
          cachedEntry.isFresh &&
          cachedEntry.results.isNotEmpty) {
        return ComparisonSearchResponse(
          results: cachedEntry.results,
          fromCache: true,
          notice: tr(
            'تم عرض النتائج من الذاكرة المؤقتة المحفوظة خلال آخر 24 ساعة.',
            'Results were loaded from the cache saved within the last 24 hours.',
          ),
        );
      }
    }

    final apiKey = LeastPriceDataConfig.serpApiKey.trim();
    if (apiKey.isEmpty) {
      return ComparisonSearchResponse(
        results: cachedEntry?.results ?? const <ComparisonSearchResult>[],
        fromCache: cachedEntry != null,
        notice: tr(
          'مفتاح SerpApi غير موجود حالياً، لذلك لا يمكن تنفيذ البحث الحي.',
          'The SerpApi key is missing, so live search cannot run right now.',
        ),
      );
    }

    try {
      final results = await _fetchLiveResults(trimmedQuery, apiKey);
      if (firebaseReady && results.isNotEmpty) {
        await _service.saveComparisonSearchCache(
          query: trimmedQuery,
          results: results,
        );
      }

      return ComparisonSearchResponse(
        results: results,
        fromCache: false,
        notice: results.isEmpty
            ? tr(
                'لم نجد نتائج تسوق مناسبة لهذا البحث حالياً.',
                'No matching shopping results were found for this search right now.',
              )
            : tr(
                'تم تحديث النتائج مباشرة من SerpApi للسوق السعودي.',
                'Results were refreshed live from SerpApi for the Saudi market.',
              ),
      );
    } catch (_) {
      if (cachedEntry != null && cachedEntry.results.isNotEmpty) {
        return ComparisonSearchResponse(
          results: cachedEntry.results,
          fromCache: true,
          notice: tr(
            'تعذر تحديث النتائج الآن، لذلك تم عرض آخر نسخة محفوظة من Firestore.',
            'Live refresh failed, so the latest saved Firestore copy is shown instead.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<List<ComparisonSearchResult>> _fetchLiveResults(
    String query,
    String apiKey,
  ) async {
    final uri = Uri.https('serpapi.com', '/search.json', {
      'engine': 'google_shopping',
      'q': query,
      'location': 'Saudi Arabia',
      'gl': 'sa',
      'hl': 'ar',
      'api_key': apiKey,
    });

    final response = await http.get(uri);
    if (response.statusCode >= 400) {
      throw Exception('SerpApi responded with ${response.statusCode}');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Unexpected SerpApi payload');
    }

    final results = _parseResults(payload)
      ..sort((a, b) => a.price.compareTo(b.price));

    return results;
  }

  List<ComparisonSearchResult> _parseResults(Map<String, dynamic> payload) {
    final results = <ComparisonSearchResult>[];
    final seen = <String>{};

    void addResult(dynamic rawItem) {
      if (rawItem is! Map) {
        return;
      }

      final item = ComparisonSearchResult.fromJson(
        Map<String, dynamic>.from(rawItem),
      );
      if (item.title.trim().isEmpty ||
          item.productUrl.trim().isEmpty ||
          item.price <= 0) {
        return;
      }

      final fingerprint = _normalizeArabic(
        '${item.title}|${item.storeName}|${item.price}',
      );
      if (!seen.add(fingerprint)) {
        return;
      }

      results.add(item);
    }

    final directResults = payload['shopping_results'];
    if (directResults is List) {
      for (final item in directResults) {
        addResult(item);
      }
    }

    final categorizedResults = payload['categorized_shopping_results'];
    if (categorizedResults is List) {
      for (final category in categorizedResults) {
        if (category is! Map) {
          continue;
        }
        final categoryItems = category['shopping_results'];
        if (categoryItems is! List) {
          continue;
        }
        for (final item in categoryItems) {
          addResult(item);
        }
      }
    }

    return results;
  }
}

class ParsedCatalogPayload {
  const ParsedCatalogPayload({
    required this.products,
    this.referralProfile,
  });

  final List<ProductComparison> products;
  final UserSavingsProfile? referralProfile;
}

class AffiliateLinkService {
  const AffiliateLinkService._();

  static const Set<String> supportedHosts = {
    'amazon.sa',
    'www.amazon.sa',
    'noon.com',
    'www.noon.com',
    'nahdionline.com',
    'www.nahdionline.com',
    'al-dawaa.com',
    'www.al-dawaa.com',
    'hungerstation.com',
    'www.hungerstation.com',
    'jahez.net',
    'www.jahez.net',
    'mrsool.co',
    'www.mrsool.co',
  };

  static String attachAffiliateTag(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return url;
    }

    final parameters = Map<String, String>.from(uri.queryParameters);
    parameters['tag'] = LeastPriceDataConfig.affiliateTag;

    return uri.replace(queryParameters: parameters).toString();
  }

  static bool isSupportedStore(Uri uri) {
    return supportedHosts.contains(uri.host.toLowerCase());
  }

  static String prepareForOpen(String rawUrl) {
    return attachAffiliateTag(rawUrl);
  }
}

class SmartMonitorService {
  const SmartMonitorService();

  Future<CatalogRefreshResult> refreshProducts(
    List<ProductComparison> products,
  ) async {
    if (!LeastPriceDataConfig.enableAutomaticPriceRefresh) {
      return CatalogRefreshResult(
        products: products,
        notice: tr(
          'التحديث التلقائي للأسعار معطل حالياً من الإعدادات.',
          'Automatic price refresh is currently disabled in settings.',
        ),
      );
    }

    final searchClient = SearchAutomationClient.fromConfig();
    if (searchClient == null) {
      return CatalogRefreshResult(
        products: products,
        notice: tr(
          'تم تفعيل منطق التحديث الذكي للأسعار، لكنه يحتاج مفتاح API صالحاً لـ Serper أو Tavily.',
          'Smart price refresh is enabled, but it still needs a valid Serper or Tavily API key.',
        ),
      );
    }

    final refreshedProducts = await Future.wait(
      products.map((product) => _refreshSingleProduct(searchClient, product)),
    );

    final refreshedCount = refreshedProducts
        .asMap()
        .entries
        .where((entry) => entry.value != products[entry.key])
        .length;

    return CatalogRefreshResult(
      products: refreshedProducts,
      notice: refreshedCount > 0
          ? tr(
              'تم تحديث $refreshedCount منتجاً تلقائياً من نتائج البحث السعودية.',
              '$refreshedCount products were automatically updated from Saudi search results.',
            )
          : tr(
              'لم يتم العثور على أسعار أحدث من موصل البحث الحالي، فتم الإبقاء على البيانات الحالية.',
              'No newer prices were found from the current search connector, so the current data was kept.',
            ),
    );
  }

  Future<ProductComparison> _refreshSingleProduct(
    SearchAutomationClient searchClient,
    ProductComparison product,
  ) async {
    try {
      final expensiveCandidates = await searchClient.search(
        _buildExpensiveQuery(product),
      );
      final alternativeCandidates = await searchClient.search(
        _buildAlternativeQuery(product),
      );

      final expensiveMatch = _selectBestMatch(
        expensiveCandidates,
        preferredHosts: const ['amazon.sa', 'noon.com'],
      );
      final alternativeMatch = _selectBestMatch(
        alternativeCandidates,
        preferredHosts: const [
          'amazon.sa',
          'noon.com',
          'nahdionline.com',
          'al-dawaa.com',
          'hungerstation.com',
          'jahez.net',
          'mrsool.co',
        ],
        requirePreferredHost: true,
      );

      final expensivePrice = expensiveMatch == null
          ? product.expensivePrice
          : _extractPrice(expensiveMatch.title, expensiveMatch.snippet) ??
              product.expensivePrice;

      final alternativePrice = alternativeMatch == null
          ? product.alternativePrice
          : _extractPrice(alternativeMatch.title, alternativeMatch.snippet) ??
              product.alternativePrice;

      final updatedBuyUrl = alternativeMatch == null
          ? AffiliateLinkService.attachAffiliateTag(product.buyUrl)
          : AffiliateLinkService.attachAffiliateTag(alternativeMatch.link);

      final updatedTags = _updatedDynamicTags(
        product.tags,
        expensivePrice: expensivePrice,
        alternativePrice: alternativePrice,
      );

      if (expensivePrice == product.expensivePrice &&
          alternativePrice == product.alternativePrice &&
          updatedBuyUrl == product.buyUrl &&
          _sameStringLists(updatedTags, product.tags)) {
        return product;
      }

      return product.copyWith(
        expensivePrice: expensivePrice,
        alternativePrice: alternativePrice,
        buyUrl: updatedBuyUrl,
        tags: updatedTags,
      );
    } catch (_) {
      return product;
    }
  }

  String _buildExpensiveQuery(ProductComparison product) {
    return '${product.expensiveName} site:amazon.sa OR site:noon.com السعودية سعر';
  }

  String _buildAlternativeQuery(ProductComparison product) {
    return '${product.alternativeName} السعودية سعر '
        'site:noon.com OR site:amazon.sa OR site:nahdionline.com OR site:al-dawaa.com OR site:hungerstation.com OR site:jahez.net';
  }

  SearchResultItem? _selectBestMatch(
    List<SearchResultItem> items, {
    required List<String> preferredHosts,
    bool requirePreferredHost = false,
  }) {
    SearchResultItem? best;
    var bestScore = -1;

    for (final item in items) {
      final uri = Uri.tryParse(item.link);
      if (uri == null) {
        continue;
      }

      final hasPreferredHost = preferredHosts.any(
        (host) => uri.host.contains(host),
      );
      if (requirePreferredHost && !hasPreferredHost) {
        continue;
      }

      var score = 0;
      for (final host in preferredHosts) {
        if (uri.host.contains(host)) {
          score += 10;
        }
      }
      if (_extractPrice(item.title, item.snippet) != null) {
        score += 5;
      }

      if (score > bestScore) {
        best = item;
        bestScore = score;
      }
    }

    return best;
  }

  double? _extractPrice(String title, String snippet) {
    final text = '$title $snippet'.replaceAll(',', '');
    final patterns = [
      RegExp(r'(?:ر\.?\s?س|ريال|SAR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
          caseSensitive: false),
      RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:ر\.?\s?س|ريال|SAR)',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '');
      }
    }

    return null;
  }

  List<String> _updatedDynamicTags(
    List<String> tags, {
    required double expensivePrice,
    required double alternativePrice,
  }) {
    final filtered = tags
        .where(
          (tag) =>
              _normalizeArabic(tag) !=
              _normalizeArabic(LeastPriceDataConfig.originalOnSaleTag),
        )
        .toList();

    if (expensivePrice > 0 &&
        alternativePrice > 0 &&
        expensivePrice <= alternativePrice) {
      filtered.insert(0, LeastPriceDataConfig.originalOnSaleTag);
    }

    return filtered;
  }
}

class SearchAutomationClient {
  const SearchAutomationClient._({
    required this.providerType,
    required this.apiKey,
  });

  final SearchProviderType providerType;
  final String apiKey;

  static SearchAutomationClient? fromConfig() {
    switch (LeastPriceDataConfig.searchProviderType) {
      case SearchProviderType.serper:
        final key = LeastPriceDataConfig.serperApiKey;
        if (key.trim().isEmpty) {
          return null;
        }
        return SearchAutomationClient._(
          providerType: SearchProviderType.serper,
          apiKey: key,
        );
      case SearchProviderType.tavily:
        final key = LeastPriceDataConfig.tavilyApiKey;
        if (key.trim().isEmpty) {
          return null;
        }
        return SearchAutomationClient._(
          providerType: SearchProviderType.tavily,
          apiKey: key,
        );
    }
  }

  Future<List<SearchResultItem>> search(String query) async {
    switch (providerType) {
      case SearchProviderType.serper:
        return _searchSerper(query);
      case SearchProviderType.tavily:
        return _searchTavily(query);
    }
  }

  Future<List<SearchResultItem>> _searchSerper(String query) async {
    final payload = await _postJson(
      Uri.parse('https://google.serper.dev/search'),
      headers: {
        'X-API-KEY': apiKey,
      },
      body: {
        'q': query,
        'gl': 'sa',
        'hl': 'ar',
        'num': 5,
      },
    );

    final organic = payload['organic'];
    if (organic is! List) {
      return const [];
    }

    return organic
        .map(
          (item) => SearchResultItem(
            title: _stringValue(item['title']) ?? '',
            link: _stringValue(item['link']) ?? '',
            snippet: _stringValue(item['snippet']) ?? '',
          ),
        )
        .where((item) => item.link.isNotEmpty)
        .toList();
  }

  Future<List<SearchResultItem>> _searchTavily(String query) async {
    final payload = await _postJson(
      Uri.parse('https://api.tavily.com/search'),
      body: {
        'api_key': apiKey,
        'query': query,
        'search_depth': 'advanced',
        'max_results': 5,
        'include_answer': false,
      },
    );

    final results = payload['results'];
    if (results is! List) {
      return const [];
    }

    return results
        .map(
          (item) => SearchResultItem(
            title: _stringValue(item['title']) ?? '',
            link: _stringValue(item['url']) ?? '',
            snippet: _stringValue(item['content']) ?? '',
          ),
        )
        .where((item) => item.link.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri, {
    Map<String, String>? headers,
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unexpected status: ${response.statusCode}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }
}

class SmartSearchDiscoveryResult {
  const SmartSearchDiscoveryResult({
    required this.products,
    this.notice,
  });

  final List<ProductComparison> products;
  final String? notice;
}

class _SmartSearchCandidate {
  const _SmartSearchCandidate({
    required this.name,
    required this.price,
    required this.link,
    required this.hostLabel,
    required this.categoryId,
    required this.categoryLabel,
    required this.detail,
  });

  final String name;
  final double price;
  final String link;
  final String hostLabel;
  final String categoryId;
  final String categoryLabel;
  final String? detail;
}

class SmartSearchDiscoveryService {
  const SmartSearchDiscoveryService();

  Future<SmartSearchDiscoveryResult> discoverComparisons({
    required String query,
    required String selectedCategoryId,
    required List<ProductComparison> existingProducts,
  }) async {
    final normalizedQuery = _normalizeArabic(query);
    if (normalizedQuery.isEmpty) {
      return const SmartSearchDiscoveryResult(products: <ProductComparison>[]);
    }

    final searchClient = SearchAutomationClient.fromConfig();
    if (searchClient == null) {
      return SmartSearchDiscoveryResult(
        products: <ProductComparison>[],
        notice: tr(
          'لتفعيل البحث الذكي من الويب أضف مفتاح Serper أو Tavily عبر --dart-define.',
          'To enable smart web search, add a Serper or Tavily key using --dart-define.',
        ),
      );
    }

    final searchResults = await searchClient.search(
      _buildDiscoveryQuery(
        query: query,
        selectedCategoryId: selectedCategoryId,
      ),
    );

    final candidates = searchResults
        .map(
          (item) => _buildCandidate(
            item,
            query: query,
            selectedCategoryId: selectedCategoryId,
          ),
        )
        .whereType<_SmartSearchCandidate>()
        .toList();

    if (candidates.length < 2) {
      return SmartSearchDiscoveryResult(
        products: <ProductComparison>[],
        notice: tr(
          'لم تتوفر بعد أسعار ويب كافية لتكوين بطاقة مقارنة جديدة، لذلك سنعتمد على القاعدة الحالية أو طلب الإضافة القادم.',
          'There are not enough web prices yet to build a new comparison card, so we will keep using the current database or the next queued request.',
        ),
      );
    }

    final suggestions = _buildSuggestedComparisons(
      query: query,
      candidates: candidates,
      existingProducts: existingProducts,
    );

    if (suggestions.isEmpty) {
      return SmartSearchDiscoveryResult(
        products: <ProductComparison>[],
        notice: tr(
          'نتائج الويب الحالية كانت قريبة من البيانات الموجودة مسبقاً، لذلك لم نضف بطاقة جديدة الآن.',
          'Current web results were too close to existing data, so no new card was added right now.',
        ),
      );
    }

    return SmartSearchDiscoveryResult(
      products: suggestions,
      notice: tr(
        'تم توليد ${suggestions.length} بطاقة ذكية من نتائج الويب حتى لو لم تكن موجودة في قاعدة البيانات.',
        '${suggestions.length} smart cards were generated from web results even though they were not in the database.',
      ),
    );
  }

  String _buildDiscoveryQuery({
    required String query,
    required String selectedCategoryId,
  }) {
    final categoryHint = selectedCategoryId == ProductCategoryCatalog.allId
        ? ''
        : '${ProductCategoryCatalog.lookup(selectedCategoryId).label} ';

    return '$query $categoryHintسعر مكونات السعودية '
        'site:amazon.sa OR site:noon.com OR site:nahdionline.com OR site:al-dawaa.com OR site:hungerstation.com OR site:jahez.net OR site:mrsool.co';
  }

  _SmartSearchCandidate? _buildCandidate(
    SearchResultItem item, {
    required String query,
    required String selectedCategoryId,
  }) {
    final uri = Uri.tryParse(item.link);
    if (uri == null || !uri.hasAuthority) {
      return null;
    }

    final price = _extractPrice(item.title, item.snippet);
    if (price == null || price <= 0) {
      return null;
    }

    final cleanedName = _cleanResultTitle(item.title);
    if (cleanedName.isEmpty) {
      return null;
    }

    final inferredCategoryId = selectedCategoryId == ProductCategoryCatalog.allId
        ? ProductCategoryCatalog.inferId('$query ${item.title} ${item.snippet}')
        : selectedCategoryId;
    final category = ProductCategoryCatalog.lookup(
      inferredCategoryId,
      fallbackLabel: 'مقارنة ذكية',
    );

    return _SmartSearchCandidate(
      name: cleanedName,
      price: price,
      link: item.link,
      hostLabel: _hostLabel(uri.host),
      categoryId: category.id,
      categoryLabel: category.label,
      detail: _extractDetail(item.snippet, category.id),
    );
  }

  List<ProductComparison> _buildSuggestedComparisons({
    required String query,
    required List<_SmartSearchCandidate> candidates,
    required List<ProductComparison> existingProducts,
  }) {
    final sorted = [...candidates]..sort((a, b) => a.price.compareTo(b.price));
    final suggestions = <ProductComparison>[];
    final seenFingerprints = <String>{};
    final rowCount = math.min(2, sorted.length ~/ 2);

    for (var index = 0; index < rowCount; index++) {
      final cheaper = sorted[index];
      final pricier = sorted[sorted.length - 1 - index];

      if (pricier.price <= cheaper.price) {
        continue;
      }

      final pairFingerprint = _normalizeArabic(
        '${pricier.name}|${cheaper.name}|${cheaper.categoryId}',
      );
      if (!seenFingerprints.add(pairFingerprint)) {
        continue;
      }

      final detail = cheaper.detail ?? pricier.detail;
      final suggestion = ProductComparison(
        categoryId: cheaper.categoryId,
        categoryLabel: cheaper.categoryLabel,
        expensiveName: pricier.name,
        expensivePrice: pricier.price,
        expensiveImageUrl: '',
        alternativeName: cheaper.name,
        alternativePrice: cheaper.price,
        alternativeImageUrl: '',
        buyUrl: cheaper.link,
        rating: 0,
        reviewCount: 0,
        tags: [
          cheaper.categoryLabel,
          query,
          'بحث ذكي',
          cheaper.hostLabel,
        ],
        fragranceNotes:
            cheaper.categoryId == 'perfumes' ? detail : null,
        activeIngredients:
            cheaper.categoryId == 'perfumes' ? null : detail,
        localLocationLabel:
            cheaper.categoryId == 'restaurants' ? cheaper.hostLabel : null,
        localLocationUrl:
            cheaper.categoryId == 'restaurants' ? cheaper.link : null,
      );

      if (_isDuplicateSuggestion(suggestion, existingProducts)) {
        continue;
      }

      suggestions.add(suggestion);
    }

    return suggestions;
  }

  bool _isDuplicateSuggestion(
    ProductComparison suggestion,
    List<ProductComparison> existingProducts,
  ) {
    final expensiveToken = _normalizeArabic(suggestion.expensiveName);
    final alternativeToken = _normalizeArabic(suggestion.alternativeName);

    for (final product in existingProducts) {
      if (_normalizeArabic(product.expensiveName) == expensiveToken &&
          _normalizeArabic(product.alternativeName) == alternativeToken) {
        return true;
      }
    }

    return false;
  }

  String _cleanResultTitle(String title) {
    final raw = title.trim();
    if (raw.isEmpty) {
      return '';
    }

    final separators = [' | ', ' - ', ' – ', ' — ', ' • '];
    for (final separator in separators) {
      final index = raw.indexOf(separator);
      if (index > 12) {
        return raw.substring(0, index).trim();
      }
    }

    return raw;
  }

  String? _extractDetail(String snippet, String categoryId) {
    final normalizedSnippet = snippet.trim();
    if (normalizedSnippet.isEmpty) {
      return null;
    }

    final patterns = <RegExp>[
      RegExp(r'(?:المكونات|المادة الفعالة|ingredients?|active ingredients?)[:\-]\s*([^.\n]{12,120})',
          caseSensitive: false),
      RegExp(r'(?:النوتة|النفحات|notes?)[:\-]\s*([^.\n]{12,120})',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(normalizedSnippet);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    if (categoryId == 'perfumes') {
      return _trimWords(normalizedSnippet, wordCount: 8);
    }

    if (categoryId == 'cosmetics' || categoryId == 'pharmacy') {
      return _trimWords(normalizedSnippet, wordCount: 10);
    }

    return null;
  }

  String _trimWords(String text, {required int wordCount}) {
    final words = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(wordCount)
        .toList();
    return words.join(' ');
  }

  String _hostLabel(String host) {
    final normalized = host.toLowerCase();
    if (normalized.contains('amazon')) return 'Amazon.sa';
    if (normalized.contains('noon')) return 'Noon';
    if (normalized.contains('nahdi')) return 'النهدي';
    if (normalized.contains('dawaa')) return 'الدواء';
    if (normalized.contains('hungerstation')) return 'HungerStation';
    if (normalized.contains('jahez')) return 'جاهز';
    if (normalized.contains('mrsool')) return 'مرسول';
    return host;
  }

  double? _extractPrice(String title, String snippet) {
    final text = '$title $snippet'.replaceAll(',', '');
    final patterns = [
      RegExp(
        r'(?:ر\.?\s?س|ريال|SAR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:ر\.?\s?س|ريال|SAR)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '');
      }
    }

    return null;
  }
}

class FirestoreCatalogService {
  const FirestoreCatalogService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      firestore.collection(LeastPriceDataConfig.productsCollectionName);
  CollectionReference<Map<String, dynamic>> get _adBannersCollection =>
      firestore.collection(LeastPriceDataConfig.adBannersCollectionName);
  CollectionReference<Map<String, dynamic>> get _exclusiveDealsCollection =>
      firestore.collection(LeastPriceDataConfig.exclusiveDealsCollectionName);
  CollectionReference<Map<String, dynamic>> get _comparisonSearchCacheCollection =>
      firestore.collection(LeastPriceDataConfig.comparisonSearchCacheCollectionName);
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      firestore.collection(LeastPriceDataConfig.usersCollectionName);
  CollectionReference<Map<String, dynamic>> get _systemHealthCollection =>
      firestore.collection(LeastPriceDataConfig.systemHealthCollectionName);
  CollectionReference<Map<String, dynamic>> get _searchRequestsCollection =>
      firestore.collection(LeastPriceDataConfig.searchRequestsCollectionName);

  Stream<List<AdBannerItem>> watchAdBanners() {
    return _adBannersCollection.snapshots().map((snapshot) {
      final banners = snapshot.docs
          .map(AdBannerItem.fromFirestore)
          .where((banner) => banner.active && banner.imageUrl.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return banners;
    });
  }

  Stream<List<AdBannerItem>> watchAdminAdBanners() {
    return _adBannersCollection.snapshots().map((snapshot) {
      final banners = snapshot.docs.map(AdBannerItem.fromFirestore).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return banners;
    });
  }

  Stream<List<ExclusiveDeal>> watchExclusiveDeals() {
    return _exclusiveDealsCollection.snapshots().map((snapshot) {
      final now = DateTime.now();
      final deals = snapshot.docs
          .map(ExclusiveDeal.fromFirestore)
          .where(
            (deal) =>
                deal.active &&
                !deal.isExpiredAt(now) &&
                deal.title.trim().isNotEmpty &&
                deal.imageUrl.trim().isNotEmpty,
          )
          .toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      return deals;
    });
  }

  Stream<List<ExclusiveDeal>> watchAdminExclusiveDeals() {
    return _exclusiveDealsCollection.snapshots().map((snapshot) {
      final deals = snapshot.docs.map(ExclusiveDeal.fromFirestore).toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      return deals;
    });
  }

  Stream<UserSavingsProfile?> watchUserProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return UserSavingsProfile.fromFirestore(snapshot);
    });
  }

  Stream<AutomationHealthStatus?> watchSystemHealth() {
    return _systemHealthCollection
        .doc(LeastPriceDataConfig.systemHealthDocumentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return AutomationHealthStatus.fromJson(snapshot.data() ?? const {});
    });
  }

  Future<ComparisonSearchCacheEntry?> fetchComparisonSearchCache(
    String query,
  ) async {
    final normalizedQuery = _normalizeArabic(query);
    if (normalizedQuery.length < 2) {
      return null;
    }

    final documentId = _buildComparisonSearchCacheDocumentId(normalizedQuery);
    final snapshot = await _comparisonSearchCacheCollection.doc(documentId).get();
    if (!snapshot.exists) {
      return null;
    }

    return ComparisonSearchCacheEntry.fromJson(snapshot.data() ?? const {});
  }

  Future<void> saveComparisonSearchCache({
    required String query,
    required List<ComparisonSearchResult> results,
  }) async {
    final normalizedQuery = _normalizeArabic(query);
    if (normalizedQuery.length < 2 || results.isEmpty) {
      return;
    }

    final documentId = _buildComparisonSearchCacheDocumentId(normalizedQuery);
    await _comparisonSearchCacheCollection.doc(documentId).set({
      'query': query.trim(),
      'normalizedQuery': normalizedQuery,
      'cachedAt': Timestamp.fromDate(DateTime.now()),
      'results': results.map((result) => result.toJson()).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserSavingsProfile> ensureUserProfile({
    required User user,
    String? pendingInviteCode,
    String? requiredPhoneNumber,
    String? emailAddress,
  }) async {
    final userDocument = _usersCollection.doc(user.uid);
    final snapshot = await userDocument.get();
    final phoneNumber = requiredPhoneNumber?.trim().isNotEmpty == true
        ? requiredPhoneNumber!.trim()
        : (user.phoneNumber?.trim() ?? '');
    final email = emailAddress?.trim().isNotEmpty == true
        ? emailAddress!.trim()
        : (user.email?.trim() ?? '');

    if (snapshot.exists) {
      final currentProfile = UserSavingsProfile.fromFirestore(snapshot);
      String inviteCode = currentProfile.inviteCode;
      if (inviteCode.trim().isEmpty) {
        inviteCode = _buildReferralCodeFromUserId(user.uid);
      }

      await userDocument.set(
        {
          'phoneNumber':
              phoneNumber.isNotEmpty ? phoneNumber : currentProfile.phoneNumber,
          'referralCode': inviteCode,
          if (email.isNotEmpty) 'email': email,
          'shareBaseUrl': currentProfile.shareBaseUrl,
          'inviteMessageTemplate': currentProfile.inviteMessageTemplate,
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return currentProfile.copyWith(
        userId: user.uid,
        phoneNumber:
            phoneNumber.isNotEmpty ? phoneNumber : currentProfile.phoneNumber,
        inviteCode: inviteCode,
      );
    }

    final referralCode = _buildReferralCodeFromUserId(user.uid);
    final normalizedInviteCode = pendingInviteCode?.trim().toUpperCase() ?? '';
    final invitedBy =
        normalizedInviteCode.isNotEmpty && normalizedInviteCode != referralCode
            ? normalizedInviteCode
            : '';

    final profile = UserSavingsProfile(
      userId: user.uid,
      phoneNumber: phoneNumber,
      inviteCode: referralCode,
      invitedBy: invitedBy,
      invitedFriendsCount: 0,
      referralRewardApplied: false,
      shareBaseUrl: LeastPriceDataConfig.appShareUrl,
      inviteMessageTemplate:
          'أنا وفرت {SAVED_AMOUNT} ريال باستخدام تطبيق أرخص سعر! '
          'حمل التطبيق الآن واستخدم كود الدعوة الخاص بي: {USER_CODE}\n{APP_LINK}',
    );

    await userDocument.set(
      {
        ...profile.toFirestoreMap(),
        if (email.isNotEmpty) 'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return profile;
  }

  Stream<List<ProductComparison>> watchProducts({
    String? categoryId,
  }) {
    final normalizedCategoryId = categoryId?.trim() ?? '';
    return _productsCollection.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map(ProductComparison.fromFirestore)
          .where(
            (product) =>
                product.isAutomated &&
                product.expensiveName.trim().isNotEmpty &&
                product.alternativeName.trim().isNotEmpty &&
                (normalizedCategoryId.isEmpty ||
                    normalizedCategoryId == ProductCategoryCatalog.allId ||
                    product.categoryId == normalizedCategoryId),
          )
          .toList()
        ..sort(_sortProducts);

      return products;
    });
  }

  Stream<List<ProductComparison>> watchAllProducts() {
    return watchProducts();
  }

  Future<void> refreshProductsFromServer() async {
    await _productsCollection.get(const GetOptions(source: Source.server));
  }

  Future<void> addProduct(ProductComparison product) async {
    await _productsCollection.add({
      ...product.toFirestoreMap(),
      'is_automated': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveAdBanner(AdBannerItem banner) async {
    final data = {
      ...banner.toFirestoreMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (banner.id.trim().isEmpty) {
      await _adBannersCollection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _adBannersCollection.doc(banner.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> publishAdBanner(String bannerId) async {
    await _adBannersCollection.doc(bannerId).set(
      {
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteAdBanner(String bannerId) async {
    await _adBannersCollection.doc(bannerId).delete();
  }

  Future<void> saveProduct(ProductComparison product) async {
    final data = {
      'expensiveName': product.expensiveName,
      'expensivePrice': product.expensivePrice,
      'expensiveImageUrl': product.expensiveImageUrl,
      'alternativeName': product.alternativeName,
      'alternativePrice': product.alternativePrice,
      'alternativeImageUrl': product.alternativeImageUrl,
      'buyUrl': product.buyUrl.trim().isEmpty
          ? ''
          : AffiliateLinkService.attachAffiliateTag(product.buyUrl),
      'category': product.categoryLabel,
      'categoryId': product.categoryId,
      'is_automated': product.isAutomated,
      'rating': product.rating,
      'reviewCount': product.reviewCount,
      'tags': product.tags,
      'fragranceNotes': product.fragranceNotes ?? '',
      'activeIngredients': product.activeIngredients ?? '',
      'localLocationLabel': product.localLocationLabel ?? '',
      'localLocationUrl': product.localLocationUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    final documentId = product.documentId?.trim() ?? '';
    if (documentId.isEmpty) {
      await _productsCollection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _productsCollection.doc(documentId).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> publishProduct(String documentId) async {
    await _productsCollection.doc(documentId).set(
      {
        'is_automated': true,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveExclusiveDeal(ExclusiveDeal deal) async {
    final data = {
      ...deal.toFirestoreMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (deal.id.trim().isEmpty) {
      await _exclusiveDealsCollection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _exclusiveDealsCollection.doc(deal.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> publishExclusiveDeal(String dealId) async {
    await _exclusiveDealsCollection.doc(dealId).set(
      {
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteExclusiveDeal(String dealId) async {
    await _exclusiveDealsCollection.doc(dealId).delete();
  }

  Future<void> deleteProduct(String documentId) async {
    await _productsCollection.doc(documentId).delete();
  }

  Future<void> submitSearchRequest({
    required String query,
    required String categoryId,
  }) async {
    final trimmedQuery = query.trim();
    final normalizedQuery = _normalizeArabic(trimmedQuery);
    if (normalizedQuery.length < 2) {
      return;
    }

    final normalizedCategoryId = categoryId.trim().isEmpty
        ? ProductCategoryCatalog.allId
        : categoryId.trim();
    final categoryLabel =
        ProductCategoryCatalog.lookup(normalizedCategoryId).label;
    final documentId = _buildSearchRequestDocumentId(
      normalizedQuery: normalizedQuery,
      categoryId: normalizedCategoryId,
    );
    final requestDocument = _searchRequestsCollection.doc(documentId);
    final createPayload = {
      'query': trimmedQuery,
      'normalizedQuery': normalizedQuery,
      'categoryId': normalizedCategoryId,
      'categoryLabel': categoryLabel,
      'requestCount': 1,
      'status': 'pending',
      'source': 'app_search',
      'firstRequestedAt': FieldValue.serverTimestamp(),
      'lastRequestedAt': FieldValue.serverTimestamp(),
    };

    try {
      await requestDocument.update({
        'query': trimmedQuery,
        'normalizedQuery': normalizedQuery,
        'categoryId': normalizedCategoryId,
        'categoryLabel': categoryLabel,
        'requestCount': FieldValue.increment(1),
        'status': 'pending',
        'source': 'app_search',
        'lastRequestedAt': FieldValue.serverTimestamp(),
      });
      return;
    } on FirebaseException catch (error) {
      if (error.code != 'not-found') {
        rethrow;
      }
    }

    await requestDocument.set(createPayload, SetOptions(merge: true));
  }

  Future<void> submitRating(
    ProductComparison product,
    double userRating,
  ) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      throw const FormatException('Missing Firestore document id');
    }

    final document = _productsCollection.doc(documentId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        throw const FormatException('Product does not exist');
      }

      final current = ProductComparison.fromFirestore(snapshot);
      final updated = current.withUserRating(userRating);

      transaction.update(document, {
        'rating': updated.rating,
        'reviewCount': updated.reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  int _sortProducts(ProductComparison a, ProductComparison b) {
    final categoryCompare = a.categoryLabel.compareTo(b.categoryLabel);
    if (categoryCompare != 0) {
      return categoryCompare;
    }

    return b.savingsPercent.compareTo(a.savingsPercent);
  }

  String _buildSearchRequestDocumentId({
    required String normalizedQuery,
    required String categoryId,
  }) {
    return '$categoryId--${normalizedQuery.replaceAll('/', '_')}';
  }

  String _buildComparisonSearchCacheDocumentId(String normalizedQuery) {
    return normalizedQuery.replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]+'), '_');
  }

  String _buildReferralCodeFromUserId(String userId) {
    final normalized = userId
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final padded = normalized.padRight(10, 'X');
    final first = padded.substring(0, 5);
    final second = padded.substring(5, 10);
    return 'LP-$first-$second';
  }
}

class ProductRepository {
  const ProductRepository({
    this.smartMonitorService = const SmartMonitorService(),
  });

  final SmartMonitorService smartMonitorService;

  Future<ProductLoadResult> loadProducts() async {
    String? notice;
    final remoteUrl = LeastPriceDataConfig.remoteJsonUrl.trim();
    final hasConfiguredRemoteUrl = remoteUrl.isNotEmpty &&
        !remoteUrl.contains('your-domain.com');

    if (hasConfiguredRemoteUrl) {
      try {
        final remoteJson = await _fetchRemoteJson(remoteUrl);
        final payload = _parsePayload(remoteJson);
        if (payload.products.isNotEmpty) {
          return ProductLoadResult(
            products: _normalizeLoadedProducts(payload.products),
            source: ProductDataSource.remote,
            referralProfile: payload.referralProfile,
          );
        }
      } catch (_) {
        notice = 'تعذر تحميل أحدث الأسعار من الرابط الخارجي، لذلك تم استخدام مصدر بديل.';
      }
    }

    try {
      final assetJson = await rootBundle.loadString(
        LeastPriceDataConfig.assetJsonPath,
      );
      final payload = _parsePayload(assetJson);
      if (payload.products.isNotEmpty) {
        return ProductLoadResult(
          products: _normalizeLoadedProducts(payload.products),
          source: ProductDataSource.asset,
          referralProfile: payload.referralProfile,
          notice: notice,
        );
      }
    } catch (_) {
      notice ??=
          'لم يتم العثور على ملف JSON خارجي، لذلك تم عرض البيانات التجريبية الحالية.';
    }

    return ProductLoadResult(
      products: _normalizeLoadedProducts(ProductComparison.mockData),
      source: ProductDataSource.mock,
      referralProfile: UserSavingsProfile.initial(),
      notice: notice ??
          'يمكنك لاحقاً ربط التطبيق بملف JSON أو رابط URL لتحديث الأسعار بدون إعادة نشر التطبيق.',
    );
  }

  Future<CatalogRefreshResult> refreshProductCatalog(
    List<ProductComparison> products,
  ) {
    return smartMonitorService.refreshProducts(products);
  }

  Future<String> _fetchRemoteJson(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unexpected status: ${response.statusCode}');
    }

    return response.body;
  }

  ParsedCatalogPayload _parsePayload(String rawJson) {
    final decoded = jsonDecode(rawJson);
    late final List<dynamic> rows;
    UserSavingsProfile? referralProfile;

    if (decoded is List) {
      rows = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final products = decoded['products'];
      if (products is! List) {
        throw const FormatException('Invalid products payload');
      }
      rows = products;

      final referral = decoded['referral'];
      if (referral is Map<String, dynamic>) {
        referralProfile = UserSavingsProfile.fromJson(referral);
      } else if (referral is Map) {
        referralProfile = UserSavingsProfile.fromJson(
          referral.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } else {
      throw const FormatException('Unsupported JSON structure');
    }

    return ParsedCatalogPayload(
      products: rows
          .map((row) => ProductComparison.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
      referralProfile: referralProfile,
    );
  }

  List<ProductComparison> _normalizeLoadedProducts(
    List<ProductComparison> products,
  ) {
    return products
        .map(
          (product) => product.copyWith(
            buyUrl: AffiliateLinkService.attachAffiliateTag(product.buyUrl),
          ),
        )
        .toList();
  }
}

class AdBannerItem {
  const AdBannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.targetUrl,
    required this.storeName,
    required this.active,
    required this.order,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String targetUrl;
  final String storeName;
  final bool active;
  final int order;

  AdBannerItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? targetUrl,
    String? storeName,
    bool? active,
    int? order,
  }) {
    return AdBannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      storeName: storeName ?? this.storeName,
      active: active ?? this.active,
      order: order ?? this.order,
    );
  }

  factory AdBannerItem.fromJson(Map<String, dynamic> json) {
    return AdBannerItem(
      id: _stringValue(json['id']) ?? '',
      title: _stringValue(json['title']) ?? tr('عرض متجر', 'Store offer'),
      subtitle: _stringValue(json['subtitle']) ?? tr(
        'خصومات يومية داخل أرخص سعر',
        'Daily discounts inside LeastPrice',
      ),
      imageUrl: _normalizedImageUrl(
        _stringValue(json['imageUrl']) ?? '',
        fallbackLabel: _stringValue(json['title']) ?? 'LeastPrice Banner',
      ),
      targetUrl: _stringValue(json['targetUrl']) ?? '',
      storeName: _stringValue(json['storeName']) ?? tr('متجر متعاقد', 'Partner store'),
      active: _boolValue(json['active'], defaultValue: true),
      order: _intValue(json['order']),
    );
  }

  factory AdBannerItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return AdBannerItem.fromJson({
      ...?document.data(),
      'id': document.id,
    });
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'storeName': storeName,
      'active': active,
      'order': order,
    };
  }

  static List<AdBannerItem> get mockData => [
    AdBannerItem(
      id: 'local-roaster',
      title: tr('عرض المحمصة المميزة', 'Featured roastery offer'),
      subtitle: tr(
        'خصم على القهوة المختصة وحبوب اليوم مع توصيل سريع.',
        'Discount on specialty coffee and today’s beans with fast delivery.',
      ),
      imageUrl:
          'https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=1400&q=80',
      targetUrl: 'https://leastprice-yaser.web.app/',
      storeName: tr('محمصة الشرقية', 'Eastern Roastery'),
      active: true,
      order: 1,
    ),
    AdBannerItem(
      id: 'restaurant-partner',
      title: tr('وجبات محلية بسعر أفضل', 'Local meals at a better price'),
      subtitle: tr(
        'عروض حصرية من مطاعم الخبر والدمام داخل التطبيق.',
        'Exclusive offers from Khobar and Dammam restaurants inside the app.',
      ),
      imageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1400&q=80',
      targetUrl: 'https://leastprice-yaser.web.app/',
      storeName: tr('شركاء المطاعم', 'Restaurant partners'),
      active: true,
      order: 2,
    ),
  ];
}

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

class ProductCategoryCatalog {
  const ProductCategoryCatalog._();

  static const String allId = 'all';

  static const ProductCategory all = ProductCategory(
    id: allId,
    label: 'الكل',
    icon: Icons.grid_view_rounded,
    color: Color(0xFFE8711A),
  );

  static const List<ProductCategory> defaults = [
    all,
    ProductCategory(
      id: 'coffee',
      label: 'قهوة',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF8C5A2B),
    ),
    ProductCategory(
      id: 'roasters',
      label: 'محامص',
      icon: Icons.coffee_maker_rounded,
      color: Color(0xFFA54E2A),
    ),
    ProductCategory(
      id: 'restaurants',
      label: 'مطاعم',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE85D3F),
    ),
    ProductCategory(
      id: 'perfumes',
      label: 'عطور',
      icon: Icons.spa_rounded,
      color: Color(0xFFB05CC8),
    ),
    ProductCategory(
      id: 'cosmetics',
      label: 'تجميل',
      icon: Icons.face_retouching_natural_rounded,
      color: Color(0xFFE06F8A),
    ),
    ProductCategory(
      id: 'pharmacy',
      label: 'صيدلية',
      icon: Icons.local_pharmacy_rounded,
      color: Color(0xFF2F9E93),
    ),
    ProductCategory(
      id: 'detergents',
      label: 'منظفات',
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF4D7CFE),
    ),
    ProductCategory(
      id: 'dairy',
      label: 'ألبان',
      icon: Icons.local_drink_rounded,
      color: Color(0xFF3FA87B),
    ),
    ProductCategory(
      id: 'canned',
      label: 'معلبات',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF8A6C3F),
    ),
    ProductCategory(
      id: 'tea',
      label: 'شاي',
      icon: Icons.emoji_food_beverage_rounded,
      color: Color(0xFF7B8E2F),
    ),
    ProductCategory(
      id: 'juice',
      label: 'عصير',
      icon: Icons.local_bar_rounded,
      color: Color(0xFFFF8B3D),
    ),
  ];

  static ProductCategory lookup(String id, {String? fallbackLabel}) {
    for (final category in defaults) {
      if (category.id == id) {
        return category;
      }
    }

    return ProductCategory(
      id: id,
      label: fallbackLabel ?? id,
      icon: Icons.category_rounded,
      color: const Color(0xFFE8711A),
    );
  }

  static String inferId(String label) {
    final normalized = _normalizeArabic(label);

    if (normalized.contains('محمص') || normalized.contains('بن') || normalized.contains('حبوب')) {
      return 'roasters';
    }
    if (normalized.contains('قهوه')) return 'coffee';
    if (normalized.contains('مطعم') ||
        normalized.contains('وجبه') ||
        normalized.contains('برجر')) {
      return 'restaurants';
    }
    if (normalized.contains('عطر') ||
        normalized.contains('برفيوم') ||
        normalized.contains('رائحه')) {
      return 'perfumes';
    }
    if (normalized.contains('تجميل') ||
        normalized.contains('سيروم') ||
        normalized.contains('كريم') ||
        normalized.contains('مكياج')) {
      return 'cosmetics';
    }
    if (normalized.contains('صيدلي') ||
        normalized.contains('صيدليه') ||
        normalized.contains('مرطب') ||
        normalized.contains('دواء')) {
      return 'pharmacy';
    }
    if (normalized.contains('منظف') || normalized.contains('تنظيف')) {
      return 'detergents';
    }
    if (normalized.contains('البان') ||
        normalized.contains('لبن') ||
        normalized.contains('حليب') ||
        normalized.contains('جبنه')) {
      return 'dairy';
    }
    if (normalized.contains('معلبات') ||
        normalized.contains('معلب') ||
        normalized.contains('معجون')) {
      return 'canned';
    }
    if (normalized.contains('شاي')) return 'tea';
    if (normalized.contains('عصير')) return 'juice';

    return normalized.replaceAll(' ', '_');
  }
}

class ExclusiveDeal {
  const ExclusiveDeal({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.beforePrice,
    required this.afterPrice,
    required this.expiryDate,
    this.active = true,
  });

  final String id;
  final String title;
  final String imageUrl;
  final double beforePrice;
  final double afterPrice;
  final DateTime expiryDate;
  final bool active;

  double get savingsAmount => beforePrice - afterPrice;

  int get savingsPercent {
    if (beforePrice <= 0) {
      return 0;
    }

    return (((beforePrice - afterPrice) / beforePrice).clamp(0.0, 1.0) * 100)
        .round();
  }

  bool isExpiredAt(DateTime dateTime) => !expiryDate.isAfter(dateTime);

  bool get isExpired => isExpiredAt(DateTime.now());

  ExclusiveDeal copyWith({
    String? id,
    String? title,
    String? imageUrl,
    double? beforePrice,
    double? afterPrice,
    DateTime? expiryDate,
    bool? active,
  }) {
    return ExclusiveDeal(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      beforePrice: beforePrice ?? this.beforePrice,
      afterPrice: afterPrice ?? this.afterPrice,
      expiryDate: expiryDate ?? this.expiryDate,
      active: active ?? this.active,
    );
  }

  factory ExclusiveDeal.fromJson(Map<String, dynamic> json) {
    final expiryDate =
        _dateTimeValue(json['expiry_date'] ?? json['expiryDate']) ??
        DateTime.now().add(const Duration(days: 1));

    return ExclusiveDeal(
      id: _stringValue(json['id']) ?? '',
      title: _stringValue(json['title']) ?? tr('عرض حصري', 'Exclusive deal'),
      imageUrl: _normalizedImageUrl(
        _stringValue(json['imageUrl']) ?? '',
        fallbackLabel: _stringValue(json['title']) ?? 'Exclusive Deal',
      ),
      beforePrice: _doubleValue(json['beforePrice'] ?? json['price_before']),
      afterPrice: _doubleValue(json['afterPrice'] ?? json['price_after']),
      expiryDate: expiryDate,
      active: _boolValue(json['active'], defaultValue: true),
    );
  }

  factory ExclusiveDeal.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return ExclusiveDeal.fromJson({
      ...?document.data(),
      'id': document.id,
    });
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'beforePrice': beforePrice,
      'afterPrice': afterPrice,
      'expiry_date': Timestamp.fromDate(expiryDate),
      'active': active,
    };
  }

  static final List<ExclusiveDeal> mockData = [
    ExclusiveDeal(
      id: 'deal-1',
      title: tr('عرض محمصة نهاية الأسبوع', 'Weekend roastery deal'),
      imageUrl:
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80',
      beforePrice: 42,
      afterPrice: 29,
      expiryDate: DateTime.now().add(const Duration(days: 3)),
    ),
    ExclusiveDeal(
      id: 'deal-2',
      title: tr('عرض عناية يومي من الصيدلية', 'Daily pharmacy care deal'),
      imageUrl:
          'https://images.unsplash.com/photo-1515377905703-c4788e51af15?auto=format&fit=crop&w=900&q=80',
      beforePrice: 79,
      afterPrice: 52,
      expiryDate: DateTime.now().add(const Duration(days: 2)),
    ),
  ];
}

class ProductComparison {
  const ProductComparison({
    this.documentId,
    required this.categoryId,
    required this.categoryLabel,
    required this.expensiveName,
    required this.expensivePrice,
    required this.expensiveImageUrl,
    required this.alternativeName,
    required this.alternativePrice,
    required this.alternativeImageUrl,
    required this.buyUrl,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    this.isAutomated = true,
    this.fragranceNotes,
    this.activeIngredients,
    this.localLocationLabel,
    this.localLocationUrl,
  });

  final String? documentId;
  final String categoryId;
  final String categoryLabel;
  final String expensiveName;
  final double expensivePrice;
  final String expensiveImageUrl;
  final String alternativeName;
  final double alternativePrice;
  final String alternativeImageUrl;
  final String buyUrl;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final bool isAutomated;
  final String? fragranceNotes;
  final String? activeIngredients;
  final String? localLocationLabel;
  final String? localLocationUrl;

  String get uniqueKey => documentId?.trim().isNotEmpty == true
      ? documentId!
      : '$categoryId|$expensiveName|$alternativeName|$buyUrl';

  bool get hasBuyUrl => buyUrl.trim().isNotEmpty;

  bool get hasOriginalOfferTag => tags.any(
        (tag) =>
            _normalizeArabic(tag) ==
            _normalizeArabic(LeastPriceDataConfig.originalOnSaleTag),
      );

  double get savingsAmount => expensivePrice - alternativePrice;

  double get savingsRatio {
    if (expensivePrice <= 0) {
      return 0;
    }

    return ((expensivePrice - alternativePrice) / expensivePrice)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  int get savingsPercent => (savingsRatio * 100).round();

  bool get isSuperSaving => savingsRatio >= 0.40;

  bool get hasDetailHighlights =>
      (fragranceNotes?.trim().isNotEmpty ?? false) ||
      (activeIngredients?.trim().isNotEmpty ?? false);

  bool get hasLocationLink => localLocationUrl?.trim().isNotEmpty ?? false;

  List<String> get searchTokens => [
        categoryLabel,
        expensiveName,
        alternativeName,
        if (fragranceNotes != null) fragranceNotes!,
        if (activeIngredients != null) activeIngredients!,
        if (localLocationLabel != null) localLocationLabel!,
        ...tags,
      ];

  ProductComparison copyWith({
    String? documentId,
    String? categoryId,
    String? categoryLabel,
    String? expensiveName,
    double? expensivePrice,
    String? expensiveImageUrl,
    String? alternativeName,
    double? alternativePrice,
    String? alternativeImageUrl,
    String? buyUrl,
    double? rating,
    int? reviewCount,
    List<String>? tags,
    bool? isAutomated,
    String? fragranceNotes,
    String? activeIngredients,
    String? localLocationLabel,
    String? localLocationUrl,
  }) {
    return ProductComparison(
      documentId: documentId ?? this.documentId,
      categoryId: categoryId ?? this.categoryId,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      expensiveName: expensiveName ?? this.expensiveName,
      expensivePrice: expensivePrice ?? this.expensivePrice,
      expensiveImageUrl: expensiveImageUrl ?? this.expensiveImageUrl,
      alternativeName: alternativeName ?? this.alternativeName,
      alternativePrice: alternativePrice ?? this.alternativePrice,
      alternativeImageUrl: alternativeImageUrl ?? this.alternativeImageUrl,
      buyUrl: buyUrl ?? this.buyUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      tags: tags ?? this.tags,
      isAutomated: isAutomated ?? this.isAutomated,
      fragranceNotes: fragranceNotes ?? this.fragranceNotes,
      activeIngredients: activeIngredients ?? this.activeIngredients,
      localLocationLabel: localLocationLabel ?? this.localLocationLabel,
      localLocationUrl: localLocationUrl ?? this.localLocationUrl,
    );
  }

  ProductComparison withUserRating(double userRating) {
    final totalReviews = reviewCount + 1;
    final newAverage = reviewCount <= 0
        ? userRating
        : ((rating * reviewCount) + userRating) / totalReviews;

    return copyWith(
      rating: newAverage.clamp(0.0, 5.0).toDouble(),
      reviewCount: totalReviews,
    );
  }

  factory ProductComparison.fromJson(Map<String, dynamic> json) {
    final expensive = _asMap(json['expensive']);
    final alternative = _asMap(json['alternative']);

    final categoryLabel =
        _stringValue(json['categoryLabel'] ?? json['category']) ??
        tr('أخرى', 'Other');
    final expensiveName =
        _stringValue(json['expensiveName'] ?? expensive['name']) ??
            tr('منتج مرتفع السعر', 'Higher-priced product');
    final alternativeName =
        _stringValue(json['alternativeName'] ?? alternative['name']) ??
            tr('الخيار الاقتصادي', 'Best-value option');
    final normalizedTags = _stringListValue(json['tags']);

    return ProductComparison(
      documentId: _stringValue(json['documentId'] ?? json['id']),
      categoryId: _stringValue(json['categoryId'])?.trim().isNotEmpty == true
          ? _stringValue(json['categoryId'])!.trim()
          : ProductCategoryCatalog.inferId(categoryLabel),
      categoryLabel: categoryLabel,
      expensiveName: expensiveName,
      expensivePrice: _doubleValue(json['expensivePrice'] ?? expensive['price']),
      expensiveImageUrl: _normalizedImageUrl(
        _stringValue(json['expensiveImageUrl'] ?? expensive['imageUrl']) ?? '',
        fallbackLabel: expensiveName,
      ),
      alternativeName: alternativeName,
      alternativePrice:
          _doubleValue(json['alternativePrice'] ?? alternative['price']),
      alternativeImageUrl: _normalizedImageUrl(
        _stringValue(json['alternativeImageUrl'] ?? alternative['imageUrl']) ??
            '',
        fallbackLabel: alternativeName,
      ),
      buyUrl: AffiliateLinkService.attachAffiliateTag(
        _stringValue(json['buyUrl']) ?? '',
      ),
      rating: _doubleValue(json['rating']),
      reviewCount: _intValue(json['reviewCount']),
      isAutomated: _boolValue(json['is_automated'], defaultValue: true),
      tags: normalizedTags.isNotEmpty
          ? normalizedTags
          : [
              categoryLabel,
              expensiveName,
              alternativeName,
            ],
      fragranceNotes: _stringValue(json['fragranceNotes']),
      activeIngredients: _stringValue(json['activeIngredients']),
      localLocationLabel: _stringValue(json['localLocationLabel']),
      localLocationUrl: _stringValue(json['localLocationUrl']),
    );
  }

  factory ProductComparison.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return ProductComparison.fromJson({
      ...?document.data(),
      'documentId': document.id,
    });
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'expensiveName': expensiveName,
      'expensivePrice': expensivePrice,
      'alternativeName': alternativeName,
      'alternativePrice': alternativePrice,
      'category': categoryLabel,
      'is_automated': isAutomated,
      if (buyUrl.trim().isNotEmpty)
        'buyUrl': AffiliateLinkService.attachAffiliateTag(buyUrl),
      'rating': rating,
      if (reviewCount > 0) 'reviewCount': reviewCount,
      if (tags.isNotEmpty) 'tags': tags,
      if (categoryId.trim().isNotEmpty) 'categoryId': categoryId,
      if (expensiveImageUrl.trim().isNotEmpty)
        'expensiveImageUrl': expensiveImageUrl,
      if (alternativeImageUrl.trim().isNotEmpty)
        'alternativeImageUrl': alternativeImageUrl,
      if (fragranceNotes != null && fragranceNotes!.trim().isNotEmpty)
        'fragranceNotes': fragranceNotes,
      if (activeIngredients != null && activeIngredients!.trim().isNotEmpty)
        'activeIngredients': activeIngredients,
      if (localLocationLabel != null && localLocationLabel!.trim().isNotEmpty)
        'localLocationLabel': localLocationLabel,
      if (localLocationUrl != null && localLocationUrl!.trim().isNotEmpty)
        'localLocationUrl': localLocationUrl,
    };
  }

  static final List<ProductComparison> mockData = [
    const ProductComparison(
      categoryId: 'coffee',
      categoryLabel: 'قهوة',
      expensiveName: 'نسكافيه جولد 200 جم',
      expensivePrice: 48.95,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'قهوة باجة السعودية 250 جم',
      alternativePrice: 24.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80',
      buyUrl:
          'https://www.amazon.sa/s?k=%D9%82%D9%87%D9%88%D8%A9+%D8%A8%D8%A7%D8%AC%D8%A9',
      rating: 4.6,
      reviewCount: 184,
      tags: ['نسكافيه', 'باجة', 'قهوة فورية', 'مشروبات ساخنة'],
    ),
    const ProductComparison(
      categoryId: 'detergents',
      categoryLabel: 'منظفات',
      expensiveName: 'فيري سائل جلي 1 لتر',
      expensivePrice: 17.50,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1583947582886-f40ec95dd752?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'هوم كير سائل جلي اقتصادي 1 لتر',
      alternativePrice: 9.25,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=dishwashing%20liquid',
      rating: 4.2,
      reviewCount: 91,
      tags: ['تنظيف', 'جلي', 'مطبخ', 'أفضل قيمة'],
    ),
    const ProductComparison(
      categoryId: 'dairy',
      categoryLabel: 'ألبان',
      expensiveName: 'جبنة كرافت شرائح 400 جم',
      expensivePrice: 21.95,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'جبنة المراعي شرائح 400 جم',
      alternativePrice: 13.95,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1452195100486-9cc805987862?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=%D8%AC%D8%A8%D9%86%D8%A9+%D8%A7%D9%84%D9%85%D8%B1%D8%A7%D8%B9%D9%8A',
      rating: 4.4,
      reviewCount: 132,
      tags: ['جبنة', 'كرافت', 'المراعي', 'إفطار'],
    ),
    const ProductComparison(
      categoryId: 'canned',
      categoryLabel: 'معلبات',
      expensiveName: 'معجون طماطم هاينز 8 عبوات',
      expensivePrice: 18.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1515003197210-e0cd71810b5f?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'معجون طماطم قودي 8 عبوات',
      alternativePrice: 10.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1576867757603-05b134ebc379?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=goody+tomato+paste',
      rating: 4.5,
      reviewCount: 88,
      tags: ['هاينز', 'قودي', 'طبخ', 'طماطم'],
    ),
    const ProductComparison(
      categoryId: 'tea',
      categoryLabel: 'شاي',
      expensiveName: 'شاي ليبتون 100 كيس',
      expensivePrice: 29.95,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'شاي ربيع 100 كيس',
      alternativePrice: 17.25,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=rabea%20tea',
      rating: 4.8,
      reviewCount: 240,
      tags: ['ليبتون', 'ربيع', 'شاي سعودي', 'مشروب ساخن'],
    ),
    const ProductComparison(
      categoryId: 'restaurants',
      categoryLabel: 'مطاعم',
      expensiveName: 'وجبة برجر مرجعية',
      expensivePrice: 26.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'برجر مدخن من مطعم برجر الشرقية - الخبر',
      alternativePrice: 18.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.hungerstation.com/sa-en',
      rating: 4.9,
      reviewCount: 278,
      tags: ['بيج ماك', 'برجر', 'الخبر', 'مطعم مميز', 'الشرقية'],
      localLocationLabel: 'الخبر - طريق الأمير تركي - مطعم برجر الشرقية',
      localLocationUrl: 'https://maps.google.com/?q=Khobar+burger+restaurant',
    ),
    const ProductComparison(
      categoryId: 'restaurants',
      categoryLabel: 'مطاعم',
      expensiveName: 'ساندوتش كرسبي مرجعي',
      expensivePrice: 24.50,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1520072959219-c595dc870360?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'كرسبي دجاج من مطعم أهل الخبر',
      alternativePrice: 16.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1606755962773-d324e0a13086?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://jahez.net',
      rating: 4.7,
      reviewCount: 163,
      tags: ['كرسبي', 'دجاج', 'مطاعم الخبر', 'أفضل قيمة'],
      localLocationLabel: 'الخبر - حي الحزام الذهبي - مطعم أهل الخبر',
      localLocationUrl: 'https://maps.google.com/?q=Khobar+crispy+chicken',
    ),
    const ProductComparison(
      categoryId: 'restaurants',
      categoryLabel: 'مطاعم',
      expensiveName: 'آيس لاتيه مرجعي',
      expensivePrice: 21.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'آيس لاتيه من مقهى شرقي',
      alternativePrice: 13.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://mrsool.co',
      rating: 4.8,
      reviewCount: 121,
      tags: ['قهوة باردة', 'مقهى مميز', 'لاتيه', 'الشرقية'],
      localLocationLabel: 'الخبر - الكورنيش - مقهى شرقي',
      localLocationUrl: 'https://maps.google.com/?q=Khobar+coffee+shop',
    ),
    const ProductComparison(
      categoryId: 'perfumes',
      categoryLabel: 'عطور',
      expensiveName: 'Dior Sauvage Eau de Parfum',
      expensivePrice: 520.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'بديل سافاج من نخبة العود',
      alternativePrice: 189.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=sauvage+alternative',
      rating: 4.9,
      reviewCount: 312,
      tags: ['سافاج', 'نخبة العود', 'براند سعودي', 'بديل عطري'],
      fragranceNotes: 'برغموت، فلفل سيشوان، أمبروكسان، لمسة خشبية منعشة',
    ),
    const ProductComparison(
      categoryId: 'perfumes',
      categoryLabel: 'عطور',
      expensiveName: 'Baccarat Rouge 540',
      expensivePrice: 1210.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1523293182086-7651a899d37f?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'بديل بنفس الرائحة من العربية للعود',
      alternativePrice: 245.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1616949755610-8c9bbc08f138?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=arabian+oud+perfume',
      rating: 4.8,
      reviewCount: 204,
      tags: ['بكارات', 'العربية للعود', 'عود', 'عنبر'],
      fragranceNotes: 'زعفران، ياسمين، عنبر، أخشاب دافئة وسكر محروق',
    ),
    const ProductComparison(
      categoryId: 'perfumes',
      categoryLabel: 'عطور',
      expensiveName: 'Chanel Coco Mademoiselle',
      expensivePrice: 615.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1594035910387-fea47794261f?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'بديل فلورال من إبراهيم القرشي',
      alternativePrice: 210.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1588405748880-12d1d2a59df9?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=ibrahim+alqurashi+perfume',
      rating: 4.7,
      reviewCount: 177,
      tags: ['شانيل', 'إبراهيم القرشي', 'فلورال', 'مسك'],
      fragranceNotes: 'برتقال، ورد تركي، باتشولي، مسك أبيض',
    ),
    const ProductComparison(
      categoryId: 'cosmetics',
      categoryLabel: 'تجميل',
      expensiveName: 'The Ordinary Niacinamide 10% Serum',
      expensivePrice: 69.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'سيروم نياسيناميد من لاب سعودي',
      alternativePrice: 34.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1625772452859-1c03d5bf1137?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=niacinamide+serum',
      rating: 4.6,
      reviewCount: 143,
      tags: ['نياسيناميد', 'سيروم', 'بشرة', 'أفضل قيمة'],
      activeIngredients: 'Niacinamide 10% + Zinc PCA لتنظيم الدهون وتقليل مظهر المسام',
    ),
    const ProductComparison(
      categoryId: 'cosmetics',
      categoryLabel: 'تجميل',
      expensiveName: 'La Roche-Posay Vitamin C Serum',
      expensivePrice: 220.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1570194065650-d99fb4d8a5c8?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'سيروم فيتامين C من براند سعودي للعناية',
      alternativePrice: 96.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=vitamin+c+serum',
      rating: 4.5,
      reviewCount: 109,
      tags: ['فيتامين سي', 'سيروم', 'نضارة', 'مكونات فعالة'],
      activeIngredients: 'Vitamin C + Hyaluronic Acid + Vitamin E لإشراقة وترطيب أعمق',
    ),
    const ProductComparison(
      categoryId: 'cosmetics',
      categoryLabel: 'تجميل',
      expensiveName: 'Maybelline Fit Me Concealer',
      expensivePrice: 58.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1631730486782-d5a6bdf9a7ec?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'كونسيلر اقتصادي بتغطية خفيفة من بوتيك سعودي',
      alternativePrice: 27.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=concealer',
      rating: 4.4,
      reviewCount: 86,
      tags: ['كونسيلر', 'مكياج', 'تغطية', 'أفضل قيمة'],
      activeIngredients: 'Pigment blend + Glycerin لترطيب خفيف وثبات يومي',
    ),
    const ProductComparison(
      categoryId: 'pharmacy',
      categoryLabel: 'صيدلية',
      expensiveName: 'CeraVe Moisturizing Cream',
      expensivePrice: 89.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1556228578-dd6c36f7737d?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'مرطب اقتصادي من الصيدلية',
      alternativePrice: 44.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1617897903246-719242758050?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.nahdionline.com',
      rating: 4.7,
      reviewCount: 221,
      tags: ['سيرافي', 'مرطب', 'نهدي', 'اقتصادي'],
      activeIngredients: 'سيراميدات + هيالورونيك أسيد + بانثينول لدعم حاجز البشرة',
    ),
    const ProductComparison(
      categoryId: 'pharmacy',
      categoryLabel: 'صيدلية',
      expensiveName: 'Panadol Cold & Flu',
      expensivePrice: 24.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'خيار اقتصادي لنزلات البرد',
      alternativePrice: 14.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.al-dawaa.com',
      rating: 4.3,
      reviewCount: 75,
      tags: ['بانادول', 'برد', 'صيدلية', 'دواء'],
      activeIngredients: 'باراسيتامول + مزيل احتقان بتركيبة اقتصادية مشابهة',
    ),
  ];
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  return const {};
}

String? _stringValue(Object? value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _sameStringLists(List<String> first, List<String> second) {
  if (identical(first, second)) {
    return true;
  }

  if (first.length != second.length) {
    return false;
  }

  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }

  return true;
}

double _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.trim()) ?? 0;
  }

  return 0;
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }

  return 0;
}

bool _boolValue(Object? value, {bool defaultValue = false}) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }

  return defaultValue;
}

List<String> _stringListValue(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String? _mergeNotices(String? current, String? incoming) {
  final parts = <String>{
    if (current != null && current.trim().isNotEmpty) current.trim(),
    if (incoming != null && incoming.trim().isNotEmpty) incoming.trim(),
  };

  if (parts.isEmpty) {
    return null;
  }

  return parts.join(' ');
}

String formatPrice(double price) {
  return '${formatAmountValue(price)} ${tr('ر.س', 'SAR')}';
}

String formatAmountValue(double amount) {
  final hasFraction = amount != amount.roundToDouble();
  return hasFraction ? amount.toStringAsFixed(2) : amount.toStringAsFixed(0);
}

double? _extractMarketplacePrice(String text) {
  final normalized = text.replaceAll(',', '').trim();
  if (normalized.isEmpty) {
    return null;
  }

  final patterns = <RegExp>[
    RegExp(
      r'(?:ر\.?\s?س|ريال|SAR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ),
    RegExp(
      r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:ر\.?\s?س|ريال|SAR)',
      caseSensitive: false,
    ),
    RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(normalized);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
  }

  return null;
}

String _normalizeArabic(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[^0-9a-zA-Z\u0600-\u06FF\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
