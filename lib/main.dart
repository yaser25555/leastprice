import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

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
        'ØªØ¹Ø°Ø± ØªÙ‡ÙŠØ¦Ø© Firebase Ø­Ø§Ù„ÙŠØ§Ù‹. ØªØ£ÙƒØ¯ Ù…Ù† Ø§ÙƒØªÙ…Ø§Ù„ Ù…Ù„ÙØ§Øª FlutterFire ÙˆØ¥Ø¹Ø¯Ø§Ø¯ Ù…Ø´Ø±ÙˆØ¹ Firebase Ø¹Ù„Ù‰ Ø§Ù„Ù…Ù†ØµØ© Ø§Ù„Ø­Ø§Ù„ÙŠØ©.';
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
    const navy = Color(0xFF1B2F5E);
    const orange = Color(0xFFE8711A);

    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.light,
    ).copyWith(
      primary: orange,
      secondary: navy,
      surface: Colors.white,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ø£Ø±Ø®Øµ Ø³Ø¹Ø± - LeastPrice',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
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
            borderSide: const BorderSide(color: Color(0xFFFFDEB8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: orange, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
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
            foregroundColor: orange,
            side: const BorderSide(color: Color(0xFFFFCB99)),
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
          textDirection: TextDirection.rtl,
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
      textDirection: TextDirection.rtl,
      child: Material(
        color: const Color(0xFFF5FBF8),
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
                      color: Color(0x140C3B2E),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFD14B4B),
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ Ø¨Ù†Ø§Ø¡ Ø§Ù„ÙˆØ§Ø¬Ù‡Ø©',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF17332B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ø¨Ø¯Ù„Ø§Ù‹ Ù…Ù† Ø§Ù„ØµÙØ­Ø© Ø§Ù„Ø¨ÙŠØ¶Ø§Ø¡ØŒ ÙŠØ¹Ø±Ø¶ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¢Ù† Ø³Ø¨Ø¨ Ø§Ù„Ø®Ø·Ø£ Ù„ÙŠØ³Ù‡Ù„ Ø¹Ù„ÙŠÙ†Ø§ Ø¥ØµÙ„Ø§Ø­Ù‡ Ø¨Ø³Ø±Ø¹Ø©.',
                      style: TextStyle(
                        color: Color(0xFF61756D),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2EBE7)),
                      ),
                      child: SelectableText(
                        details.exceptionAsString(),
                        style: const TextStyle(
                          color: Color(0xFF24443B),
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      details.library ?? 'Flutter',
                      style: const TextStyle(
                        color: Color(0xFF7B8E86),
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
          return const _AuthLoadingScreen(
            title: 'Ø¬Ø§Ø±Ù ØªØ¬Ù‡ÙŠØ² Ø­Ø³Ø§Ø¨Ùƒ',
            message: 'Ù†Ø±Ø¨Ø· Ù…Ù„ÙÙƒ Ø§Ù„Ø´Ø®ØµÙŠ ÙˆØ§Ù„Ø¯Ø¹ÙˆØ§Øª ÙˆØ§Ù„Ø¹Ø±ÙˆØ¶ Ù‚Ø¨Ù„ ÙØªØ­ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚.',
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _AuthBootstrapErrorScreen(
            message: 'ØªØ¹Ø°Ø± ØªØ¬Ù‡ÙŠØ² Ù…Ù„Ù Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… Ù…Ù† Firestore. ØªØ£ÙƒØ¯ Ù…Ù† Ø§Ù„Ø§ØªØµØ§Ù„ Ø«Ù… Ø¬Ø±Ù‘Ø¨ Ù…Ø±Ø© Ø£Ø®Ø±Ù‰.',
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
          return const _AuthLoadingScreen(
            title: 'Ø¬Ø§Ø±Ù ØªØ¬Ù‡ÙŠØ² Ù„ÙˆØ­Ø© Ø§Ù„ØªØ­ÙƒÙ…',
            message: 'Ù†Ø±Ø¨Ø· Ù„ÙˆØ­Ø© Ø§Ù„Ø¥Ø¯Ø§Ø±Ø© Ø¨Ø®Ø¯Ù…Ø§Øª Firebase ÙˆÙ†Ø¬Ù‡Ø² ØµÙ„Ø§Ø­ÙŠØ§Øª Ø§Ù„Ù…Ø´Ø±Ù.',
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
        _statusMessage = 'Ø£Ø¯Ø®Ù„ Ø¨Ø±ÙŠØ¯ Ø§Ù„Ù…Ø´Ø±Ù Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ø¨ØµÙŠØºØ© ØµØ­ÙŠØ­Ø©.';
      });
      return;
    }

    if (!_isAllowedAdminEmail(normalizedEmail)) {
      setState(() {
        _statusMessage =
            'Ù‡Ø°Ù‡ Ø§Ù„Ù„ÙˆØ­Ø© Ù…Ù‚ÙŠØ¯Ø© Ø¨Ø¨Ø±ÙŠØ¯ Ø§Ù„Ù…Ø´Ø±Ù ${LeastPriceDataConfig.adminEmail} ÙÙ‚Ø·.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _statusMessage = 'Ø£Ø¯Ø®Ù„ ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ù„Ù„Ù…ØªØ§Ø¨Ø¹Ø©.';
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
        _statusMessage = 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø¯Ø®ÙˆÙ„ Ø§Ù„Ù…Ø´Ø±Ù Ø¨Ù†Ø¬Ø§Ø­.';
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
        _statusMessage = 'ØªØ¹Ø°Ø± ÙØªØ­ Ù„ÙˆØ­Ø© Ø§Ù„ØªØ­ÙƒÙ… Ø­Ø§Ù„ÙŠØ§Ù‹: $error';
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
                    color: Color(0x140C3B2E),
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
                    Icons.dashboard_customize_rounded,
                    size: 52,
                    color: Color(0xFFE8711A),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ù„ÙˆØ­Ø© ØªØ­ÙƒÙ… LeastPrice',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ø³Ø¬Ù‘Ù„ Ø¨Ø¨Ø±ÙŠØ¯ Ø§Ù„Ù…Ø´Ø±Ù Ù„Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ø¨Ù†Ø±Ø§Øª ÙˆØ§Ù„Ù…Ù†ØªØ¬Ø§Øª Ù…Ø¨Ø§Ø´Ø±Ø© Ù…Ù† Ø§Ù„Ù…ØªØµÙØ­. Ù‡Ø°Ù‡ Ø§Ù„Ù„ÙˆØ­Ø© Ù…Ø­Ù…ÙŠØ© Ø¨Ø¨Ø±ÙŠØ¯ ${LeastPriceDataConfig.adminEmail}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF61756D),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Ø¨Ø±ÙŠØ¯ Ø§Ù„Ù…Ø´Ø±Ù',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±',
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
                      _isSubmitting ? 'Ø¬Ø§Ø±Ù Ø§Ù„Ø¯Ø®ÙˆÙ„...' : 'Ø¯Ø®ÙˆÙ„ Ø§Ù„Ù…Ø´Ø±Ù',
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
                    color: Color(0x140C3B2E),
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
                  const Text(
                    'Ù‡Ø°Ø§ Ø§Ù„Ø­Ø³Ø§Ø¨ Ù„ÙŠØ³ Ù…Ø´Ø±ÙØ§Ù‹',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø­Ø§Ù„ÙŠ Ù‡Ùˆ ${user.email ?? 'ØºÙŠØ± Ù…Ø¹Ø±ÙˆÙ'}ØŒ Ø¨ÙŠÙ†Ù…Ø§ Ø§Ù„Ù„ÙˆØ­Ø© Ù…Ø³Ù…ÙˆØ­Ø© ÙÙ‚Ø· Ù„Ù„Ø¨Ø±ÙŠØ¯ ${LeastPriceDataConfig.adminEmail}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF61756D),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø®Ø±ÙˆØ¬'),
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
            const Text(
              'Ù„ÙˆØ­Ø© ØªØ­ÙƒÙ… LeastPrice',
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
            label: const Text('Ø®Ø±ÙˆØ¬'),
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
    _tabController = TabController(length: 2, vsync: this);
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
            tabs: const [
              Tab(icon: Icon(Icons.view_carousel_rounded), text: 'Ø§Ù„Ø¨Ù†Ø±Ø§Øª'),
              Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AdminSimpleBannersPanel(service: widget.service),
              _AdminSimpleProductsPanel(service: widget.service),
            ],
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Ù„ÙˆØ­Ø© Ø§Ù„Ø¨Ù†Ø±Ø§Øª Ø§Ù„Ø¨Ø³ÙŠØ·Ø© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          const SnackBar(content: Text('ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ø¨Ù†Ø± Ø¨Ù†Ø¬Ø§Ø­.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ø®Ø·Ø£: $e')));
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
          const SnackBar(content: Text('ØªÙ… ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø¨Ù†Ø± Ø¨Ù†Ø¬Ø§Ø­.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ø®Ø·Ø£: $e')));
      }
    }
  }

  Future<void> _delete(AdBannerItem banner) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø±'),
            content: Text('Ù‡Ù„ ØªØ±ÙŠØ¯ Ø­Ø°Ù "${banner.title}"ØŸ'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Ø¥Ù„ØºØ§Ø¡')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ø­Ø°Ù')),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    try {
      await widget.service.deleteAdBanner(banner.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ØªÙ… Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø±.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ø®Ø·Ø£: $e')));
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
          const SnackBar(content: Text('ØªÙ… Ù†Ø´Ø± Ø§Ù„Ø¨Ù†Ø±Ø§Øª Ø§Ù„ØªØ¬Ø±ÙŠØ¨ÙŠØ© ÙÙŠ Firestore.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ù†Ø´Ø±: $e')));
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
            isMock ? 'ðŸ“¦ ØªØ¬Ø±ÙŠØ¨ÙŠ â€” ${b.storeName}' : b.storeName,
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
                                Text('ØªÙ… Ù†Ø´Ø± "${b.title}" ÙÙŠ Firestore.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ø®Ø·Ø£: $e')));
                    }
                  }
                },
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text('Ù†Ø´Ø±'),
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
                      'Ø§Ù„Ø¨Ù†Ø±Ø§Øª Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†ÙŠØ©',
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
                            label: const Text('Ù†Ø´Ø± Ø§Ù„ÙƒÙ„ ÙÙŠ Firestore'),
                          ),
                        if (isMock) const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _add,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Ø¥Ø¶Ø§ÙØ© Ø¨Ù†Ø±'),
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
                          'Firestore ÙØ§Ø±ØºØ© â€” ØªØ¹Ø±Ø¶ Ø§Ù„Ø¨Ù†Ø±Ø§Øª Ø§Ù„ØªØ¬Ø±ÙŠØ¨ÙŠØ©. Ø§Ø¶ØºØ· "Ù†Ø´Ø±" Ù„Ø­ÙØ¸Ù‡Ø§.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Ø®Ø·Ø£: ${snap.error}',
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
        label: const Text('Ø¥Ø¶Ø§ÙØ© Ø¨Ù†Ø±'),
      ),
    );
  }
}

// â”€â”€â”€ Ù„ÙˆØ­Ø© Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª Ø§Ù„Ø¨Ø³ÙŠØ·Ø© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          const SnackBar(content: Text('ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ù…Ù†ØªØ¬ Ø¨Ù†Ø¬Ø§Ø­.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ø®Ø·Ø£: $e')));
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
          const SnackBar(content: Text('ØªÙ… ØªØ­Ø¯ÙŠØ« Ø§Ù„Ù…Ù†ØªØ¬ Ø¨Ù†Ø¬Ø§Ø­.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ø®Ø·Ø£: $e')));
      }
    }
  }

  Future<void> _delete(ProductComparison product) async {
    final docId = product.documentId;
    if (docId == null) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Ø­Ø°Ù Ø§Ù„Ù…Ù†ØªØ¬'),
            content: Text('Ù‡Ù„ ØªØ±ÙŠØ¯ Ø­Ø°Ù "${product.expensiveName}"ØŸ'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Ø¥Ù„ØºØ§Ø¡')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ø­Ø°Ù')),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    try {
      await widget.service.deleteProduct(docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ØªÙ… Ø­Ø°Ù Ø§Ù„Ù…Ù†ØªØ¬.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ø®Ø·Ø£: $e')));
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
          const SnackBar(content: Text('ØªÙ… Ù†Ø´Ø± Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª Ø§Ù„ØªØ¬Ø±ÙŠØ¨ÙŠØ© ÙÙŠ Firestore.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ù†Ø´Ø±: $e')));
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
            p.categoryLabel.isNotEmpty ? p.categoryLabel[0] : 'ØŸ',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          '${p.expensiveName}  â†’  ${p.alternativeName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          isMock
              ? 'ðŸ“¦ ØªØ¬Ø±ÙŠØ¨ÙŠ â€” ${p.categoryLabel} | ${p.expensivePrice} Ø±.Ø³  â†’  ${p.alternativePrice} Ø±.Ø³'
              : '${p.categoryLabel} | ${p.expensivePrice} Ø±.Ø³  â†’  ${p.alternativePrice} Ø±.Ø³',
          style: TextStyle(color: isMock ? Colors.orange[800] : null),
        ),
        trailing: isMock
            ? ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await widget.service.saveProduct(p);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ØªÙ… Ù†Ø´Ø± "${p.expensiveName}".')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Ø®Ø·Ø£: $e')));
                    }
                  }
                },
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text('Ù†Ø´Ø±'),
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
                      'Ø¨Ø·Ø§Ù‚Ø§Øª Ø§Ù„Ù…Ù‚Ø§Ø±Ù†Ø©',
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
                            label: const Text('Ù†Ø´Ø± Ø§Ù„ÙƒÙ„ ÙÙŠ Firestore'),
                          ),
                        if (isMock) const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _add,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Ø¥Ø¶Ø§ÙØ© Ù…Ù†ØªØ¬'),
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
                          'Firestore ÙØ§Ø±ØºØ© â€” ØªØ¹Ø±Ø¶ Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª Ø§Ù„ØªØ¬Ø±ÙŠØ¨ÙŠØ©. Ø§Ø¶ØºØ· "Ù†Ø´Ø±" Ù„Ø­ÙØ¸Ù‡Ø§.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Ø®Ø·Ø£: ${snap.error}',
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
        label: const Text('Ø¥Ø¶Ø§ÙØ© Ù…Ù†ØªØ¬'),
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
              'Ù„ÙˆØ­Ø© ØªØ­ÙƒÙ… LeastPrice',
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
            label: const Text('Ø®Ø±ÙˆØ¬'),
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
                ? 'ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ø¨Ù†Ø± Ø¨Ù†Ø¬Ø§Ø­.'
                : 'ØªÙ… ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø¨Ù†Ø± Ø¨Ù†Ø¬Ø§Ø­.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­ÙØ¸ Ø§Ù„Ø¨Ù†Ø± Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
      );
    }
  }

  Future<void> _publishBanner(AdBannerItem banner) async {
    try {
      await widget.catalogService.publishAdBanner(banner.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ØªÙ… ØªØ­Ø¯ÙŠØ« lastUpdated Ù„Ù„Ø¨Ù†Ø± Ø¨Ù†Ø¬Ø§Ø­.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ù†Ø´Ø± Ø§Ù„Ø¨Ù†Ø± Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
      );
    }
  }

  Future<void> _deleteBanner(AdBannerItem banner) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø±'),
            content: Text('Ù‡Ù„ ØªØ±ÙŠØ¯ Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø± "${banner.title}" Ù†Ù‡Ø§Ø¦ÙŠØ§Ù‹ØŸ'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ø¥Ù„ØºØ§Ø¡'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ø­Ø°Ù'),
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
        const SnackBar(content: Text('ØªÙ… Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø±.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø± Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
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
                    'Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ø¨Ù†Ø±Ø§Øª Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†ÙŠØ©',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ø£Ø¶Ù Ø£Ùˆ Ø¹Ø¯Ù‘Ù„ Ø£Ùˆ Ø§Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø±Ø§Øª ÙÙŠ ad_banners Ù…Ø¹ Ù†Ø´Ø± Ø§Ù„ØªØ­Ø¯ÙŠØ« ÙÙˆØ±Ø§Ù‹ Ù„Ù„Ù…Ø³ØªØ®Ø¯Ù…ÙŠÙ†.',
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
              label: const Text('Ø¥Ø¶Ø§ÙØ© Ø¨Ù†Ø±'),
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
                    'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¨Ù†Ø±Ø§Øª Ù…Ù† Firestore: ${snapshot.error}',
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
                    'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø¨Ù†Ø±Ø§Øª Ø¨Ø¹Ø¯. Ø£Ø¶Ù Ø£ÙˆÙ„ Ø¨Ù†Ø± Ù…Ù† Ø§Ù„Ø²Ø± Ø§Ù„Ø¹Ù„ÙˆÙŠ.',
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
                                      label: banner.active ? 'Ù†Ø´Ø·' : 'Ù…Ø®ÙÙŠ',
                                      color: banner.active
                                          ? const Color(0xFFE8711A)
                                          : const Color(0xFF9A6B6B),
                                    ),
                                    _AdminStatusChip(
                                      label: 'Ø§Ù„ØªØ±ØªÙŠØ¨ ${banner.order}',
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
                                  child: const Text('ØªØ¹Ø¯ÙŠÙ„'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _publishBanner(banner),
                                  child: const Text('Ù†Ø´Ø±'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _deleteBanner(banner),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFC24E4E),
                                  ),
                                  child: const Text('Ø­Ø°Ù'),
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
                ? 'ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ù…Ù†ØªØ¬ Ø¨Ù†Ø¬Ø§Ø­.'
                : 'ØªÙ… ØªØ­Ø¯ÙŠØ« Ø§Ù„Ù…Ù†ØªØ¬ Ø¨Ù†Ø¬Ø§Ø­.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­ÙØ¸ Ø§Ù„Ù…Ù†ØªØ¬ Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
      );
    }
  }

  Future<void> _publishProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ø§Ø­ÙØ¸ Ø§Ù„Ù…Ù†ØªØ¬ Ø£ÙˆÙ„Ø§Ù‹ Ù‚Ø¨Ù„ Ù†Ø´Ø±Ù‡.')),
      );
      return;
    }

    try {
      await widget.catalogService.publishProduct(documentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ØªÙ… ØªØ­Ø¯ÙŠØ« lastUpdated Ù„Ù„Ù…Ù†ØªØ¬ Ø¨Ù†Ø¬Ø§Ø­.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ù†Ø´Ø± Ø§Ù„Ù…Ù†ØªØ¬ Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
      );
    }
  }

  Future<void> _deleteProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ù‡Ø°Ø§ Ø§Ù„Ù…Ù†ØªØ¬ ØºÙŠØ± Ù…Ø±ØªØ¨Ø· Ø¨ÙˆØ«ÙŠÙ‚Ø© Firestore.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ø­Ø°Ù Ø§Ù„Ù…Ù†ØªØ¬'),
            content: Text(
              'Ù‡Ù„ ØªØ±ÙŠØ¯ Ø­Ø°Ù "${product.expensiveName}" Ùˆ"${product.alternativeName}" Ù†Ù‡Ø§Ø¦ÙŠØ§Ù‹ØŸ',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ø¥Ù„ØºØ§Ø¡'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ø­Ø°Ù'),
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
        const SnackBar(content: Text('ØªÙ… Ø­Ø°Ù Ø§Ù„Ù…Ù†ØªØ¬.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­Ø°Ù Ø§Ù„Ù…Ù†ØªØ¬ Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
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
                    'Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ø¹Ø¯Ù‘Ù„ Ø§Ù„Ø£Ø³Ù…Ø§Ø¡ ÙˆØ§Ù„Ø£Ø³Ø¹Ø§Ø± ÙˆØ§Ù„ØµÙˆØ± Ø«Ù… Ø§Ù†Ø´Ø± Ø§Ù„ØªØ­Ø¯ÙŠØ« Ù„ÙŠØ¸Ù‡Ø± ÙÙˆØ±Ø§Ù‹ Ø¯Ø§Ø®Ù„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚.',
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
              label: const Text('Ø¥Ø¶Ø§ÙØ© Ù…Ù†ØªØ¬'),
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
                    'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª Ù…Ù† Firestore: ${snapshot.error}',
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
                    'Ù„Ø§ ØªÙˆØ¬Ø¯ Ù…Ù†ØªØ¬Ø§Øª Ø¨Ø¹Ø¯. Ø£Ø¶Ù Ø£ÙˆÙ„ Ù…Ù†ØªØ¬ Ù…Ù† Ø§Ù„Ø²Ø± Ø§Ù„Ø¹Ù„ÙˆÙŠ.',
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
                                      '${product.expensiveName}  â€¢  ${formatAmountValue(product.expensivePrice)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF17332B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${product.alternativeName}  â€¢  ${formatAmountValue(product.alternativePrice)}',
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
                                child: const Text('ØªØ¹Ø¯ÙŠÙ„'),
                              ),
                              OutlinedButton(
                                onPressed: () => _publishProduct(product),
                                child: const Text('Ù†Ø´Ø±'),
                              ),
                              OutlinedButton(
                                onPressed: () => _deleteProduct(product),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFC24E4E),
                                ),
                                child: const Text('Ø­Ø°Ù'),
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
  final FirestoreCatalogService _catalogService = const FirestoreCatalogService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _isRegisterMode = true;
  bool _isSubmitting = false;
  bool _isSendingPasswordReset = false;
  bool _obscurePassword = true;
  String? _statusMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    final messenger = ScaffoldMessenger.of(context);
    final normalizedPhone = _formatSaudiPhoneNumber(_phoneController.text);
    final normalizedEmail = _normalizeEmailAddress(_emailController.text);
    final password = _passwordController.text.trim();
    final referralCode = _referralController.text.trim().toUpperCase();

    if (normalizedPhone == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ø±Ù‚Ù… Ø§Ù„Ø¬ÙˆØ§Ù„ Ø¥Ù„Ø²Ø§Ù…ÙŠ. Ø£Ø¯Ø®Ù„Ù‡ Ø¨ØµÙŠØºØ© 05XXXXXXXX Ø£Ùˆ +9665XXXXXXXX.'),
        ),
      );
      return;
    }

    if (normalizedEmail == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ø£Ø¯Ø®Ù„ Ø¨Ø±ÙŠØ¯Ø§Ù‹ Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠØ§Ù‹ ØµØ­ÙŠØ­Ø§Ù‹ Ù„ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ ÙˆØ¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø­Ø³Ø§Ø¨.'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± ÙŠØ¬Ø¨ Ø£Ù† ØªÙƒÙˆÙ† 6 Ø£Ø­Ø±Ù Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„.'),
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
        throw const FormatException('Ù„Ù… ÙŠØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø¬Ù„Ø³Ø© Ù…Ø³ØªØ®Ø¯Ù… ÙÙŠ Firebase.');
      }

      await _catalogService.ensureUserProfile(
        user: user,
        pendingInviteCode: PendingAuthSession.consumeInviteCode(),
        requiredPhoneNumber: normalizedPhone,
        emailAddress: normalizedEmail,
      );
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _statusMessage = _isRegisterMode
            ? 'ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø­Ø³Ø§Ø¨ Ø¨Ù†Ø¬Ø§Ø­. ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„Ø¯Ø®ÙˆÙ„ Ù…Ø¨Ø§Ø´Ø±Ø© Ø¨Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ ÙˆÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±.'
            : 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ Ø¨Ù†Ø¬Ø§Ø­.';
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
        _statusMessage = 'ØªØ¹Ø°Ø± Ø¥ÙƒÙ…Ø§Ù„ ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ Ø­Ø§Ù„ÙŠØ§Ù‹: $error';
      });
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final normalizedEmail = _normalizeEmailAddress(_emailController.text);
    if (normalizedEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ø£Ø¯Ø®Ù„ Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ø£ÙˆÙ„Ø§Ù‹ Ù„Ø¥Ø±Ø³Ø§Ù„ Ø±Ø§Ø¨Ø· Ø¥Ø¹Ø§Ø¯Ø© ØªØ¹ÙŠÙŠÙ† ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±.'),
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
            'Ø£Ø±Ø³Ù„Ù†Ø§ Ø¥Ù„Ù‰ $normalizedEmail Ø±Ø§Ø¨Ø·Ø§Ù‹ Ù„Ø¥Ø¹Ø§Ø¯Ø© ØªØ¹ÙŠÙŠÙ† ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±. Ø§ÙØ­Øµ Ø§Ù„Ø¨Ø±ÙŠØ¯ ÙˆØµÙ†Ø¯ÙˆÙ‚ Ø§Ù„Ø±Ø³Ø§Ø¦Ù„ ØºÙŠØ± Ø§Ù„Ù…Ø±ØºÙˆØ¨Ø©.';
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
        _statusMessage = 'ØªØ¹Ø°Ø± Ø¥Ø±Ø³Ø§Ù„ Ø±Ø§Ø¨Ø· Ø§Ø³ØªØ¹Ø§Ø¯Ø© ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±: $error';
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
            colors: [Color(0xFF0D7A5E), Color(0xFFF5FCF9)],
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x140C3B2E),
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
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2FBF7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Color(0xFFE8711A),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ø£Ø±Ø®Øµ Ø³Ø¹Ø± - LeastPrice',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1B2F5E),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isRegisterMode
                                          ? 'Ø£Ù†Ø´Ø¦ Ø­Ø³Ø§Ø¨Ùƒ Ø¨Ø§Ù„Ø¥ÙŠÙ…ÙŠÙ„ ÙˆÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ù…Ø¹ Ø±Ù‚Ù… Ø¬ÙˆØ§Ù„ Ø¥Ù„Ø²Ø§Ù…ÙŠ.'
                                          : 'Ø³Ø¬Ù‘Ù„ Ø¯Ø®ÙˆÙ„Ùƒ Ø¨Ø§Ù„Ø¥ÙŠÙ…ÙŠÙ„ ÙˆÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±ØŒ ÙˆØ³ÙŠØ¨Ù‚Ù‰ Ø±Ù‚Ù… Ø§Ù„Ø¬ÙˆØ§Ù„ Ø¥Ù„Ø²Ø§Ù…ÙŠØ§Ù‹ Ø¯Ø§Ø®Ù„ Ø§Ù„Ù…Ù„Ù.',
                                      style: const TextStyle(
                                        color: Color(0xFF61756D),
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2FBF7),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _ModeToggleButton(
                                    selected: _isRegisterMode,
                                    label: 'Ø¥Ù†Ø´Ø§Ø¡ Ø­Ø³Ø§Ø¨',
                                    onTap: () {
                                      setState(() {
                                        _isRegisterMode = true;
                                        _statusMessage = null;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: _ModeToggleButton(
                                    selected: !_isRegisterMode,
                                    label: 'ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„',
                                    onTap: () {
                                      setState(() {
                                        _isRegisterMode = false;
                                        _statusMessage = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Ø±Ù‚Ù… Ø§Ù„Ø¬ÙˆØ§Ù„ - Ø¥Ù„Ø²Ø§Ù…ÙŠ',
                              hintText: '05XXXXXXXX',
                              prefixIcon: Icon(Icons.phone_android_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ',
                              hintText: 'name@example.com',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±',
                              hintText: '6 Ø£Ø­Ø±Ù Ø£Ùˆ Ø£ÙƒØ«Ø±',
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
                          const SizedBox(height: 14),
                          TextField(
                            controller: _referralController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'ÙƒÙˆØ¯ Ø§Ù„Ø¯Ø¹ÙˆØ© - Ø§Ø®ØªÙŠØ§Ø±ÙŠ',
                              hintText: 'LP-AB12',
                              prefixIcon: Icon(Icons.card_giftcard_rounded),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ø±Ù‚Ù… Ø§Ù„Ø¬ÙˆØ§Ù„ Ø¥Ù„Ø²Ø§Ù…ÙŠ Ù„Ø­ÙØ¸ Ù…Ù„ÙÙƒ ÙˆØ§Ù„ØªÙˆØ§ØµÙ„ Ø§Ù„ØªØ¬Ø§Ø±ÙŠØŒ Ø£Ù…Ø§ ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ ÙÙŠØ¹ØªÙ…Ø¯ Ø¹Ù„Ù‰ Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ ÙˆÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± ÙÙ‚Ø· Ø¯ÙˆÙ† Ø§Ù„Ø­Ø§Ø¬Ø© Ø¥Ù„Ù‰ ØªÙØ¹ÙŠÙ„ Ø§Ù„Ø­Ø³Ø§Ø¨.',
                            style: TextStyle(
                              color: Color(0xFF6C7D76),
                              fontSize: 12.8,
                              height: 1.45,
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
                                  ? 'Ø¬Ø§Ø±Ù Ø§Ù„ØªÙ†ÙÙŠØ°...'
                                  : (_isRegisterMode
                                      ? 'Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø­Ø³Ø§Ø¨'
                                      : 'ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isSubmitting || _isSendingPasswordReset
                                ? null
                                : _sendPasswordResetEmail,
                            icon: _isSendingPasswordReset
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2.2),
                                  )
                                : const Icon(Icons.mark_email_read_rounded),
                            label: const Text('Ø¥Ø±Ø³Ø§Ù„ Ø±Ø§Ø¨Ø· Ø¥Ø¹Ø§Ø¯Ø© ØªØ¹ÙŠÙŠÙ† ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±'),
                          ),
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

class _ModeToggleButton extends StatelessWidget {
  const _ModeToggleButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8711A) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF406156),
            fontWeight: FontWeight.w800,
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
      title: 'Ø¬Ø§Ø±Ù Ø¥Ù†Ù‡Ø§Ø¡ Ø§Ù„Ø¬Ù„Ø³Ø© Ø§Ù„Ù‚Ø¯ÙŠÙ…Ø©',
      message: 'Ù†Ø­Ø¯Ù‘Ø« Ø·Ø±ÙŠÙ‚Ø© Ø§Ù„Ø¯Ø®ÙˆÙ„ Ø¥Ù„Ù‰ Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ø­ØªÙ‰ ØªØ¸Ù‡Ø± Ù„Ùƒ Ø´Ø§Ø´Ø© Ø§Ù„ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¬Ø¯ÙŠØ¯Ø©.',
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
            ? 'ØªÙ… Ø§Ù„ØªØ­Ù‚Ù‚ Ù…Ù† Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ø¨Ù†Ø¬Ø§Ø­. Ø³Ù†Ù†Ù‚Ù„Ùƒ Ø§Ù„Ø¢Ù† Ø¥Ù„Ù‰ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚.'
            : 'Ù„Ù… ÙŠØªÙ… ØªÙØ¹ÙŠÙ„ Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø¨Ø¹Ø¯. Ø§ÙØªØ­ Ø§Ù„Ø±Ø³Ø§Ù„Ø© Ø§Ù„ÙˆØ§Ø±Ø¯Ø© Ø«Ù… Ø§Ø±Ø¬Ø¹ ÙˆØ§Ø¶ØºØ· "ØªØ­Ù‚Ù‚Øª Ù…Ù† Ø§Ù„Ø¨Ø±ÙŠØ¯".';
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
        _statusMessage = 'ØªØ¹Ø°Ø± ØªØ­Ø¯ÙŠØ« Ø­Ø§Ù„Ø© Ø§Ù„ØªÙØ¹ÙŠÙ„: $error';
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
            'Ø£Ø¹Ø¯Ù†Ø§ Ø¥Ø±Ø³Ø§Ù„ Ø±Ø§Ø¨Ø· Ø§Ù„ØªÙØ¹ÙŠÙ„ Ø¥Ù„Ù‰ ${widget.user.email ?? 'Ø¨Ø±ÙŠØ¯Ùƒ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ'}. Ø§ÙØ­Øµ Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø£Ø³Ø§Ø³ÙŠ ÙˆØ§Ù„Ø±Ø³Ø§Ø¦Ù„ ØºÙŠØ± Ø§Ù„Ù…Ø±ØºÙˆØ¨Ø©.';
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
        _statusMessage = 'ØªØ¹Ø°Ø± Ø¥Ø¹Ø§Ø¯Ø© Ø¥Ø±Ø³Ø§Ù„ Ø±Ø³Ø§Ù„Ø© Ø§Ù„ØªÙØ¹ÙŠÙ„: $error';
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
                    'ÙØ¹Ù‘Ù„ Ø¨Ø±ÙŠØ¯Ùƒ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ø£ÙˆÙ„Ø§Ù‹',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ø£Ø±Ø³Ù„Ù†Ø§ Ø±Ø§Ø¨Ø· ØªÙØ¹ÙŠÙ„ Ø¥Ù„Ù‰ ${widget.user.email ?? 'Ø¨Ø±ÙŠØ¯Ùƒ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ'}. Ø§Ù„ØªÙØ¹ÙŠÙ„ Ø¹Ø¨Ø± Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø£ÙˆÙØ± Ù…Ù† Ø±Ø³Ø§Ø¦Ù„ Ø§Ù„Ø¬ÙˆØ§Ù„ØŒ Ù„Ø°Ù„Ùƒ Ù„Ù† Ù†Ø¯Ø®Ù„Ùƒ Ù‚Ø¨Ù„ ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø¥ÙŠÙ…ÙŠÙ„.',
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
                    label: const Text('ØªØ­Ù‚Ù‚Øª Ù…Ù† Ø§Ù„Ø¨Ø±ÙŠØ¯'),
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
                    label: const Text('Ø¥Ø¹Ø§Ø¯Ø© Ø¥Ø±Ø³Ø§Ù„ Ø±Ø§Ø¨Ø· Ø§Ù„ØªÙØ¹ÙŠÙ„'),
                  ),
                  TextButton(
                    onPressed: _isRefreshing || _isResending ? null : _signOut,
                    child: const Text('Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø¨Ø±ÙŠØ¯ Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ø¢Ø®Ø±'),
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

  // Ø±Ø§Ø¨Ø· ÙØ§Ø±Øº Ø£Ùˆ localhost Ø£Ùˆ ØºÙŠØ± ØµØ§Ù„Ø­ â†’ placeholder Ø¢Ù…Ù†Ø©
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
      return 'ØµÙŠØºØ© Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ ØºÙŠØ± ØµØ­ÙŠØ­Ø©.';
    case 'email-already-in-use':
      return 'Ù‡Ø°Ø§ Ø§Ù„Ø¨Ø±ÙŠØ¯ Ù…Ø³ØªØ®Ø¯Ù… Ø¨Ø§Ù„ÙØ¹Ù„. Ø¬Ø±Ù‘Ø¨ ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ Ø¨Ø¯Ù„Ø§Ù‹ Ù…Ù† Ø¥Ù†Ø´Ø§Ø¡ Ø­Ø³Ø§Ø¨ Ø¬Ø¯ÙŠØ¯.';
    case 'weak-password':
      return 'ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ø¶Ø¹ÙŠÙØ© Ø¬Ø¯Ø§Ù‹. Ø§Ø®ØªØ± ÙƒÙ„Ù…Ø© Ù…Ø±ÙˆØ± Ø£Ù‚ÙˆÙ‰.';
    case 'user-not-found':
    case 'invalid-credential':
      return 'Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø¯Ø®ÙˆÙ„ ØºÙŠØ± ØµØ­ÙŠØ­Ø©. ØªØ£ÙƒØ¯ Ù…Ù† Ø§Ù„Ø¨Ø±ÙŠØ¯ ÙˆÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±.';
    case 'wrong-password':
      return 'ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± ØºÙŠØ± ØµØ­ÙŠØ­Ø©.';
    case 'operation-not-allowed':
      return 'ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ Ø¨Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ ÙˆÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± ØºÙŠØ± Ù…ÙØ¹Ù‘Ù„ ÙÙŠ Firebase Authentication Ø¨Ø¹Ø¯. ÙØ¹Ù‘Ù„ Ù…Ø²ÙˆØ¯ Email/Password Ù…Ù† Ù„ÙˆØ­Ø© Firebase Ø«Ù… Ø£Ø¹Ø¯ Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©.';
    case 'internal-error':
      final details = (error.message ?? '').toUpperCase();
      if (details.contains('CONFIGURATION_NOT_FOUND')) {
        return 'Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Firebase Authentication ØºÙŠØ± Ù…ÙƒØªÙ…Ù„Ø© Ù„Ù‡Ø°Ø§ Ø§Ù„Ù†ÙˆØ¹ Ù…Ù† ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„. ÙØ¹Ù‘Ù„ Email/Password Ù…Ù† Firebase Console Ø«Ù… Ø£Ø¹Ø¯ Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©.';
      }
      return 'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø¯Ø§Ø®Ù„ÙŠ ÙÙŠ Firebase Authentication. ØªØ­Ù‚Ù‚ Ù…Ù† Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ Ø«Ù… Ø£Ø¹Ø¯ Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©.';
    case 'too-many-requests':
      return 'ØªÙ… Ø¥Ø¬Ø±Ø§Ø¡ Ù…Ø­Ø§ÙˆÙ„Ø§Øª ÙƒØ«ÙŠØ±Ø©. Ø§Ù†ØªØ¸Ø± Ù‚Ù„ÙŠÙ„Ø§Ù‹ Ø«Ù… Ø£Ø¹Ø¯ Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©.';
    case 'network-request-failed':
      return 'ØªØ¹Ø°Ø± Ø§Ù„Ø§ØªØµØ§Ù„ Ø¨Ù€ Firebase Ø­Ø§Ù„ÙŠØ§Ù‹. ØªØ­Ù‚Ù‚ Ù…Ù† Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª Ø«Ù… Ø£Ø¹Ø¯ Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©.';
    default:
      return error.message ?? 'Ø­Ø¯Ø« Ø®Ø·Ø£ ÙÙŠ Ø§Ù„Ù…ØµØ§Ø¯Ù‚Ø©. Ø­Ø§ÙˆÙ„ Ù…Ø±Ø© Ø£Ø®Ø±Ù‰.';
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
    return 'Ø¨Ø§Ù†ØªØ¸Ø§Ø± Ø£ÙˆÙ„ ØªØ­Ø¯ÙŠØ«';
  }

  final local = value.toLocal();
  final twoDigitsHour = local.hour.toString().padLeft(2, '0');
  final twoDigitsMinute = local.minute.toString().padLeft(2, '0');
  final twoDigitsDay = local.day.toString().padLeft(2, '0');
  final twoDigitsMonth = local.month.toString().padLeft(2, '0');
  return '$twoDigitsHour:$twoDigitsMinute - $twoDigitsDay/$twoDigitsMonth';
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen({
    this.title = 'Ø¬Ø§Ø±Ù Ø§Ù„Ø§ØªØµØ§Ù„ Ø¨Ø®Ø¯Ù…Ø§Øª Ø§Ù„Ø¯Ø®ÙˆÙ„',
    this.message = 'Ù†Ø¬Ù‡Ø² Ø¬Ù„Ø³Ø© Firebase ÙˆÙ†Ø±Ø¨Ø· Ø­Ø³Ø§Ø¨Ùƒ Ø¨Ø§Ù„ØªØ·Ø¨ÙŠÙ‚...',
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
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF18352C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
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
                const Text(
                  'Firebase ØºÙŠØ± Ø¬Ø§Ù‡Ø²',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18352C),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message ??
                      'ØªØ¹Ø°Ø± ØªÙ‡ÙŠØ¦Ø© Firebase Ø­Ø§Ù„ÙŠØ§Ù‹. Ø£ÙƒÙ…Ù„ Ø¥Ø¹Ø¯Ø§Ø¯ Ø§Ù„Ù…ØµØ§Ø¯Ù‚Ø© ÙˆFirestore Ø«Ù… Ø£Ø¹Ø¯ ØªØ´ØºÙŠÙ„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚.',
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
                const Text(
                  'ØªØ¹Ø°Ø± ÙØªØ­ Ø­Ø³Ø§Ø¨Ùƒ',
                  style: TextStyle(
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
                  label: const Text('Ø¥Ø¹Ø§Ø¯Ø© Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø®Ø±ÙˆØ¬'),
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
  final SmartSearchDiscoveryService _smartSearchService =
      const SmartSearchDiscoveryService();
  final Connectivity _connectivity = Connectivity();
  final List<String> _quickSearchTags = const [
    'Ù‚Ù‡ÙˆØ©',
    'Ù…Ø·Ø§Ø¹Ù…',
    'Ø¹Ø·ÙˆØ±',
    'Ù…Ø­Ø§Ù…Øµ',
    'ØªØ¬Ù…ÙŠÙ„',
    'ØµÙŠØ¯Ù„ÙŠØ©',
    'Ù…Ù†Ø¸ÙØ§Øª',
    'Ø£Ù„Ø¨Ø§Ù†',
    'Ù…Ø¹Ù„Ø¨Ø§Øª',
    'Ø´Ø§ÙŠ',
  ];

  late Stream<List<ProductComparison>> _productsStream;
  StreamSubscription<dynamic>? _connectivitySubscription;
  StreamSubscription<UserSavingsProfile?>? _userProfileSubscription;
  StreamSubscription<List<AdBannerItem>>? _bannerSubscription;
  StreamSubscription<AutomationHealthStatus?>? _systemHealthSubscription;
  Timer? _smartSearchDebounce;
  String _query = '';
  String _selectedCategoryId = ProductCategoryCatalog.allId;
  bool _hasInternet = true;
  bool _isRefreshing = false;
  bool _isSearchingOnline = false;
  String? _dataNotice;
  String? _smartSearchNotice;
  String? _searchDemandNotice;
  String _dataSourceLabel = 'Cloud Firestore';
  UserSavingsProfile _userProfile = UserSavingsProfile.initial();
  AutomationHealthStatus _systemHealth = AutomationHealthStatus.initial();
  final Set<String> _submittedSearchRequestKeys = <String>{};
  List<AdBannerItem> _activeBanners = AdBannerItem.mockData;
  List<ProductComparison> _catalogProductsSnapshot = const <ProductComparison>[];
  List<ProductComparison> _smartSearchSuggestions =
      const <ProductComparison>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _userProfile = widget.initialUserProfile;
    _dataNotice = widget.bootstrapNotice;
    _dataSourceLabel = widget.firebaseReady ? 'Cloud Firestore' : 'Ø¨ÙŠØ§Ù†Ø§Øª Ø¨Ø¯ÙŠÙ„Ø©';
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
          _dataSourceLabel = result.source.label;
          _dataNotice = _mergeNotices(
            widget.bootstrapNotice,
            result.notice ??
                'ÙŠØªÙ… Ø¹Ø±Ø¶ Ø¨ÙŠØ§Ù†Ø§Øª Ø¨Ø¯ÙŠÙ„Ø© Ø­Ø§Ù„ÙŠØ§Ù‹ Ø­ØªÙ‰ ÙŠÙƒØªÙ…Ù„ Ø±Ø¨Ø· Firebase Ø¹Ù„Ù‰ Ù‡Ø°Ø§ Ø§Ù„Ø¬Ù‡Ø§Ø².',
          );
        });
      }

      yield result.products;
    } catch (error) {
      debugPrint('LeastPrice fallback catalog failed: $error');
      if (mounted) {
        setState(() {
          _dataSourceLabel = 'Ø¨ÙŠØ§Ù†Ø§Øª ØªØ¬Ø±ÙŠØ¨ÙŠØ©';
          _dataNotice = _mergeNotices(
            widget.bootstrapNotice,
            'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø¨Ø¯ÙŠÙ„Ø©ØŒ Ù„Ø°Ø§ ØªÙ… Ø§Ù„Ø±Ø¬ÙˆØ¹ Ø¥Ù„Ù‰ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„ØªØ¬Ø±ÙŠØ¨ÙŠØ© Ø§Ù„Ù…Ø¯Ù…Ø¬Ø©.',
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
            'ØªØ¹Ø°Ø± Ø§Ù„ØªØ­Ù‚Ù‚ Ù…Ù† Ø­Ø§Ù„Ø© Ø§Ù„Ø´Ø¨ÙƒØ© ØªÙ„Ù‚Ø§Ø¦ÙŠØ§Ù‹ØŒ Ù„ÙƒÙ† Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø³ÙŠØ­Ø§ÙˆÙ„ Ù…ØªØ§Ø¨Ø¹Ø© ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø³Ø­Ø§Ø¨ÙŠØ©.';
      });
    }
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text;
    setState(() {
      _query = nextQuery;
      _searchDemandNotice = null;
    });

    _scheduleSmartSearch(nextQuery);
  }

  void _applyQuickSearch(String value) {
    _searchController
      ..text = value
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: value.length),
      );
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _resetFilters() {
    _clearSearch();
    setState(() {
      _selectedCategoryId = ProductCategoryCatalog.allId;
      _searchDemandNotice = null;
      _productsStream = _buildProductsStream();
    });
    _clearSmartSearchState();
  }

  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _searchDemandNotice = null;
      _productsStream = _buildProductsStream();
    });

    _scheduleSmartSearch(_query);
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
    if (_smartSearchSuggestions.isEmpty &&
        _smartSearchNotice == null &&
        _searchDemandNotice == null &&
        !_isSearchingOnline) {
      return;
    }

    if (!mounted) {
      _smartSearchSuggestions = const <ProductComparison>[];
      _smartSearchNotice = null;
      _searchDemandNotice = null;
      _isSearchingOnline = false;
      return;
    }

    setState(() {
      _smartSearchSuggestions = const <ProductComparison>[];
      _smartSearchNotice = null;
      _searchDemandNotice = null;
      _isSearchingOnline = false;
    });
  }

  Future<void> _runSmartSearch(String rawQuery) async {
    final trimmedQuery = rawQuery.trim();
    final requestedCategoryId = _selectedCategoryId;
    if (trimmedQuery.isEmpty || !mounted || !_hasInternet) {
      _clearSmartSearchState();
      return;
    }

    setState(() {
      _isSearchingOnline = true;
      _smartSearchNotice = null;
    });

    try {
      final result = await _smartSearchService.discoverComparisons(
        query: trimmedQuery,
        selectedCategoryId: requestedCategoryId,
        existingProducts: _catalogProductsSnapshot,
      );

      if (!mounted ||
          _normalizeArabic(trimmedQuery) != _normalizeArabic(_query) ||
          requestedCategoryId != _selectedCategoryId) {
        return;
      }

      setState(() {
        _smartSearchSuggestions = result.products;
        _smartSearchNotice = result.notice;
      });

      if (_shouldQueueSearchDemand(
        query: trimmedQuery,
        categoryId: requestedCategoryId,
        smartSuggestions: result.products,
      )) {
        unawaited(
          _submitSearchDemand(
            query: trimmedQuery,
            categoryId: requestedCategoryId,
          ),
        );
      }
    } catch (error) {
      debugPrint('LeastPrice smart search failed: $error');
      if (!mounted ||
          _normalizeArabic(trimmedQuery) != _normalizeArabic(_query) ||
          requestedCategoryId != _selectedCategoryId) {
        return;
      }

      setState(() {
        _smartSearchSuggestions = const <ProductComparison>[];
        _smartSearchNotice =
            'ØªØ¹Ø°Ø± Ø¥ÙƒÙ…Ø§Ù„ Ø§Ù„Ø¨Ø­Ø« Ø§Ù„Ø°ÙƒÙŠ Ù…Ù† Ø§Ù„ÙˆÙŠØ¨ Ø­Ø§Ù„ÙŠØ§Ù‹. Ø³Ù†ÙˆØ§ØµÙ„ Ø§Ù„Ø§Ø¹ØªÙ…Ø§Ø¯ Ø¹Ù„Ù‰ Ø§Ù„Ù‚Ø§Ø¹Ø¯Ø© Ø§Ù„Ø­Ø§Ù„ÙŠØ© ÙˆØ³Ù†Ø³Ø¬Ù„ Ø·Ù„Ø¨Ùƒ Ø¥Ù† Ù„Ø²Ù….';
      });

      if (_shouldQueueSearchDemand(
        query: trimmedQuery,
        categoryId: requestedCategoryId,
        smartSuggestions: const <ProductComparison>[],
      )) {
        unawaited(
          _submitSearchDemand(
            query: trimmedQuery,
            categoryId: requestedCategoryId,
          ),
        );
      }
    } finally {
      if (mounted &&
          _normalizeArabic(trimmedQuery) == _normalizeArabic(_query) &&
          requestedCategoryId == _selectedCategoryId) {
        setState(() {
          _isSearchingOnline = false;
        });
      }
    }
  }

  bool _shouldQueueSearchDemand({
    required String query,
    required String categoryId,
    required List<ProductComparison> smartSuggestions,
  }) {
    if (!widget.firebaseReady || !_hasInternet) {
      return false;
    }

    final normalizedQuery = _normalizeArabic(query);
    if (normalizedQuery.length < 2) {
      return false;
    }

    if (smartSuggestions.isNotEmpty) {
      return false;
    }

    if (_findMatchingProducts(
      _catalogProductsSnapshot,
      normalizedQuery: normalizedQuery,
    ).isNotEmpty) {
      return false;
    }

    final requestKey = _buildSearchRequestKey(
      query: normalizedQuery,
      categoryId: categoryId,
    );

    return !_submittedSearchRequestKeys.contains(requestKey);
  }

  Future<void> _submitSearchDemand({
    required String query,
    required String categoryId,
  }) async {
    final normalizedQuery = _normalizeArabic(query);
    final requestKey = _buildSearchRequestKey(
      query: normalizedQuery,
      categoryId: categoryId,
    );

    if (_submittedSearchRequestKeys.contains(requestKey)) {
      return;
    }

    _submittedSearchRequestKeys.add(requestKey);

    try {
      await _catalogService.submitSearchRequest(
        query: query,
        categoryId: categoryId,
      );

      if (!mounted ||
          _normalizeArabic(_query) != normalizedQuery ||
          _selectedCategoryId != categoryId) {
        return;
      }

      setState(() {
        _searchDemandNotice =
            'Ø³Ø¬Ù„Ù†Ø§ Ø·Ù„Ø¨ Ø§Ù„Ø¨Ø­Ø« Ø¹Ù† "${query.trim()}"ØŒ ÙˆØ³ÙŠØ³ØªØ®Ø¯Ù…Ù‡ Ø±ÙˆØ¨ÙˆØª Ø§Ù„ØªØ­Ø¯ÙŠØ« Ø§Ù„ÙŠÙˆÙ…ÙŠ Ù„Ø¥Ø¶Ø§ÙØ© Ù‡Ø°Ø§ Ø§Ù„ØµÙ†Ù Ø£Ùˆ Ø£ÙØ¶Ù„ Ù…Ù‚Ø§Ø±Ù†Ø© Ù„Ù‡ ÙÙŠ Ø§Ù„Ø¬ÙˆÙ„Ø© Ø§Ù„Ù‚Ø§Ø¯Ù…Ø©.';
      });
    } catch (error) {
      _submittedSearchRequestKeys.remove(requestKey);
      debugPrint('LeastPrice search demand submission failed: $error');

      if (!mounted ||
          _normalizeArabic(_query) != normalizedQuery ||
          _selectedCategoryId != categoryId) {
        return;
      }

      setState(() {
        _searchDemandNotice =
            'ØªØ¹Ø°Ø± ØªØ³Ø¬ÙŠÙ„ Ø·Ù„Ø¨ Ø§Ù„Ø¨Ø­Ø« Ø§Ù„Ø¢Ù†. ØªØ­Ù‚Ù‚ Ù…Ù† Ø§Ù„Ø§ØªØµØ§Ù„ Ø«Ù… Ø¬Ø±Ù‘Ø¨ Ù…Ø±Ø© Ø£Ø®Ø±Ù‰ØŒ Ø£Ùˆ Ø§Ø³Ø­Ø¨ Ù„Ù„ØªØ­Ø¯ÙŠØ« Ù„Ø§Ø­Ù‚Ø§Ù‹.';
      });
    }
  }

  String _buildSearchRequestKey({
    required String query,
    required String categoryId,
  }) {
    return '$categoryId|$query';
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
          ? 'Ø¹Ø§Ø¯ Ø§Ù„Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø´Ø¨ÙƒØ©. ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„Ø³Ø­Ø¨ Ù„Ù„Ø£Ø³ÙÙ„ Ù„Ù„ØªØ£ÙƒØ¯ Ù…Ù† Ø¬Ù„Ø¨ Ø£Ø­Ø¯Ø« Ø§Ù„Ø£Ø³Ø¹Ø§Ø± Ù…Ù† Firestore.'
          : 'Ø§Ù„Ø§ØªØµØ§Ù„ ØºÙŠØ± Ù…ØªÙˆÙØ± Ø­Ø§Ù„ÙŠØ§Ù‹. Ø³Ù†Ø¹Ø±Ø¶ Ø¢Ø®Ø± Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø®Ø²Ù†Ø©ØŒ ÙˆØ¹Ù†Ø¯ Ø¹ÙˆØ¯Ø© Ø§Ù„Ø´Ø¨ÙƒØ© ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„Ø³Ø­Ø¨ Ù„Ù„ØªØ­Ø¯ÙŠØ«.';
    });

    if (!showFeedback) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasInternet
              ? 'ØªÙ…Øª Ø§Ø³ØªØ¹Ø§Ø¯Ø© Ø§Ù„Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø´Ø¨ÙƒØ©.'
              : 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª Ø­Ø§Ù„ÙŠØ§Ù‹.',
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
        const SnackBar(
          content: Text(
            'Ø£ÙƒÙ…Ù„ Ø¥Ø¹Ø¯Ø§Ø¯ Firebase Ø£ÙˆÙ„Ø§Ù‹ Ø­ØªÙ‰ ÙŠØªÙ…ÙƒÙ† Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ù…Ù† Ø§Ù„ØªØ­Ø¯ÙŠØ« Ù…Ù† Cloud Firestore.',
          ),
        ),
      );
      return;
    }

    if (!_hasInternet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø§ØªØµØ§Ù„ Ø­Ø§Ù„ÙŠØ§Ù‹. Ø³Ù†Ø¹Ø±Ø¶ Ø¢Ø®Ø± Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…ØªØ§Ø­Ø© Ø­ØªÙ‰ ØªØ¹ÙˆØ¯ Ø§Ù„Ø´Ø¨ÙƒØ©.',
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
      _dataNotice = 'ÙŠØªÙ… Ø§Ù„Ø¢Ù† Ø§Ù„ØªØ­Ù‚Ù‚ Ù…Ù† Ø£Ø­Ø¯Ø« Ø§Ù„Ø£Ø³Ø¹Ø§Ø± ÙˆØ§Ù„Ù…Ù†ØªØ¬Ø§Øª Ù…Ù† Cloud Firestore.';
    });

    try {
      await _catalogService.refreshProductsFromServer();
      if (!mounted) return;

      setState(() {
        _dataNotice = 'ØªÙ…Øª Ù…Ø²Ø§Ù…Ù†Ø© Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø³Ø­Ø§Ø¨ÙŠØ© Ø¨Ù†Ø¬Ø§Ø­.';
      });

      if (showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ØªÙ… ØªØ­Ø¯ÙŠØ« Ù‚Ø§Ø¦Ù…Ø© Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª Ù…Ù† Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª Ø¨Ù†Ø¬Ø§Ø­.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _dataNotice =
            'ØªØ¹Ø°Ø± Ø¬Ù„Ø¨ Ø¢Ø®Ø± ØªØ­Ø¯ÙŠØ« Ù…Ù† Cloud Firestore Ø­Ø§Ù„ÙŠØ§Ù‹. Ø³Ù†ÙˆØ§ØµÙ„ Ø¹Ø±Ø¶ Ø¢Ø®Ø± Ù†Ø³Ø®Ø© Ù…ØªØ§Ø­Ø© Ù„Ø¯ÙŠÙƒ.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ØªØ¹Ø°Ø± Ø§Ù„ÙˆØµÙˆÙ„ Ø¥Ù„Ù‰ Ù‚Ø§Ø¹Ø¯Ø© Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø­Ø§Ù„ÙŠØ§Ù‹. ØªØ­Ù‚Ù‚ Ù…Ù† Ø§Ù„Ø§ØªØµØ§Ù„ Ø«Ù… Ø£Ø¹Ø¯ Ø§Ù„Ø³Ø­Ø¨.',
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

  List<ProductCategory> _visibleCategoriesFor(
    List<ProductComparison> products,
  ) {
    final availableIds = products.map((product) => product.categoryId).toSet();
    final visible = <ProductCategory>[...ProductCategoryCatalog.defaults];

    for (final categoryId in availableIds) {
      final alreadyVisible = visible.any((category) => category.id == categoryId);
      if (alreadyVisible) {
        continue;
      }

      final fallbackLabel = products
          .firstWhere((product) => product.categoryId == categoryId)
          .categoryLabel;

      visible.add(
        ProductCategoryCatalog.lookup(
          categoryId,
          fallbackLabel: fallbackLabel,
        ),
      );
    }

    return visible;
  }

  String _selectedCategoryLabelFor(List<ProductComparison> products) {
    if (_selectedCategoryId == ProductCategoryCatalog.allId) {
      return ProductCategoryCatalog.all.label;
    }

    String? fallbackLabel;
    for (final product in products) {
      if (product.categoryId == _selectedCategoryId &&
          product.categoryLabel.trim().isNotEmpty) {
        fallbackLabel = product.categoryLabel;
        break;
      }
    }

    return ProductCategoryCatalog.lookup(
      _selectedCategoryId,
      fallbackLabel: fallbackLabel ?? 'Ø§Ù„ÙƒÙ„',
    ).label;
  }

  List<ProductComparison> _filteredProductsFor(
    List<ProductComparison> products,
  ) {
    final localResults = _filterProductsWithCurrentState(products);
    final normalizedQuery = _normalizeArabic(_query);

    if (normalizedQuery.isEmpty) {
      return localResults;
    }

    final smartResults = _filterProductsWithCurrentState(_smartSearchSuggestions);
    if (smartResults.isEmpty) {
      return localResults;
    }

    final merged = <ProductComparison>[...localResults];
    final fingerprints = localResults
        .map(_productFingerprint)
        .where((token) => token.isNotEmpty)
        .toSet();

    for (final product in smartResults) {
      final fingerprint = _productFingerprint(product);
      if (fingerprint.isEmpty || fingerprints.add(fingerprint)) {
        merged.add(product);
      }
    }

    return merged;
  }

  List<ProductComparison> _filterProductsWithCurrentState(
    List<ProductComparison> products,
  ) {
    final normalizedQuery = _normalizeArabic(_query);

    return _findMatchingProducts(
      products,
      normalizedQuery: normalizedQuery,
      categoryId: _selectedCategoryId,
    );
  }

  List<ProductComparison> _findMatchingProducts(
    List<ProductComparison> products, {
    required String normalizedQuery,
    String? categoryId,
  }) {
    final filtered = products.where((product) {
      if (categoryId == null || categoryId == ProductCategoryCatalog.allId) {
        return true;
      }
      return product.categoryId == categoryId;
    }).toList();

    if (normalizedQuery.isEmpty) {
      return filtered;
    }

    final ranked = filtered
        .map(
          (product) => MapEntry(
            product,
            _calculateSearchScore(product, normalizedQuery),
          ),
        )
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ranked.map((entry) => entry.key).toList();
  }

  String _productFingerprint(ProductComparison product) {
    return _normalizeArabic(
      '${product.expensiveName}|${product.alternativeName}|${product.categoryLabel}|${product.buyUrl}',
    );
  }

  int _calculateSearchScore(ProductComparison product, String query) {
    final searchableTokens = product.searchTokens
        .map(_normalizeArabic)
        .where((token) => token.isNotEmpty)
        .toList();

    final searchableText = searchableTokens.join(' ');
    final terms = query.split(' ').where((term) => term.isNotEmpty);
    var total = 0;

    for (final term in terms) {
      var termScore = 0;

      for (final token in searchableTokens) {
        if (token == term) {
          termScore = math.max(termScore, 120);
        } else if (token.startsWith(term)) {
          termScore = math.max(termScore, 90);
        } else if (token.contains(term)) {
          termScore = math.max(termScore, 60);
        }
      }

      if (termScore == 0 && searchableText.contains(term)) {
        termScore = 35;
      }

      if (termScore == 0) {
        return 0;
      }

      total += termScore;
    }

    return total + product.savingsPercent;
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
          const SnackBar(
            content: Text('Ø§Ù„Ø±Ø§Ø¨Ø· Ø§Ù„Ø­Ø§Ù„ÙŠ Ù„Ø§ ÙŠÙˆØ¬Ù‘Ù‡ Ø¥Ù„Ù‰ Ù…ØªØ¬Ø± Ø³Ø¹ÙˆØ¯ÙŠ Ù…Ø¯Ø¹ÙˆÙ….'),
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
          const SnackBar(content: Text('ØªØ¹Ø°Ø± ÙØªØ­ Ø±Ø§Ø¨Ø· Ø§Ù„Ø´Ø±Ø§Ø¡ Ø­Ø§Ù„ÙŠØ§Ù‹.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Ø§Ù„Ø±Ø§Ø¨Ø· ØºÙŠØ± ØµØ§Ù„Ø­ Ø£Ùˆ ØºÙŠØ± Ù…ØªØ§Ø­ Ø­Ø§Ù„ÙŠØ§Ù‹.')),
      );
    }
  }

  Future<void> _openBuyLink(ProductComparison product) {
    if (!product.hasBuyUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø±Ø§Ø¨Ø· Ø´Ø±Ø§Ø¡ Ù„Ù‡Ø°Ø§ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù† Ø­Ø§Ù„ÙŠØ§Ù‹.'),
        ),
      );
      return Future<void>.value();
    }

    return _openExternalUrl(
      product.buyUrl,
      enforceSupportedStore: true,
    );
  }

  void _shareSavings(ProductComparison product) {
    final message = product.hasOriginalOfferTag
        ? 'ÙˆØ¬Ø¯Øª Ø¹Ø±Ø¶Ø§Ù‹ Ù…Ù…ÙŠØ²Ø§Ù‹ Ø¹Ù„Ù‰ Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ø£ØµÙ„ÙŠ Ø¯Ø§Ø®Ù„ ØªØ·Ø¨ÙŠÙ‚ Ø£Ø±Ø®Øµ Ø³Ø¹Ø±! '
            'Ø´Ø§Ù‡Ø¯ Ø§Ù„Ù…Ù‚Ø§Ø±Ù†Ø© Ø§Ù„Ø¢Ù†: ${_userProfile.shareBaseUrl}'
        : 'Ø´Ø§Ù‡Ø¯Øª Ù‡Ø°Ø§ Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ø§Ù‚ØªØµØ§Ø¯ÙŠ ÙÙŠ ØªØ·Ø¨ÙŠÙ‚ Ø£Ø±Ø®Øµ Ø³Ø¹Ø± ÙˆÙˆÙØ±Øª '
            '${formatAmountValue(product.savingsAmount)} Ø±ÙŠØ§Ù„! '
            'Ø­Ù…Ù„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¢Ù†: ${_userProfile.shareBaseUrl}';

    Share.share(message, subject: 'Ø£Ø±Ø®Øµ Ø³Ø¹Ø± - LeastPrice');
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
      subject: 'Ø§Ø¯Ø¹Ù ØµØ¯ÙŠÙ‚Ø§Ù‹ Ù„Ù„ØªÙˆÙÙŠØ± Ù…Ø¹ Ø£Ø±Ø®Øµ Ø³Ø¹Ø±',
    );
  }

  Future<void> _openBanner(AdBannerItem banner) async {
    if (banner.targetUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø±Ø§Ø¨Ø· Ù…ÙØ¹Ù„ Ù„Ù‡Ø°Ø§ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù† Ø­Ø§Ù„ÙŠØ§Ù‹.'),
        ),
      );
      return;
    }

    await _openExternalUrl(banner.targetUrl);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _openRatingDialog(ProductComparison product) async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => _RateAlternativeDialog(product: product),
    );

    if (rating == null || !mounted) {
      return;
    }

    try {
      await _catalogService.submitRating(product, rating);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ØªÙ… ØªØ³Ø¬ÙŠÙ„ ØªÙ‚ÙŠÙŠÙ…Ùƒ Ù„Ù€ "${product.alternativeName}" ÙˆØªØ­Ø¯ÙŠØ«Ù‡ Ø¹Ù„Ù‰ Ø§Ù„Ø³Ø­Ø§Ø¨Ø©.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ØªØ¹Ø°Ø± Ø­ÙØ¸ Ø§Ù„ØªÙ‚ÙŠÙŠÙ… Ø­Ø§Ù„ÙŠØ§Ù‹. ØªØ£ÙƒØ¯ Ù…Ù† Ø£Ù† Ø§Ù„Ù…Ù†ØªØ¬ Ù…Ø±ØªØ¨Ø· Ø¨ÙˆØ«ÙŠÙ‚Ø© Firestore.',
          ),
        ),
      );
    }
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
        _dataNotice =
            'ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ù…Ù†ØªØ¬ Ø¥Ù„Ù‰ Cloud Firestore ÙˆØ³ÙŠØ¸Ù‡Ø± Ù…Ø¨Ø§Ø´Ø±Ø© Ù„ÙƒÙ„ Ù…Ù† ÙŠØ³ØªØ®Ø¯Ù… Ø§Ù„ØªØ·Ø¨ÙŠÙ‚.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© "${product.alternativeName}" Ø¨Ù†Ø¬Ø§Ø­.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ØªØ¹Ø°Ø± Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ù…Ù†ØªØ¬ Ø¥Ù„Ù‰ Cloud Firestore. ØªØ­Ù‚Ù‚ Ù…Ù† Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Ø£Ùˆ Ø§Ù„Ø§ØªØµØ§Ù„.',
          ),
        ),
      );
    }
  }

  void _showFirebaseSetupRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ ÙŠØ­ØªØ§Ø¬ ØªÙ‡ÙŠØ¦Ø© Firebase ÙˆCloud Firestore Ø£ÙˆÙ„Ø§Ù‹ Ù‚Ø¨Ù„ Ø§Ø³ØªØ®Ø¯Ø§Ù… Ù‚Ø§Ø¹Ø¯Ø© Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'admin-dashboard-fab',
        tooltip: 'Ù„ÙˆØ­Ø© Ø§Ù„Ù…Ø³Ø¤ÙˆÙ„',
        backgroundColor: const Color(0xE60F8F6F),
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
          _catalogProductsSnapshot = products;
          final filteredProducts = _filteredProductsFor(products);
          final visibleCategories = _visibleCategoriesFor(products);
          final selectedCategoryLabel = _selectedCategoryLabelFor(products);
          final hasQuery = _query.trim().isNotEmpty;
          final isInitialLoading =
              widget.firebaseReady &&
              snapshot.connectionState == ConnectionState.waiting &&
              products.isEmpty;

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF2FCF7), Color(0xFFFFFFFF)],
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
                                  : 'Ù…Ø³ØªØ®Ø¯Ù… Ù…ÙˆØ«Ù‘Ù‚'),
                      banners: _activeBanners,
                      searchController: _searchController,
                      resultsCount: filteredProducts.length,
                      quickTags: _quickSearchTags,
                      categories: visibleCategories,
                      selectedCategoryId: _selectedCategoryId,
                      dataSourceLabel: _dataSourceLabel,
                      inviteCode: _userProfile.inviteCode,
                      invitedFriendsCount: _userProfile.invitedFriendsCount,
                      estimatedSavingsText: formatAmountValue(
                        _estimatedInviteSavingsFor(products),
                      ),
                      systemHealthLabel: _systemHealth.statusLabel,
                      onTagTap: _applyQuickSearch,
                      onBannerTap: _openBanner,
                      onCategorySelected: _selectCategory,
                      onInviteTap: () => _inviteFriend(products),
                      onLogoutTap: _signOut,
                      onClearSearch: _clearSearch,
                    ),
                  ),
                  if (!_hasInternet)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _StatusBanner(
                          icon: Icons.wifi_off_rounded,
                          title: 'Ø§Ù„Ø§ØªØµØ§Ù„ ØºÙŠØ± Ù…ØªÙˆÙØ±',
                          message:
                              'Ø³ÙŠØ¹Ø±Ø¶ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø¢Ø®Ø± Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø­ÙÙˆØ¸Ø©ØŒ ÙˆØ¹Ù†Ø¯ Ø¹ÙˆØ¯Ø© Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„Ø³Ø­Ø¨ Ù„Ù„Ø£Ø³ÙÙ„ Ù„ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø£Ø³Ø¹Ø§Ø±.',
                          backgroundColor: Color(0xFFFFF8E8),
                          borderColor: Color(0xFFF2D38D),
                          accentColor: Color(0xFF9A6700),
                        ),
                      ),
                    ),
                  if (!widget.firebaseReady)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: _StatusBanner(
                          icon: Icons.cloud_off_rounded,
                          title: 'Firebase ØºÙŠØ± Ù…Ù‡ÙŠØ£',
                          message:
                              'Ø£Ø¶Ù Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª Firebase ÙˆÙ…Ù„ÙØ§Øª Android Ø«Ù… Ø£Ø¹Ø¯ ØªØ´ØºÙŠÙ„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ù„ÙŠØ¨Ø¯Ø£ Ø¬Ù„Ø¨ Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª Ù…Ù† Cloud Firestore.',
                          backgroundColor: Color(0xFFFFF1F0),
                          borderColor: Color(0xFFF4C7C3),
                          accentColor: Color(0xFFB44B42),
                        ),
                      ),
                    )
                  else if (snapshot.hasError && products.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: _StatusBanner(
                          icon: Icons.cloud_off_rounded,
                          title: 'ØªØ¹Ø°Ø± Ù‚Ø±Ø§Ø¡Ø© Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª',
                          message:
                              'Ù„Ù… Ù†ØªÙ…ÙƒÙ† Ù…Ù† Ø§Ù„ÙˆØµÙˆÙ„ Ø¥Ù„Ù‰ Cloud Firestore Ø­Ø§Ù„ÙŠØ§Ù‹. ØªØ£ÙƒØ¯ Ù…Ù† Ø¥Ø¹Ø¯Ø§Ø¯ Ø§Ù„Ù‚Ø§Ø¹Ø¯Ø© ÙˆØ§Ù„Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø´Ø¨ÙƒØ© Ø«Ù… Ø¬Ø±Ù‘Ø¨ Ù…Ø±Ø© Ø£Ø®Ø±Ù‰.',
                          backgroundColor: Color(0xFFFFF1F0),
                          borderColor: Color(0xFFF4C7C3),
                          accentColor: Color(0xFFB44B42),
                        ),
                      ),
                    ),
                  if (snapshot.hasError && products.isEmpty && !widget.firebaseReady)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                      sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                    ),
                  if (!snapshot.hasError || products.isNotEmpty || !widget.firebaseReady)
                    if (isInitialLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE8711A),
                        ),
                      ),
                    )
                  else if (filteredProducts.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: _EmptyState(
                          query: _query,
                          selectedCategoryLabel: selectedCategoryLabel,
                          searchDemandNotice: _searchDemandNotice,
                          onReset: _resetFilters,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = filteredProducts[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == filteredProducts.length - 1
                                    ? 0
                                    : 18,
                              ),
                              child: ComparisonCard(
                                comparison: product,
                                onBuyTap: product.hasBuyUrl
                                    ? () => _openBuyLink(product)
                                    : null,
                                onShareTap: () => _shareSavings(product),
                                onRateTap: () => _openRatingDialog(product),
                                onLocationTap: product.localLocationUrl == null
                                    ? null
                                    : () => _openExternalUrl(
                                          product.localLocationUrl!,
                                        ),
                              ),
                            );
                          },
                          childCount: filteredProducts.length,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasQuery
                                ? 'Ù†ØªØ§Ø¦Ø¬ Ø§Ù„Ø¨Ø­Ø« Ø¹Ù† "${_query.trim()}"'
                                : 'ÙŠØªÙ… Ø§Ù„Ø¢Ù† Ø¬Ù„Ø¨ Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª Ù…Ø¨Ø§Ø´Ø±Ø© Ù…Ù† Cloud Firestore Ù…Ø¹ Ø¨Ø« Ù„Ø­Ø¸ÙŠ Ù„Ø£ÙŠ ØªØ­Ø¯ÙŠØ« Ø¬Ø¯ÙŠØ¯.',
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
                            const Text(
                              'Ø¬Ø§Ø±Ù Ø§Ù„ØªØ­Ù‚Ù‚ Ù…Ù† Ø£Ø­Ø¯Ø« Ø§Ù„Ø£Ø³Ø¹Ø§Ø± Ù…Ù† Ø§Ù„Ø®Ø§Ø¯Ù…...',
                              style: TextStyle(
                                color: Color(0xFF9A6700),
                                fontSize: 12.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (_isSearchingOnline) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Ø¬Ø§Ø±Ù Ø§Ù„Ø¨Ø­Ø« Ø§Ù„Ø°ÙƒÙŠ Ù…Ù† Ø§Ù„ÙˆÙŠØ¨ Ø¹Ù† Ù…Ù‚Ø§Ø±Ù†Ø§Øª ØºÙŠØ± Ù…ÙˆØ¬ÙˆØ¯Ø© ÙÙŠ Ø§Ù„Ù‚Ø§Ø¹Ø¯Ø©...',
                              style: TextStyle(
                                color: Color(0xFF0B7A5E),
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
                                color: Color(0xFF5B6E66),
                                fontSize: 12.8,
                                fontWeight: FontWeight.w700,
                                height: 1.45,
                              ),
                            ),
                          ],
                          if (_searchDemandNotice != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _searchDemandNotice!,
                              style: const TextStyle(
                                color: Color(0xFF0B7A5E),
                                fontSize: 12.8,
                                fontWeight: FontWeight.w800,
                                height: 1.5,
                              ),
                            ),
                          ],
                          if (snapshot.hasError && products.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Ø­Ø¯Ø«Øª Ù…Ø´ÙƒÙ„Ø© Ù…Ø¤Ù‚ØªØ© ÙÙŠ Ø§Ù„Ù…Ø²Ø§Ù…Ù†Ø©ØŒ Ù„ÙƒÙ† ØªÙ… Ø§Ù„Ø¥Ø¨Ù‚Ø§Ø¡ Ø¹Ù„Ù‰ Ø¢Ø®Ø± Ø¨ÙŠØ§Ù†Ø§Øª Ù…ØªØ§Ø­Ø©.',
                              style: TextStyle(
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.query,
    required this.currentUserLabel,
    required this.banners,
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
    required this.onTagTap,
    required this.onBannerTap,
    required this.onCategorySelected,
    required this.onInviteTap,
    required this.onLogoutTap,
    required this.onClearSearch,
  });

  final String query;
  final String currentUserLabel;
  final List<AdBannerItem> banners;
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
  final ValueChanged<String> onTagTap;
  final ValueChanged<AdBannerItem> onBannerTap;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onInviteTap;
  final Future<void> Function() onLogoutTap;
  final VoidCallback onClearSearch;

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
              colors: [Color(0xFF0B7A5E), Color(0xFF13A07C)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x290F8F6F),
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
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFFE8711A),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ø£Ø±Ø®Øµ Ø³Ø¹Ø± - LeastPrice',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ù…Ø±Ø­Ø¨Ø§Ù‹ $currentUserLabel',
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
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: onLogoutTap,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0x1AFFFFFF),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: 'ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø®Ø±ÙˆØ¬',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ÙˆØ§Ø¬Ù‡Ø© ØªØ¬Ø§Ø±ÙŠØ© ØªØ¬Ù…Ø¹ Ø¹Ø±ÙˆØ¶ Ø§Ù„Ù…ØªØ§Ø¬Ø±ØŒ Ø§Ù„Ù…Ù‚Ø§Ø±Ù†Ø§Øª Ø§Ù„ÙŠÙˆÙ…ÙŠØ©ØŒ ÙˆØ§Ù„Ø¯Ø¹ÙˆØ§Øª Ø§Ù„Ø°ÙƒÙŠØ© ÙÙŠ Ù…ÙƒØ§Ù† ÙˆØ§Ø­Ø¯.',
                    style: TextStyle(
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
                      hintText: 'Ø§Ø¨Ø­Ø« Ø¹Ù† Ù…Ù†ØªØ¬ Ù…Ø«Ù„: Ù†Ø³ÙƒØ§ÙÙŠÙ‡ØŒ ÙƒØ±Ø§ÙØªØŒ Ù‡Ø§ÙŠÙ†Ø²...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: hasQuery
                          ? IconButton(
                              onPressed: onClearSearch,
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (banners.isNotEmpty) ...[
                    _BannerCarousel(
                      banners: banners,
                      onTap: onBannerTap,
                    ),
                    const SizedBox(height: 18),
                  ],
                  const Text(
                    'Ø§Ù„Ø£Ù‚Ø³Ø§Ù… Ø§Ù„Ø¨Ø§Ø±Ø²Ø©',
                    style: TextStyle(
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
                            label: Text(tag),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatPill(
                        icon: Icons.inventory_2_outlined,
                        label: '$resultsCount Ù†ØªÙŠØ¬Ø©',
                      ),
                      _StatPill(
                        icon: Icons.bolt_rounded,
                        label: hasQuery ? 'Ø¨Ø­Ø« Ù…Ø¨Ø§Ø´Ø±' : 'Ø¨Ø­Ø« Ø°ÙƒÙŠ',
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
                            const Expanded(
                              child: Text(
                                'Ù…Ù„Ù Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… ÙˆØ¯Ø¹ÙˆØ§Øª Ø§Ù„ØªÙˆÙÙŠØ±',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              'ÙƒÙˆØ¯Ùƒ: $inviteCode',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ø´Ø§Ø±Ùƒ Ø±Ø§Ø¨Ø· Ø§Ù„Ø¯Ø¹ÙˆØ© Ø§Ù„Ø®Ø§Øµ Ø¨Ùƒ ÙˆÙˆØ³Ù‘Ø¹ Ø¯Ø§Ø¦Ø±Ø© Ø§Ù„ØªÙˆÙÙŠØ± Ø¨ÙŠÙ† Ø£ØµØ¯Ù‚Ø§Ø¦Ùƒ.',
                          style: TextStyle(
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
                                label: '$invitedFriendsCount Ø¯Ø¹ÙˆØ©',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _InviteMetric(
                                icon: Icons.savings_rounded,
                                label: '$estimatedSavingsText Ø±.Ø³ ØªÙˆÙÙŠØ±',
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
                            label: const Text('Ø§Ø¯Ø¹Ù ØµØ¯ÙŠÙ‚Ø§Ù‹ Ù„Ù„ØªÙˆÙÙŠØ±'),
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
              category.label,
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
                                color: const Color(0xFFCAEADF),
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
                              colors: [Color(0xD90F271F), Color(0x55152F28)],
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
                    color: const Color(0xFFF2FBF7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    comparison.categoryLabel,
                    style: const TextStyle(
                      color: Color(0xFFE8711A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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
                        label: 'Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ø£Ø¹Ù„Ù‰ Ø³Ø¹Ø±Ø§Ù‹',
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
                        label: 'Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ø£ÙØ¶Ù„ Ù‚ÙŠÙ…Ø©',
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
                        label: 'Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ø£Ø¹Ù„Ù‰ Ø³Ø¹Ø±Ø§Ù‹',
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
                        label: 'Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ø£ÙØ¶Ù„ Ù‚ÙŠÙ…Ø©',
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
                color: const Color(0xFFFFF6EF),
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
                          ? 'Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ø£ØµÙ„ÙŠ Ø£ØµØ¨Ø­ Ø§Ù„Ø£Ø±Ø®Øµ Ø­Ø§Ù„ÙŠØ§Ù‹ØŒ Ù„Ø°Ù„Ùƒ Ù†Ù†ØµØ­ Ø¨Ù…Ø±Ø§Ø¬Ø¹Ø© Ø§Ù„Ø¹Ø±Ø¶ Ù‚Ø¨Ù„ Ø§Ù„Ø´Ø±Ø§Ø¡.'
                          : 'ÙØ±Ù‚ Ø§Ù„Ø³Ø¹Ø±: ${formatPrice(comparison.savingsAmount)} Ù„ØµØ§Ù„Ø­ Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ø£ÙØ¶Ù„ Ù‚ÙŠÙ…Ø©.',
                      style: const TextStyle(
                        color: Color(0xFF224238),
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
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
                          label: const Text('Ù…Ø´Ø§Ø±ÙƒØ© Ø§Ù„ØªÙˆÙÙŠØ±'),
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
                                ? 'ÙØªØ­ Ø±Ø§Ø¨Ø· Ø§Ù„Ø´Ø±Ø§Ø¡'
                                : 'Ø¨Ø¯ÙˆÙ† Ø±Ø§Ø¨Ø· Ø´Ø±Ø§Ø¡',
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
                        label: const Text('Ù…Ø´Ø§Ø±ÙƒØ© Ø§Ù„ØªÙˆÙÙŠØ±'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onBuyTap,
                        icon: const Icon(Icons.shopping_cart_checkout_rounded),
                        label: Text(
                          comparison.hasBuyUrl
                              ? 'ÙØªØ­ Ø±Ø§Ø¨Ø· Ø§Ù„Ø´Ø±Ø§Ø¡'
                              : 'Ø¨Ø¯ÙˆÙ† Ø±Ø§Ø¨Ø· Ø´Ø±Ø§Ø¡',
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
        ? '${comparison.rating.toStringAsFixed(1)} â­ - ${comparison.reviewCount} ØªÙ‚ÙŠÙŠÙ…'
        : 'Ø§Ø¨Ø¯Ø£ Ø£ÙˆÙ„ ØªÙ‚ÙŠÙŠÙ… Ù„Ù‡Ø°Ø§ Ø§Ù„Ø®ÙŠØ§Ø±';

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
                  const Text(
                    'Ø§Ø¶ØºØ· Ø¹Ù„Ù‰ Ø§Ù„Ù†Ø¬ÙˆÙ… Ù„ØªÙ‚ÙŠÙŠÙ… Ø§Ù„Ø¬ÙˆØ¯Ø© ÙˆØ§Ù„Ù‚ÙŠÙ…Ø© Ù…Ù‚Ø§Ø±Ù†Ø© Ø¨Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ø£Ø¹Ù„Ù‰ Ø³Ø¹Ø±Ø§Ù‹.',
                    style: TextStyle(
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
              title: 'Ù†ÙˆØªØ© Ø§Ù„Ø¹Ø·Ø±',
              value: comparison.fragranceNotes!,
            ),
          if (comparison.activeIngredients != null &&
              comparison.activeIngredients!.trim().isNotEmpty)
            _InsightRow(
              icon: Icons.science_rounded,
              title: 'Ø§Ù„Ù…Ø§Ø¯Ø© Ø§Ù„ÙØ¹Ø§Ù„Ø©',
              value: comparison.activeIngredients!,
            ),
          if (comparison.localLocationLabel != null &&
              comparison.localLocationLabel!.trim().isNotEmpty)
            _InsightRow(
              icon: Icons.place_rounded,
              title: 'Ù…ÙˆÙ‚Ø¹ Ø§Ù„Ù…ØªØ¬Ø±',
              value: comparison.localLocationLabel!,
              actionLabel: comparison.localLocationUrl == null
                  ? null
                  : 'Ø±Ø§Ø¨Ø· Ø§Ù„Ù…ÙˆÙ‚Ø¹',
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
          colors: [Color(0xFFE8711A), Color(0xFF16AA83)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'ÙˆÙØ±Øª $savingsPercent%',
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
      child: const Text(
        'ØªÙˆÙÙŠØ± Ø®Ø§Ø±Ù‚',
        style: TextStyle(
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
      child: const Text(
        'Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ø£ØµÙ„ÙŠ Ø¹Ù„ÙŠÙ‡ Ø¹Ø±Ø¶ Ø­Ø§Ù„ÙŠØ§Ù‹',
        style: TextStyle(
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.query,
    required this.selectedCategoryLabel,
    this.searchDemandNotice,
    required this.onReset,
  });

  final String query;
  final String selectedCategoryLabel;
  final String? searchDemandNotice;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    final hasCategoryFilter = selectedCategoryLabel != ProductCategoryCatalog.all.label;
    final hasQueuedSearchDemand = searchDemandNotice?.trim().isNotEmpty ?? false;

    final title = hasQuery
        ? hasQueuedSearchDemand
            ? 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø·Ù„Ø¨ Ø§Ù„Ø¨Ø­Ø« Ø¹Ù† "${query.trim()}".'
            : 'Ù†Ø­Ø¶Ù‘Ø± Ù„Ùƒ Ù†ØªØ§Ø¦Ø¬ Ø£Ø¯Ù‚ Ø¹Ù† "${query.trim()}".'
        : hasCategoryFilter
            ? 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ù…Ù†ØªØ¬Ø§Øª Ø­Ø§Ù„ÙŠØ§Ù‹ Ø¶Ù…Ù† ØªØµÙ†ÙŠÙ "$selectedCategoryLabel".'
            : 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ù…Ù†ØªØ¬Ø§Øª Ù…ØªØ§Ø­Ø© Ø­Ø§Ù„ÙŠØ§Ù‹.';

    final description = hasQuery
        ? hasQueuedSearchDemand
            ? searchDemandNotice!
            : hasCategoryFilter
                ? 'Ù‚Ø¯ ÙŠÙƒÙˆÙ† Ø§Ù„Ù…Ù†ØªØ¬ Ù…ÙˆØ¬ÙˆØ¯Ø§Ù‹ ÙÙŠ ØªØµÙ†ÙŠÙ Ø¢Ø®Ø±ØŒ ÙˆÙŠÙ…ÙƒÙ†Ùƒ Ø¥Ø¹Ø§Ø¯Ø© Ø¶Ø¨Ø· Ø§Ù„ÙÙ„Ø§ØªØ± Ø§Ù„Ø¢Ù†. ÙˆØ¥Ø°Ø§ ÙƒØ§Ù† ØºÙŠØ± Ù…ÙˆØ¬ÙˆØ¯ Ø¨Ø¹Ø¯ØŒ ÙØ³Ù†Ø³Ø¬Ù„ Ø·Ù„Ø¨Ù‡ Ù„ÙŠØ¶ÙŠÙÙ‡ Ø±ÙˆØ¨ÙˆØª Ø§Ù„ØªØ­Ø¯ÙŠØ« Ø§Ù„ÙŠÙˆÙ…ÙŠ Ù„Ø§Ø­Ù‚Ø§Ù‹.'
                : 'Ø¥Ø°Ø§ Ù„Ù… ÙŠÙƒÙ† Ù‡Ø°Ø§ Ø§Ù„Ù…Ù†ØªØ¬ Ù…ÙˆØ¬ÙˆØ¯Ø§Ù‹ Ø¨Ø¹Ø¯ ÙÙŠ Ø§Ù„Ù‚Ø§Ø¹Ø¯Ø© Ø£Ùˆ ÙÙŠ Ù†ØªØ§Ø¦Ø¬ Ø§Ù„ÙˆÙŠØ¨ Ø§Ù„Ù„Ø­Ø¸ÙŠØ©ØŒ ÙØ³ÙŠØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø·Ù„Ø¨Ùƒ Ù„Ø¥Ø¶Ø§ÙØªÙ‡ ØªÙ„Ù‚Ø§Ø¦ÙŠØ§Ù‹ ÙÙŠ Ø§Ù„Ø¬ÙˆÙ„Ø© Ø§Ù„Ù‚Ø§Ø¯Ù…Ø©.'
        : 'ÙŠÙ…ÙƒÙ†Ùƒ ØªØºÙŠÙŠØ± Ø§Ù„ØªØµÙ†ÙŠÙ Ø£Ùˆ Ø§Ù„Ø¨Ø­Ø« Ø¹Ù† Ø§Ø³Ù… Ø§Ù„Ù…Ù†ØªØ¬ Ø£Ùˆ Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù† Ø£Ùˆ Ø­ØªÙ‰ Ø§Ù„Ù…ÙƒÙˆÙ‘Ù†Ø§Øª Ù„Ø¥Ø¸Ù‡Ø§Ø± Ø§Ù„Ù†ØªØ§Ø¦Ø¬ Ø§Ù„Ù…Ù†Ø§Ø³Ø¨Ø©.';

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
            label: const Text('Ø¥Ø¹Ø§Ø¯Ø© Ø¶Ø¨Ø· Ø§Ù„ÙÙ„Ø§ØªØ±'),
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
                ? 'ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ø¨Ù†Ø± Ø¨Ù†Ø¬Ø§Ø­.'
                : 'ØªÙ… ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø¨Ù†Ø± Ø¨Ù†Ø¬Ø§Ø­.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­ÙØ¸ Ø§Ù„Ø¨Ù†Ø± Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
      );
    }
  }

  Future<void> _publishBanner(AdBannerItem banner) async {
    try {
      await widget.catalogService.publishAdBanner(banner.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ØªÙ… ØªØ­Ø¯ÙŠØ« lastUpdated Ù„Ù„Ø¨Ù†Ø± Ø¨Ù†Ø¬Ø§Ø­.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ù†Ø´Ø± Ø§Ù„Ø¨Ù†Ø± Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
      );
    }
  }

  Future<void> _deleteBanner(AdBannerItem banner) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø±'),
            content: Text('Ù‡Ù„ ØªØ±ÙŠØ¯ Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø± "${banner.title}" Ù†Ù‡Ø§Ø¦ÙŠØ§Ù‹ØŸ'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ø¥Ù„ØºØ§Ø¡'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ø­Ø°Ù'),
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
        const SnackBar(content: Text('ØªÙ… Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø±.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø± Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ø¨Ù†Ø±Ø§Øª Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†ÙŠØ©',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2F5E),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Ø£Ø¶Ù Ø£Ùˆ Ø¹Ø¯Ù‘Ù„ Ø£Ùˆ Ø§Ø­Ø°Ù Ø§Ù„Ø¨Ù†Ø±Ø§Øª ÙÙŠ Ù…Ø¬Ù…ÙˆØ¹Ø© ad_bannersØŒ Ø«Ù… Ø§Ø³ØªØ®Ø¯Ù… Ø²Ø± Ø§Ù„Ù†Ø´Ø± Ù„ØªØ­Ø¯ÙŠØ« lastUpdated.',
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
                label: const Text('Ø¥Ø¶Ø§ÙØ© Ø¨Ù†Ø±'),
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
                          'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¨Ù†Ø±Ø§Øª Ù…Ù† Firestore: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6B7A9A)),
                        ),
                      ),
                    );
                  }

                  final banners = snapshot.data ?? const <AdBannerItem>[];
                  if (banners.isEmpty) {
                    return const Center(
                      child: Text(
                        'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø¨Ù†Ø±Ø§Øª Ø¨Ø¹Ø¯. Ø£Ø¶Ù Ø£ÙˆÙ„ Ø¨Ù†Ø± Ù…Ù† Ø§Ù„Ø²Ø± Ø§Ù„Ø¹Ù„ÙˆÙŠ.',
                        style: TextStyle(
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
                        columns: const [
                          DataColumn(label: Text('Ø§Ù„Ù…ØªØ¬Ø±')),
                          DataColumn(label: Text('Ø§Ù„Ø¹Ù†ÙˆØ§Ù†')),
                          DataColumn(label: Text('Ø§Ù„ØªØ±ØªÙŠØ¨')),
                          DataColumn(label: Text('Ø§Ù„Ø­Ø§Ù„Ø©')),
                          DataColumn(label: Text('Ø§Ù„ØµÙˆØ±Ø©')),
                          DataColumn(label: Text('Ø§Ù„Ø¥Ø¬Ø±Ø§Ø¡Ø§Øª')),
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
                                  label: banner.active ? 'Ù†Ø´Ø·' : 'Ù…Ø®ÙÙŠ',
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
                                        child: const Text('ØªØ¹Ø¯ÙŠÙ„'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _publishBanner(banner),
                                        child: const Text('Ù†Ø´Ø±'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _deleteBanner(banner),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFC24E4E),
                                        ),
                                        child: const Text('Ø­Ø°Ù'),
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
                ? 'ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ù…Ù†ØªØ¬ Ø¨Ù†Ø¬Ø§Ø­.'
                : 'ØªÙ… ØªØ­Ø¯ÙŠØ« Ø§Ù„Ù…Ù†ØªØ¬ Ø¨Ù†Ø¬Ø§Ø­.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­ÙØ¸ Ø§Ù„Ù…Ù†ØªØ¬ Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
      );
    }
  }

  Future<void> _publishProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ø§Ø­ÙØ¸ Ø§Ù„Ù…Ù†ØªØ¬ Ø£ÙˆÙ„Ø§Ù‹ Ù‚Ø¨Ù„ Ù†Ø´Ø±Ù‡.')),
      );
      return;
    }

    try {
      await widget.catalogService.publishProduct(documentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ØªÙ… ØªØ­Ø¯ÙŠØ« lastUpdated Ù„Ù„Ù…Ù†ØªØ¬ Ø¨Ù†Ø¬Ø§Ø­.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ù†Ø´Ø± Ø§Ù„Ù…Ù†ØªØ¬ Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
      );
    }
  }

  Future<void> _deleteProduct(ProductComparison product) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ù‡Ø°Ø§ Ø§Ù„Ù…Ù†ØªØ¬ ØºÙŠØ± Ù…Ø±ØªØ¨Ø· Ø¨ÙˆØ«ÙŠÙ‚Ø© Firestore.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ø­Ø°Ù Ø§Ù„Ù…Ù†ØªØ¬'),
            content: Text(
              'Ù‡Ù„ ØªØ±ÙŠØ¯ Ø­Ø°Ù "${product.expensiveName}" Ùˆ"${product.alternativeName}" Ù†Ù‡Ø§Ø¦ÙŠØ§Ù‹ØŸ',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ø¥Ù„ØºØ§Ø¡'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ø­Ø°Ù'),
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
        const SnackBar(content: Text('ØªÙ… Ø­Ø°Ù Ø§Ù„Ù…Ù†ØªØ¬.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­Ø°Ù Ø§Ù„Ù…Ù†ØªØ¬ Ø­Ø§Ù„ÙŠØ§Ù‹: $error')),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2F5E),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Ø¹Ø¯Ù‘Ù„ Ø§Ù„Ø£Ø³Ù…Ø§Ø¡ ÙˆØ§Ù„Ø£Ø³Ø¹Ø§Ø± ÙˆØ§Ù„ØµÙˆØ± Ù…Ø¨Ø§Ø´Ø±Ø© ÙÙŠ Ù…Ø¬Ù…ÙˆØ¹Ø© productsØŒ Ø«Ù… Ø§Ø³ØªØ®Ø¯Ù… Ø²Ø± Ø§Ù„Ù†Ø´Ø± Ù„ØªØ­Ø¯ÙŠØ« lastUpdated.',
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
                label: const Text('Ø¥Ø¶Ø§ÙØ© Ù…Ù†ØªØ¬'),
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
                          'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª Ù…Ù† Firestore: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6B7A9A)),
                        ),
                      ),
                    );
                  }

                  final products = snapshot.data ?? const <ProductComparison>[];
                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        'Ù„Ø§ ØªÙˆØ¬Ø¯ Ù…Ù†ØªØ¬Ø§Øª Ø¨Ø¹Ø¯. Ø£Ø¶Ù Ø£ÙˆÙ„ Ù…Ù†ØªØ¬ Ù…Ù† Ø§Ù„Ø²Ø± Ø§Ù„Ø¹Ù„ÙˆÙŠ.',
                        style: TextStyle(
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
                        columns: const [
                          DataColumn(label: Text('Ø§Ù„Ù‚Ø³Ù…')),
                          DataColumn(label: Text('Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…Ø±Ø¬Ø¹ÙŠ')),
                          DataColumn(label: Text('Ø³Ø¹Ø±Ù‡')),
                          DataColumn(label: Text('Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†')),
                          DataColumn(label: Text('Ø³Ø¹Ø±Ù‡')),
                          DataColumn(label: Text('Ø§Ù„ØµÙˆØ±')),
                          DataColumn(label: Text('Ø§Ù„Ø±Ø§Ø¨Ø·')),
                          DataColumn(label: Text('Ø§Ù„Ø¥Ø¬Ø±Ø§Ø¡Ø§Øª')),
                        ],
                        rows: products.map((product) {
                          return DataRow(
                            cells: [
                              DataCell(Text(product.categoryLabel)),
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
                                        ? 'Ø¨Ø¯ÙˆÙ† Ø±Ø§Ø¨Ø·'
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
                                        child: const Text('ØªØ¹Ø¯ÙŠÙ„'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _publishProduct(product),
                                        child: const Text('Ù†Ø´Ø±'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _deleteProduct(product),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFC24E4E),
                                        ),
                                        child: const Text('Ø­Ø°Ù'),
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
                const Text(
                  'ØªØ¹Ø°Ø± Ø¨Ù†Ø§Ø¡ ÙˆØ§Ø¬Ù‡Ø© Ø§Ù„Ø¥Ø¯Ø§Ø±Ø©',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
      return '$label Ù…Ø·Ù„ÙˆØ¨.';
    }
    return null;
  }

  String? _validateUrl(String? value, {bool required = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return required ? 'Ù‡Ø°Ø§ Ø§Ù„Ø±Ø§Ø¨Ø· Ù…Ø·Ù„ÙˆØ¨.' : null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Ø£Ø¯Ø®Ù„ Ø±Ø§Ø¨Ø·Ø§Ù‹ ØµØ§Ù„Ø­Ø§Ù‹ ÙŠØ¨Ø¯Ø£ Ø¨Ù€ http Ø£Ùˆ https.';
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
                        ? 'Ø¥Ø¶Ø§ÙØ© Ø¨Ù†Ø± Ø¬Ø¯ÙŠØ¯'
                        : 'ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø¨Ù†Ø±',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _storeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ø§Ø³Ù… Ø§Ù„Ù…ØªØ¬Ø±',
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                    validator: (value) => _validateRequired(value, 'Ø§Ø³Ù… Ø§Ù„Ù…ØªØ¬Ø±'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Ø¹Ù†ÙˆØ§Ù† Ø§Ù„Ø¨Ù†Ø±',
                      prefixIcon: Icon(Icons.campaign_rounded),
                    ),
                    validator: (value) => _validateRequired(value, 'Ø¹Ù†ÙˆØ§Ù† Ø§Ù„Ø¨Ù†Ø±'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _subtitleController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ø§Ù„ÙˆØµÙ Ø§Ù„Ù…Ø®ØªØµØ±',
                      prefixIcon: Icon(Icons.subject_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _imageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Ø±Ø§Ø¨Ø· Ø§Ù„ØµÙˆØ±Ø©',
                      prefixIcon: Icon(Icons.image_rounded),
                    ),
                    validator: (value) => _validateUrl(value, required: true),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _targetUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Ø±Ø§Ø¨Ø· Ø§Ù„ÙˆØ¬Ù‡Ø©',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _orderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ø§Ù„ØªØ±ØªÙŠØ¨',
                      prefixIcon: Icon(Icons.format_list_numbered_rounded),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 0) {
                        return 'Ø£Ø¯Ø®Ù„ Ø±Ù‚Ù…Ø§Ù‹ ØµØ­ÙŠØ­Ø§Ù‹ Ù„Ù„ØªØ±ØªÙŠØ¨.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _active,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ø§Ù„Ø¨Ù†Ø± Ù†Ø´Ø·'),
                    subtitle: const Text('Ø§Ù„Ø¨Ù†Ø±Ø§Øª ØºÙŠØ± Ø§Ù„Ù†Ø´Ø·Ø© Ù„Ù† ØªØ¸Ù‡Ø± Ù„Ù„Ù…Ø³ØªØ®Ø¯Ù…ÙŠÙ†.'),
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
                          child: const Text('Ø¥Ù„ØºØ§Ø¡'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text('Ø­ÙØ¸'),
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
      return '$label Ù…Ø·Ù„ÙˆØ¨.';
    }
    return null;
  }

  String? _validatePrice(String? value, String label) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Ø£Ø¯Ø®Ù„ Ù‚ÙŠÙ…Ø© ØµØ­ÙŠØ­Ø© Ù„Ù€ $label.';
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
      return 'Ø£Ø¯Ø®Ù„ Ø±Ø§Ø¨Ø·Ø§Ù‹ ØµØ§Ù„Ø­Ø§Ù‹ ÙŠØ¨Ø¯Ø£ Ø¨Ù€ http Ø£Ùˆ https.';
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
                        ? 'Ø¥Ø¶Ø§ÙØ© Ù…Ù†ØªØ¬ Ø¬Ø¯ÙŠØ¯'
                        : 'ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ù…Ù†ØªØ¬',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Ø§Ù„Ù‚Ø³Ù…',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.label),
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
                    decoration: const InputDecoration(
                      labelText: 'Ø§Ø³Ù… Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…Ø±Ø¬Ø¹ÙŠ',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) =>
                        _validateRequired(value, 'Ø§Ø³Ù… Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…Ø±Ø¬Ø¹ÙŠ'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expensivePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ø³Ø¹Ø± Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…Ø±Ø¬Ø¹ÙŠ',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    validator: (value) =>
                        _validatePrice(value, 'Ø³Ø¹Ø± Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…Ø±Ø¬Ø¹ÙŠ'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expensiveImageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Ø±Ø§Ø¨Ø· ØµÙˆØ±Ø© Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…Ø±Ø¬Ø¹ÙŠ',
                      prefixIcon: Icon(Icons.image_search_rounded),
                    ),
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ø§Ø³Ù… Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†',
                      prefixIcon: Icon(Icons.swap_horiz_rounded),
                    ),
                    validator: (value) =>
                        _validateRequired(value, 'Ø§Ø³Ù… Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ø³Ø¹Ø± Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†',
                      prefixIcon: Icon(Icons.savings_rounded),
                    ),
                    validator: (value) =>
                        _validatePrice(value, 'Ø³Ø¹Ø± Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativeImageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Ø±Ø§Ø¨Ø· ØµÙˆØ±Ø© Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†',
                      prefixIcon: Icon(Icons.image_search_rounded),
                    ),
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _buyUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Ø±Ø§Ø¨Ø· Ø§Ù„Ø´Ø±Ø§Ø¡ Ø£Ùˆ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†',
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
                          child: const Text('Ø¥Ù„ØºØ§Ø¡'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text('Ø­ÙØ¸'),
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
        'Ø¥Ø¶Ø§ÙØ© Ù…Ø³Ø¤ÙˆÙ„',
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
    _categoryController.text = 'Ù‚Ù‡ÙˆØ©';
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
        _passwordError = 'ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± ØºÙŠØ± ØµØ­ÙŠØ­Ø©.';
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

  String? _validateRequired(String? value, {String label = 'Ù‡Ø°Ø§ Ø§Ù„Ø­Ù‚Ù„'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label Ù…Ø·Ù„ÙˆØ¨.';
    }

    return null;
  }

  String? _validatePrice(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return '$label Ù…Ø·Ù„ÙˆØ¨.';
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Ø£Ø¯Ø®Ù„ Ù‚ÙŠÙ…Ø© ØµØ­ÙŠØ­Ø© Ù„Ù€ $label.';
    }

    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Ø£Ø¯Ø®Ù„ Ø±Ø§Ø¨Ø·Ø§Ù‹ ØµØ§Ù„Ø­Ø§Ù‹ ÙŠØ¨Ø¯Ø£ Ø¨Ù€ http Ø£Ùˆ httpsØŒ Ø£Ùˆ Ø§ØªØ±Ùƒ Ø§Ù„Ø­Ù‚Ù„ ÙØ§Ø±ØºØ§Ù‹.';
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ù„ÙˆØ­Ø© Ø§Ù„Ù…Ø³Ø¤ÙˆÙ„',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF17332B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ø£Ø¶Ù Ù…Ù†ØªØ¬Ø§Ù‹ Ø¬Ø¯ÙŠØ¯Ø§Ù‹ Ù„ÙŠØ¸Ù‡Ø± ÙÙˆØ±Ø§Ù‹ Ø¯Ø§Ø®Ù„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚.',
                              style: TextStyle(
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
                      labelText: 'ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±',
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
                    validator: (value) =>
                        _validateRequired(value, label: 'ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _originalNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ø§Ø³Ù… Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…Ø±Ø¬Ø¹ÙŠ',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) =>
                        _validateRequired(value, label: 'Ø§Ø³Ù… Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…Ø±Ø¬Ø¹ÙŠ'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _originalPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ø³Ø¹Ø± Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…Ø±Ø¬Ø¹ÙŠ',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    validator: (value) =>
                        _validatePrice(value, label: 'Ø³Ø¹Ø± Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…Ø±Ø¬Ø¹ÙŠ'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ø§Ø³Ù… Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†',
                      prefixIcon: Icon(Icons.swap_horiz_rounded),
                    ),
                    validator: (value) =>
                        _validateRequired(value, label: 'Ø§Ø³Ù… Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ø³Ø¹Ø± Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†',
                      prefixIcon: Icon(Icons.savings_rounded),
                    ),
                    validator: (value) =>
                        _validatePrice(value, label: 'Ø³Ø¹Ø± Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _affiliateUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Ø±Ø§Ø¨Ø· Ø§Ù„Ø´Ø±Ø§Ø¡ Ø£Ùˆ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù† (Ø§Ø®ØªÙŠØ§Ø±ÙŠ)',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Ø§Ù„Ù‚Ø³Ù…',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    validator: (value) =>
                        _validateRequired(value, label: 'Ø§Ù„Ù‚Ø³Ù…'),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Ø¥Ù„ØºØ§Ø¡'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text('Ø­ÙØ¸'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ÙŠÙ…ÙƒÙ† ØªØºÙŠÙŠØ± ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ù…Ù† Ø§Ù„Ø«Ø§Ø¨Øª adminPassword Ø¯Ø§Ø®Ù„ LeastPriceDataConfig.',
                    style: TextStyle(
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
            const Text(
              'ØªÙ‚ÙŠÙŠÙ… Ø¬ÙˆØ¯Ø© Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ù…Ù‚Ø§Ø±Ù†',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17332B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ÙƒÙŠÙ ØªØ±Ù‰ "${widget.product.alternativeName}" Ù…Ù† Ø­ÙŠØ« Ø§Ù„Ø¬ÙˆØ¯Ø© ÙˆØ§Ù„Ù…ÙƒÙˆÙ‘Ù†Ø§Øª Ù…Ù‚Ø§Ø±Ù†Ø©Ù‹ Ø¨Ù€ "${widget.product.expensiveName}"ØŸ',
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
                '${_selectedRating.toStringAsFixed(1)} Ù…Ù† 5',
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
                    child: const Text('Ø¥Ù„ØºØ§Ø¡'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selectedRating),
                    child: const Text('Ø¥Ø±Ø³Ø§Ù„ Ø§Ù„ØªÙ‚ÙŠÙŠÙ…'),
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
          'Ø£Ù†Ø§ ÙˆÙØ±Øª {SAVED_AMOUNT} Ø±ÙŠØ§Ù„ Ø¨Ø§Ø³ØªØ®Ø¯Ø§Ù… ØªØ·Ø¨ÙŠÙ‚ Ø£Ø±Ø®Øµ Ø³Ø¹Ø±! '
          'Ø­Ù…Ù„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¢Ù† ÙˆØ§Ø³ØªØ®Ø¯Ù… ÙƒÙˆØ¯ Ø§Ù„Ø¯Ø¹ÙˆØ© Ø§Ù„Ø®Ø§Øµ Ø¨ÙŠ: {USER_CODE}\n{APP_LINK}',
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
          'Ø£Ù†Ø§ ÙˆÙØ±Øª {SAVED_AMOUNT} Ø±ÙŠØ§Ù„ Ø¨Ø§Ø³ØªØ®Ø¯Ø§Ù… ØªØ·Ø¨ÙŠÙ‚ Ø£Ø±Ø®Øµ Ø³Ø¹Ø±! '
              'Ø­Ù…Ù„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¢Ù† ÙˆØ§Ø³ØªØ®Ø¯Ù… ÙƒÙˆØ¯ Ø§Ù„Ø¯Ø¹ÙˆØ© Ø§Ù„Ø®Ø§Øµ Ø¨ÙŠ: {USER_CODE}\n{APP_LINK}',
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
      return 'Ø§Ù„Ø±ÙˆØ¨ÙˆØª: Ø¨Ø§Ù†ØªØ¸Ø§Ø± Ø£ÙˆÙ„ ØªØ´ØºÙŠÙ„';
    }
    return 'Ø¢Ø®Ø± ØªØ­Ø¯ÙŠØ« ${_formatHealthTimestamp(lastSuccessAt)}';
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
        return 'Ø±Ø§Ø¨Ø· Ø®Ø§Ø±Ø¬ÙŠ';
      case ProductDataSource.asset:
        return 'Ù…Ù„Ù JSON';
      case ProductDataSource.mock:
        return 'Ø¨ÙŠØ§Ù†Ø§Øª ØªØ¬Ø±ÙŠØ¨ÙŠØ©';
    }
  }
}

class LeastPriceDataConfig {
  const LeastPriceDataConfig._();

  static const String productsCollectionName = 'products';
  static const String adBannersCollectionName = 'ad_banners';
  static const String usersCollectionName = 'users';
  static const String popularProductsCollectionName = 'popular_products';
  static const String searchRequestsCollectionName = 'search_requests';
  static const String systemHealthCollectionName = 'system_health';
  static const String systemHealthDocumentId = 'daily_price_bot';
  static const String remoteJsonUrl =
      'https://your-domain.com/leastprice-feed.json';
  static const String assetJsonPath = 'assets/data/products.json';
  static const String appShareUrl = 'https://leastprice.app';
  static const String adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: 'yaser.haroon79@gmail.com',
  );
  static const String adminPassword = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: 'leastprice123',
  );
  static const String affiliateTag = 'myid-21';
  static const String originalOnSaleTag = 'Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ø£ØµÙ„ÙŠ Ø¹Ù„ÙŠÙ‡ Ø¹Ø±Ø¶ Ø­Ø§Ù„ÙŠØ§Ù‹';
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
        notice: 'Ø§Ù„ØªØ­Ø¯ÙŠØ« Ø§Ù„ØªÙ„Ù‚Ø§Ø¦ÙŠ Ù„Ù„Ø£Ø³Ø¹Ø§Ø± Ù…Ø¹Ø·Ù„ Ø­Ø§Ù„ÙŠØ§Ù‹ Ù…Ù† Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª.',
      );
    }

    final searchClient = SearchAutomationClient.fromConfig();
    if (searchClient == null) {
      return CatalogRefreshResult(
        products: products,
        notice:
            'ØªÙ… ØªÙØ¹ÙŠÙ„ Ù…Ù†Ø·Ù‚ Ø§Ù„ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø°ÙƒÙŠ Ù„Ù„Ø£Ø³Ø¹Ø§Ø±ØŒ Ù„ÙƒÙ†Ù‡ ÙŠØ­ØªØ§Ø¬ Ù…ÙØªØ§Ø­ API ØµØ§Ù„Ø­Ø§Ù‹ Ù„Ù€ Serper Ø£Ùˆ Tavily.',
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
          ? 'ØªÙ… ØªØ­Ø¯ÙŠØ« $refreshedCount Ù…Ù†ØªØ¬Ø§Ù‹ ØªÙ„Ù‚Ø§Ø¦ÙŠØ§Ù‹ Ù…Ù† Ù†ØªØ§Ø¦Ø¬ Ø§Ù„Ø¨Ø­Ø« Ø§Ù„Ø³Ø¹ÙˆØ¯ÙŠØ©.'
          : 'Ù„Ù… ÙŠØªÙ… Ø§Ù„Ø¹Ø«ÙˆØ± Ø¹Ù„Ù‰ Ø£Ø³Ø¹Ø§Ø± Ø£Ø­Ø¯Ø« Ù…Ù† Ù…ÙˆØµÙ„ Ø§Ù„Ø¨Ø­Ø« Ø§Ù„Ø­Ø§Ù„ÙŠØŒ ÙØªÙ… Ø§Ù„Ø¥Ø¨Ù‚Ø§Ø¡ Ø¹Ù„Ù‰ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø­Ø§Ù„ÙŠØ©.',
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
    return '${product.expensiveName} site:amazon.sa OR site:noon.com Ø§Ù„Ø³Ø¹ÙˆØ¯ÙŠØ© Ø³Ø¹Ø±';
  }

  String _buildAlternativeQuery(ProductComparison product) {
    return '${product.alternativeName} Ø§Ù„Ø³Ø¹ÙˆØ¯ÙŠØ© Ø³Ø¹Ø± '
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
      RegExp(r'(?:Ø±\.?\s?Ø³|Ø±ÙŠØ§Ù„|SAR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
          caseSensitive: false),
      RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:Ø±\.?\s?Ø³|Ø±ÙŠØ§Ù„|SAR)',
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
      return const SmartSearchDiscoveryResult(
        products: <ProductComparison>[],
        notice:
            'Ù„ØªÙØ¹ÙŠÙ„ Ø§Ù„Ø¨Ø­Ø« Ø§Ù„Ø°ÙƒÙŠ Ù…Ù† Ø§Ù„ÙˆÙŠØ¨ Ø£Ø¶Ù Ù…ÙØªØ§Ø­ Serper Ø£Ùˆ Tavily Ø¹Ø¨Ø± --dart-define.',
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
      return const SmartSearchDiscoveryResult(
        products: <ProductComparison>[],
        notice:
            'Ù„Ù… ØªØªÙˆÙØ± Ø¨Ø¹Ø¯ Ø£Ø³Ø¹Ø§Ø± ÙˆÙŠØ¨ ÙƒØ§ÙÙŠØ© Ù„ØªÙƒÙˆÙŠÙ† Ø¨Ø·Ø§Ù‚Ø© Ù…Ù‚Ø§Ø±Ù†Ø© Ø¬Ø¯ÙŠØ¯Ø©ØŒ Ù„Ø°Ù„Ùƒ Ø³Ù†Ø¹ØªÙ…Ø¯ Ø¹Ù„Ù‰ Ø§Ù„Ù‚Ø§Ø¹Ø¯Ø© Ø§Ù„Ø­Ø§Ù„ÙŠØ© Ø£Ùˆ Ø·Ù„Ø¨ Ø§Ù„Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ù‚Ø§Ø¯Ù….',
      );
    }

    final suggestions = _buildSuggestedComparisons(
      query: query,
      candidates: candidates,
      existingProducts: existingProducts,
    );

    if (suggestions.isEmpty) {
      return const SmartSearchDiscoveryResult(
        products: <ProductComparison>[],
        notice:
            'Ù†ØªØ§Ø¦Ø¬ Ø§Ù„ÙˆÙŠØ¨ Ø§Ù„Ø­Ø§Ù„ÙŠØ© ÙƒØ§Ù†Øª Ù‚Ø±ÙŠØ¨Ø© Ù…Ù† Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…ÙˆØ¬ÙˆØ¯Ø© Ù…Ø³Ø¨Ù‚Ø§Ù‹ØŒ Ù„Ø°Ù„Ùƒ Ù„Ù… Ù†Ø¶Ù Ø¨Ø·Ø§Ù‚Ø© Ø¬Ø¯ÙŠØ¯Ø© Ø§Ù„Ø¢Ù†.',
      );
    }

    return SmartSearchDiscoveryResult(
      products: suggestions,
      notice:
          'ØªÙ… ØªÙˆÙ„ÙŠØ¯ ${suggestions.length} Ø¨Ø·Ø§Ù‚Ø© Ø°ÙƒÙŠØ© Ù…Ù† Ù†ØªØ§Ø¦Ø¬ Ø§Ù„ÙˆÙŠØ¨ Ø­ØªÙ‰ Ù„Ùˆ Ù„Ù… ØªÙƒÙ† Ù…ÙˆØ¬ÙˆØ¯Ø© ÙÙŠ Ù‚Ø§Ø¹Ø¯Ø© Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª.',
    );
  }

  String _buildDiscoveryQuery({
    required String query,
    required String selectedCategoryId,
  }) {
    final categoryHint = selectedCategoryId == ProductCategoryCatalog.allId
        ? ''
        : '${ProductCategoryCatalog.lookup(selectedCategoryId).label} ';

    return '$query $categoryHintØ³Ø¹Ø± Ù…ÙƒÙˆÙ†Ø§Øª Ø§Ù„Ø³Ø¹ÙˆØ¯ÙŠØ© '
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
      fallbackLabel: 'Ù…Ù‚Ø§Ø±Ù†Ø© Ø°ÙƒÙŠØ©',
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
          'Ø¨Ø­Ø« Ø°ÙƒÙŠ',
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

    final separators = [' | ', ' - ', ' â€“ ', ' â€” ', ' â€¢ '];
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
      RegExp(r'(?:Ø§Ù„Ù…ÙƒÙˆÙ†Ø§Øª|Ø§Ù„Ù…Ø§Ø¯Ø© Ø§Ù„ÙØ¹Ø§Ù„Ø©|ingredients?|active ingredients?)[:\-]\s*([^.\n]{12,120})',
          caseSensitive: false),
      RegExp(r'(?:Ø§Ù„Ù†ÙˆØªØ©|Ø§Ù„Ù†ÙØ­Ø§Øª|notes?)[:\-]\s*([^.\n]{12,120})',
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
    if (normalized.contains('nahdi')) return 'Ø§Ù„Ù†Ù‡Ø¯ÙŠ';
    if (normalized.contains('dawaa')) return 'Ø§Ù„Ø¯ÙˆØ§Ø¡';
    if (normalized.contains('hungerstation')) return 'HungerStation';
    if (normalized.contains('jahez')) return 'Ø¬Ø§Ù‡Ø²';
    if (normalized.contains('mrsool')) return 'Ù…Ø±Ø³ÙˆÙ„';
    return host;
  }

  double? _extractPrice(String title, String snippet) {
    final text = '$title $snippet'.replaceAll(',', '');
    final patterns = [
      RegExp(
        r'(?:Ø±\.?\s?Ø³|Ø±ÙŠØ§Ù„|SAR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:Ø±\.?\s?Ø³|Ø±ÙŠØ§Ù„|SAR)',
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
        inviteCode = await _generateUniqueReferralCode();
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

    final referralCode = await _generateUniqueReferralCode();
    final normalizedInviteCode = pendingInviteCode?.trim().toUpperCase() ?? '';
    var invitedBy = '';

    if (normalizedInviteCode.isNotEmpty && normalizedInviteCode != referralCode) {
      final referrer = await _findUserByReferralCode(normalizedInviteCode);
      if (referrer != null && referrer.id != user.uid) {
        invitedBy = normalizedInviteCode;
      }
    }

    final profile = UserSavingsProfile(
      userId: user.uid,
      phoneNumber: phoneNumber,
      inviteCode: referralCode,
      invitedBy: invitedBy,
      invitedFriendsCount: 0,
      referralRewardApplied: false,
      shareBaseUrl: LeastPriceDataConfig.appShareUrl,
      inviteMessageTemplate:
          'Ø£Ù†Ø§ ÙˆÙØ±Øª {SAVED_AMOUNT} Ø±ÙŠØ§Ù„ Ø¨Ø§Ø³ØªØ®Ø¯Ø§Ù… ØªØ·Ø¨ÙŠÙ‚ Ø£Ø±Ø®Øµ Ø³Ø¹Ø±! '
          'Ø­Ù…Ù„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¢Ù† ÙˆØ§Ø³ØªØ®Ø¯Ù… ÙƒÙˆØ¯ Ø§Ù„Ø¯Ø¹ÙˆØ© Ø§Ù„Ø®Ø§Øµ Ø¨ÙŠ: {USER_CODE}\n{APP_LINK}',
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
    final Query<Map<String, dynamic>> query =
        normalizedCategoryId.isEmpty ||
            normalizedCategoryId == ProductCategoryCatalog.allId
        ? _productsCollection
        : _productsCollection.where('categoryId', isEqualTo: normalizedCategoryId);

    return query.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map(ProductComparison.fromFirestore)
          .where(
            (product) =>
                product.expensiveName.trim().isNotEmpty &&
                product.alternativeName.trim().isNotEmpty,
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
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(requestDocument);
      final existingCount = snapshot.exists
          ? _intValue(snapshot.data()?['requestCount'])
          : 0;

      transaction.set(
        requestDocument,
        {
          'query': trimmedQuery,
          'normalizedQuery': normalizedQuery,
          'categoryId': normalizedCategoryId,
          'categoryLabel': categoryLabel,
          'requestCount': existingCount + 1,
          'status': 'pending',
          'source': 'app_search',
          'lastRequestedAt': FieldValue.serverTimestamp(),
          if (!snapshot.exists)
            'firstRequestedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
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

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findUserByReferralCode(
    String referralCode,
  ) async {
    final result = await _usersCollection
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();
    if (result.docs.isEmpty) {
      return null;
    }

    return result.docs.first;
  }

  Future<String> _generateUniqueReferralCode() async {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = math.Random();

    for (var attempt = 0; attempt < 18; attempt++) {
      final suffix = List.generate(
        6,
        (_) => alphabet[random.nextInt(alphabet.length)],
      ).join();
      final code = 'LP-$suffix';
      final existing = await _usersCollection
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        return code;
      }
    }

    throw const FormatException('Unable to generate unique referral code');
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
        notice = 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø£Ø­Ø¯Ø« Ø§Ù„Ø£Ø³Ø¹Ø§Ø± Ù…Ù† Ø§Ù„Ø±Ø§Ø¨Ø· Ø§Ù„Ø®Ø§Ø±Ø¬ÙŠØŒ Ù„Ø°Ù„Ùƒ ØªÙ… Ø§Ø³ØªØ®Ø¯Ø§Ù… Ù…ØµØ¯Ø± Ø¨Ø¯ÙŠÙ„.';
      }
    } else if (remoteUrl.isNotEmpty) {
      notice =
          'ØªÙ… ØªÙØ¹ÙŠÙ„ remoteJsonUrl ÙƒØ±Ø§Ø¨Ø· Ù†Ù…ÙˆØ°Ø¬ÙŠ. Ø§Ø³ØªØ¨Ø¯Ù„Ù‡ Ø¨Ø±Ø§Ø¨Ø·Ùƒ Ø§Ù„Ø­Ù‚ÙŠÙ‚ÙŠ Ù„Ø¨Ø¯Ø¡ Ø§Ù„ØªØ­ÙƒÙ… Ø¹Ù† Ø¨Ø¹Ø¯ Ø¨Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª.';
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
          'Ù„Ù… ÙŠØªÙ… Ø§Ù„Ø¹Ø«ÙˆØ± Ø¹Ù„Ù‰ Ù…Ù„Ù JSON Ø®Ø§Ø±Ø¬ÙŠØŒ Ù„Ø°Ù„Ùƒ ØªÙ… Ø¹Ø±Ø¶ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„ØªØ¬Ø±ÙŠØ¨ÙŠØ© Ø§Ù„Ø­Ø§Ù„ÙŠØ©.';
    }

    return ProductLoadResult(
      products: _normalizeLoadedProducts(ProductComparison.mockData),
      source: ProductDataSource.mock,
      referralProfile: UserSavingsProfile.initial(),
      notice: notice ??
          'ÙŠÙ…ÙƒÙ†Ùƒ Ù„Ø§Ø­Ù‚Ø§Ù‹ Ø±Ø¨Ø· Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø¨Ù…Ù„Ù JSON Ø£Ùˆ Ø±Ø§Ø¨Ø· URL Ù„ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø£Ø³Ø¹Ø§Ø± Ø¨Ø¯ÙˆÙ† Ø¥Ø¹Ø§Ø¯Ø© Ù†Ø´Ø± Ø§Ù„ØªØ·Ø¨ÙŠÙ‚.',
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
      title: _stringValue(json['title']) ?? 'Ø¹Ø±Ø¶ Ù…ØªØ¬Ø±',
      subtitle: _stringValue(json['subtitle']) ?? 'Ø®ØµÙˆÙ…Ø§Øª ÙŠÙˆÙ…ÙŠØ© Ø¯Ø§Ø®Ù„ Ø£Ø±Ø®Øµ Ø³Ø¹Ø±',
      imageUrl: _normalizedImageUrl(
        _stringValue(json['imageUrl']) ?? '',
        fallbackLabel: _stringValue(json['title']) ?? 'LeastPrice Banner',
      ),
      targetUrl: _stringValue(json['targetUrl']) ?? '',
      storeName: _stringValue(json['storeName']) ?? 'Ù…ØªØ¬Ø± Ù…ØªØ¹Ø§Ù‚Ø¯',
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

  static const List<AdBannerItem> mockData = [
    AdBannerItem(
      id: 'local-roaster',
      title: 'Ø¹Ø±Ø¶ Ø§Ù„Ù…Ø­Ù…ØµØ© Ø§Ù„Ù…Ù…ÙŠØ²Ø©',
      subtitle: 'Ø®ØµÙ… Ø¹Ù„Ù‰ Ø§Ù„Ù‚Ù‡ÙˆØ© Ø§Ù„Ù…Ø®ØªØµØ© ÙˆØ­Ø¨ÙˆØ¨ Ø§Ù„ÙŠÙˆÙ… Ù…Ø¹ ØªÙˆØµÙŠÙ„ Ø³Ø±ÙŠØ¹.',
      imageUrl:
          'https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=1400&q=80',
      targetUrl: 'https://leastprice.app/offers/roaster',
      storeName: 'Ù…Ø­Ù…ØµØ© Ø§Ù„Ø´Ø±Ù‚ÙŠØ©',
      active: true,
      order: 1,
    ),
    AdBannerItem(
      id: 'restaurant-partner',
      title: 'ÙˆØ¬Ø¨Ø§Øª Ù…Ø­Ù„ÙŠØ© Ø¨Ø³Ø¹Ø± Ø£ÙØ¶Ù„',
      subtitle: 'Ø¹Ø±ÙˆØ¶ Ø­ØµØ±ÙŠØ© Ù…Ù† Ù…Ø·Ø§Ø¹Ù… Ø§Ù„Ø®Ø¨Ø± ÙˆØ§Ù„Ø¯Ù…Ø§Ù… Ø¯Ø§Ø®Ù„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚.',
      imageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1400&q=80',
      targetUrl: 'https://leastprice.app/offers/restaurants',
      storeName: 'Ø´Ø±ÙƒØ§Ø¡ Ø§Ù„Ù…Ø·Ø§Ø¹Ù…',
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
    label: 'Ø§Ù„ÙƒÙ„',
    icon: Icons.grid_view_rounded,
    color: Color(0xFFE8711A),
  );

  static const List<ProductCategory> defaults = [
    all,
    ProductCategory(
      id: 'coffee',
      label: 'Ù‚Ù‡ÙˆØ©',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF8C5A2B),
    ),
    ProductCategory(
      id: 'roasters',
      label: 'Ù…Ø­Ø§Ù…Øµ',
      icon: Icons.coffee_maker_rounded,
      color: Color(0xFFA54E2A),
    ),
    ProductCategory(
      id: 'restaurants',
      label: 'Ù…Ø·Ø§Ø¹Ù…',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE85D3F),
    ),
    ProductCategory(
      id: 'perfumes',
      label: 'Ø¹Ø·ÙˆØ±',
      icon: Icons.spa_rounded,
      color: Color(0xFFB05CC8),
    ),
    ProductCategory(
      id: 'cosmetics',
      label: 'ØªØ¬Ù…ÙŠÙ„',
      icon: Icons.face_retouching_natural_rounded,
      color: Color(0xFFE06F8A),
    ),
    ProductCategory(
      id: 'pharmacy',
      label: 'ØµÙŠØ¯Ù„ÙŠØ©',
      icon: Icons.local_pharmacy_rounded,
      color: Color(0xFF2F9E93),
    ),
    ProductCategory(
      id: 'detergents',
      label: 'Ù…Ù†Ø¸ÙØ§Øª',
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF4D7CFE),
    ),
    ProductCategory(
      id: 'dairy',
      label: 'Ø£Ù„Ø¨Ø§Ù†',
      icon: Icons.local_drink_rounded,
      color: Color(0xFF3FA87B),
    ),
    ProductCategory(
      id: 'canned',
      label: 'Ù…Ø¹Ù„Ø¨Ø§Øª',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF8A6C3F),
    ),
    ProductCategory(
      id: 'tea',
      label: 'Ø´Ø§ÙŠ',
      icon: Icons.emoji_food_beverage_rounded,
      color: Color(0xFF7B8E2F),
    ),
    ProductCategory(
      id: 'juice',
      label: 'Ø¹ØµÙŠØ±',
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

    if (normalized.contains('Ù…Ø­Ù…Øµ') || normalized.contains('Ø¨Ù†') || normalized.contains('Ø­Ø¨ÙˆØ¨')) {
      return 'roasters';
    }
    if (normalized.contains('Ù‚Ù‡ÙˆÙ‡')) return 'coffee';
    if (normalized.contains('Ù…Ø·Ø¹Ù…') ||
        normalized.contains('ÙˆØ¬Ø¨Ù‡') ||
        normalized.contains('Ø¨Ø±Ø¬Ø±')) {
      return 'restaurants';
    }
    if (normalized.contains('Ø¹Ø·Ø±') ||
        normalized.contains('Ø¨Ø±ÙÙŠÙˆÙ…') ||
        normalized.contains('Ø±Ø§Ø¦Ø­Ù‡')) {
      return 'perfumes';
    }
    if (normalized.contains('ØªØ¬Ù…ÙŠÙ„') ||
        normalized.contains('Ø³ÙŠØ±ÙˆÙ…') ||
        normalized.contains('ÙƒØ±ÙŠÙ…') ||
        normalized.contains('Ù…ÙƒÙŠØ§Ø¬')) {
      return 'cosmetics';
    }
    if (normalized.contains('ØµÙŠØ¯Ù„ÙŠ') ||
        normalized.contains('ØµÙŠØ¯Ù„ÙŠÙ‡') ||
        normalized.contains('Ù…Ø±Ø·Ø¨') ||
        normalized.contains('Ø¯ÙˆØ§Ø¡')) {
      return 'pharmacy';
    }
    if (normalized.contains('Ù…Ù†Ø¸Ù') || normalized.contains('ØªÙ†Ø¸ÙŠÙ')) {
      return 'detergents';
    }
    if (normalized.contains('Ø§Ù„Ø¨Ø§Ù†') ||
        normalized.contains('Ù„Ø¨Ù†') ||
        normalized.contains('Ø­Ù„ÙŠØ¨') ||
        normalized.contains('Ø¬Ø¨Ù†Ù‡')) {
      return 'dairy';
    }
    if (normalized.contains('Ù…Ø¹Ù„Ø¨Ø§Øª') ||
        normalized.contains('Ù…Ø¹Ù„Ø¨') ||
        normalized.contains('Ù…Ø¹Ø¬ÙˆÙ†')) {
      return 'canned';
    }
    if (normalized.contains('Ø´Ø§ÙŠ')) return 'tea';
    if (normalized.contains('Ø¹ØµÙŠØ±')) return 'juice';

    return normalized.replaceAll(' ', '_');
  }
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
        _stringValue(json['categoryLabel'] ?? json['category']) ?? 'Ø£Ø®Ø±Ù‰';
    final expensiveName =
        _stringValue(json['expensiveName'] ?? expensive['name']) ??
            'Ù…Ù†ØªØ¬ Ù…Ø±ØªÙØ¹ Ø§Ù„Ø³Ø¹Ø±';
    final alternativeName =
        _stringValue(json['alternativeName'] ?? alternative['name']) ??
            'Ø§Ù„Ø®ÙŠØ§Ø± Ø§Ù„Ø§Ù‚ØªØµØ§Ø¯ÙŠ';
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
      categoryLabel: 'Ù‚Ù‡ÙˆØ©',
      expensiveName: 'Ù†Ø³ÙƒØ§ÙÙŠÙ‡ Ø¬ÙˆÙ„Ø¯ 200 Ø¬Ù…',
      expensivePrice: 48.95,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ù‚Ù‡ÙˆØ© Ø¨Ø§Ø¬Ø© Ø§Ù„Ø³Ø¹ÙˆØ¯ÙŠØ© 250 Ø¬Ù…',
      alternativePrice: 24.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80',
      buyUrl:
          'https://www.amazon.sa/s?k=%D9%82%D9%87%D9%88%D8%A9+%D8%A8%D8%A7%D8%AC%D8%A9',
      rating: 4.6,
      reviewCount: 184,
      tags: ['Ù†Ø³ÙƒØ§ÙÙŠÙ‡', 'Ø¨Ø§Ø¬Ø©', 'Ù‚Ù‡ÙˆØ© ÙÙˆØ±ÙŠØ©', 'Ù…Ø´Ø±ÙˆØ¨Ø§Øª Ø³Ø§Ø®Ù†Ø©'],
    ),
    const ProductComparison(
      categoryId: 'detergents',
      categoryLabel: 'Ù…Ù†Ø¸ÙØ§Øª',
      expensiveName: 'ÙÙŠØ±ÙŠ Ø³Ø§Ø¦Ù„ Ø¬Ù„ÙŠ 1 Ù„ØªØ±',
      expensivePrice: 17.50,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1583947582886-f40ec95dd752?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ù‡ÙˆÙ… ÙƒÙŠØ± Ø³Ø§Ø¦Ù„ Ø¬Ù„ÙŠ Ø§Ù‚ØªØµØ§Ø¯ÙŠ 1 Ù„ØªØ±',
      alternativePrice: 9.25,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=dishwashing%20liquid',
      rating: 4.2,
      reviewCount: 91,
      tags: ['ØªÙ†Ø¸ÙŠÙ', 'Ø¬Ù„ÙŠ', 'Ù…Ø·Ø¨Ø®', 'Ø£ÙØ¶Ù„ Ù‚ÙŠÙ…Ø©'],
    ),
    const ProductComparison(
      categoryId: 'dairy',
      categoryLabel: 'Ø£Ù„Ø¨Ø§Ù†',
      expensiveName: 'Ø¬Ø¨Ù†Ø© ÙƒØ±Ø§ÙØª Ø´Ø±Ø§Ø¦Ø­ 400 Ø¬Ù…',
      expensivePrice: 21.95,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ø¬Ø¨Ù†Ø© Ø§Ù„Ù…Ø±Ø§Ø¹ÙŠ Ø´Ø±Ø§Ø¦Ø­ 400 Ø¬Ù…',
      alternativePrice: 13.95,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1452195100486-9cc805987862?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=%D8%AC%D8%A8%D9%86%D8%A9+%D8%A7%D9%84%D9%85%D8%B1%D8%A7%D8%B9%D9%8A',
      rating: 4.4,
      reviewCount: 132,
      tags: ['Ø¬Ø¨Ù†Ø©', 'ÙƒØ±Ø§ÙØª', 'Ø§Ù„Ù…Ø±Ø§Ø¹ÙŠ', 'Ø¥ÙØ·Ø§Ø±'],
    ),
    const ProductComparison(
      categoryId: 'canned',
      categoryLabel: 'Ù…Ø¹Ù„Ø¨Ø§Øª',
      expensiveName: 'Ù…Ø¹Ø¬ÙˆÙ† Ø·Ù…Ø§Ø·Ù… Ù‡Ø§ÙŠÙ†Ø² 8 Ø¹Ø¨ÙˆØ§Øª',
      expensivePrice: 18.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1515003197210-e0cd71810b5f?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ù…Ø¹Ø¬ÙˆÙ† Ø·Ù…Ø§Ø·Ù… Ù‚ÙˆØ¯ÙŠ 8 Ø¹Ø¨ÙˆØ§Øª',
      alternativePrice: 10.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1576867757603-05b134ebc379?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=goody+tomato+paste',
      rating: 4.5,
      reviewCount: 88,
      tags: ['Ù‡Ø§ÙŠÙ†Ø²', 'Ù‚ÙˆØ¯ÙŠ', 'Ø·Ø¨Ø®', 'Ø·Ù…Ø§Ø·Ù…'],
    ),
    const ProductComparison(
      categoryId: 'tea',
      categoryLabel: 'Ø´Ø§ÙŠ',
      expensiveName: 'Ø´Ø§ÙŠ Ù„ÙŠØ¨ØªÙˆÙ† 100 ÙƒÙŠØ³',
      expensivePrice: 29.95,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ø´Ø§ÙŠ Ø±Ø¨ÙŠØ¹ 100 ÙƒÙŠØ³',
      alternativePrice: 17.25,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=rabea%20tea',
      rating: 4.8,
      reviewCount: 240,
      tags: ['Ù„ÙŠØ¨ØªÙˆÙ†', 'Ø±Ø¨ÙŠØ¹', 'Ø´Ø§ÙŠ Ø³Ø¹ÙˆØ¯ÙŠ', 'Ù…Ø´Ø±ÙˆØ¨ Ø³Ø§Ø®Ù†'],
    ),
    const ProductComparison(
      categoryId: 'restaurants',
      categoryLabel: 'Ù…Ø·Ø§Ø¹Ù…',
      expensiveName: 'ÙˆØ¬Ø¨Ø© Ø¨Ø±Ø¬Ø± Ù…Ø±Ø¬Ø¹ÙŠØ©',
      expensivePrice: 26.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ø¨Ø±Ø¬Ø± Ù…Ø¯Ø®Ù† Ù…Ù† Ù…Ø·Ø¹Ù… Ø¨Ø±Ø¬Ø± Ø§Ù„Ø´Ø±Ù‚ÙŠØ© - Ø§Ù„Ø®Ø¨Ø±',
      alternativePrice: 18.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.hungerstation.com/sa-en',
      rating: 4.9,
      reviewCount: 278,
      tags: ['Ø¨ÙŠØ¬ Ù…Ø§Ùƒ', 'Ø¨Ø±Ø¬Ø±', 'Ø§Ù„Ø®Ø¨Ø±', 'Ù…Ø·Ø¹Ù… Ù…Ù…ÙŠØ²', 'Ø§Ù„Ø´Ø±Ù‚ÙŠØ©'],
      localLocationLabel: 'Ø§Ù„Ø®Ø¨Ø± - Ø·Ø±ÙŠÙ‚ Ø§Ù„Ø£Ù…ÙŠØ± ØªØ±ÙƒÙŠ - Ù…Ø·Ø¹Ù… Ø¨Ø±Ø¬Ø± Ø§Ù„Ø´Ø±Ù‚ÙŠØ©',
      localLocationUrl: 'https://maps.google.com/?q=Khobar+burger+restaurant',
    ),
    const ProductComparison(
      categoryId: 'restaurants',
      categoryLabel: 'Ù…Ø·Ø§Ø¹Ù…',
      expensiveName: 'Ø³Ø§Ù†Ø¯ÙˆØªØ´ ÙƒØ±Ø³Ø¨ÙŠ Ù…Ø±Ø¬Ø¹ÙŠ',
      expensivePrice: 24.50,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1520072959219-c595dc870360?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'ÙƒØ±Ø³Ø¨ÙŠ Ø¯Ø¬Ø§Ø¬ Ù…Ù† Ù…Ø·Ø¹Ù… Ø£Ù‡Ù„ Ø§Ù„Ø®Ø¨Ø±',
      alternativePrice: 16.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1606755962773-d324e0a13086?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://jahez.net',
      rating: 4.7,
      reviewCount: 163,
      tags: ['ÙƒØ±Ø³Ø¨ÙŠ', 'Ø¯Ø¬Ø§Ø¬', 'Ù…Ø·Ø§Ø¹Ù… Ø§Ù„Ø®Ø¨Ø±', 'Ø£ÙØ¶Ù„ Ù‚ÙŠÙ…Ø©'],
      localLocationLabel: 'Ø§Ù„Ø®Ø¨Ø± - Ø­ÙŠ Ø§Ù„Ø­Ø²Ø§Ù… Ø§Ù„Ø°Ù‡Ø¨ÙŠ - Ù…Ø·Ø¹Ù… Ø£Ù‡Ù„ Ø§Ù„Ø®Ø¨Ø±',
      localLocationUrl: 'https://maps.google.com/?q=Khobar+crispy+chicken',
    ),
    const ProductComparison(
      categoryId: 'restaurants',
      categoryLabel: 'Ù…Ø·Ø§Ø¹Ù…',
      expensiveName: 'Ø¢ÙŠØ³ Ù„Ø§ØªÙŠÙ‡ Ù…Ø±Ø¬Ø¹ÙŠ',
      expensivePrice: 21.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ø¢ÙŠØ³ Ù„Ø§ØªÙŠÙ‡ Ù…Ù† Ù…Ù‚Ù‡Ù‰ Ø´Ø±Ù‚ÙŠ',
      alternativePrice: 13.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://mrsool.co',
      rating: 4.8,
      reviewCount: 121,
      tags: ['Ù‚Ù‡ÙˆØ© Ø¨Ø§Ø±Ø¯Ø©', 'Ù…Ù‚Ù‡Ù‰ Ù…Ù…ÙŠØ²', 'Ù„Ø§ØªÙŠÙ‡', 'Ø§Ù„Ø´Ø±Ù‚ÙŠØ©'],
      localLocationLabel: 'Ø§Ù„Ø®Ø¨Ø± - Ø§Ù„ÙƒÙˆØ±Ù†ÙŠØ´ - Ù…Ù‚Ù‡Ù‰ Ø´Ø±Ù‚ÙŠ',
      localLocationUrl: 'https://maps.google.com/?q=Khobar+coffee+shop',
    ),
    const ProductComparison(
      categoryId: 'perfumes',
      categoryLabel: 'Ø¹Ø·ÙˆØ±',
      expensiveName: 'Dior Sauvage Eau de Parfum',
      expensivePrice: 520.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ø¨Ø¯ÙŠÙ„ Ø³Ø§ÙØ§Ø¬ Ù…Ù† Ù†Ø®Ø¨Ø© Ø§Ù„Ø¹ÙˆØ¯',
      alternativePrice: 189.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=sauvage+alternative',
      rating: 4.9,
      reviewCount: 312,
      tags: ['Ø³Ø§ÙØ§Ø¬', 'Ù†Ø®Ø¨Ø© Ø§Ù„Ø¹ÙˆØ¯', 'Ø¨Ø±Ø§Ù†Ø¯ Ø³Ø¹ÙˆØ¯ÙŠ', 'Ø¨Ø¯ÙŠÙ„ Ø¹Ø·Ø±ÙŠ'],
      fragranceNotes: 'Ø¨Ø±ØºÙ…ÙˆØªØŒ ÙÙ„ÙÙ„ Ø³ÙŠØ´ÙˆØ§Ù†ØŒ Ø£Ù…Ø¨Ø±ÙˆÙƒØ³Ø§Ù†ØŒ Ù„Ù…Ø³Ø© Ø®Ø´Ø¨ÙŠØ© Ù…Ù†Ø¹Ø´Ø©',
    ),
    const ProductComparison(
      categoryId: 'perfumes',
      categoryLabel: 'Ø¹Ø·ÙˆØ±',
      expensiveName: 'Baccarat Rouge 540',
      expensivePrice: 1210.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1523293182086-7651a899d37f?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ø¨Ø¯ÙŠÙ„ Ø¨Ù†ÙØ³ Ø§Ù„Ø±Ø§Ø¦Ø­Ø© Ù…Ù† Ø§Ù„Ø¹Ø±Ø¨ÙŠØ© Ù„Ù„Ø¹ÙˆØ¯',
      alternativePrice: 245.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1616949755610-8c9bbc08f138?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=arabian+oud+perfume',
      rating: 4.8,
      reviewCount: 204,
      tags: ['Ø¨ÙƒØ§Ø±Ø§Øª', 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ© Ù„Ù„Ø¹ÙˆØ¯', 'Ø¹ÙˆØ¯', 'Ø¹Ù†Ø¨Ø±'],
      fragranceNotes: 'Ø²Ø¹ÙØ±Ø§Ù†ØŒ ÙŠØ§Ø³Ù…ÙŠÙ†ØŒ Ø¹Ù†Ø¨Ø±ØŒ Ø£Ø®Ø´Ø§Ø¨ Ø¯Ø§ÙØ¦Ø© ÙˆØ³ÙƒØ± Ù…Ø­Ø±ÙˆÙ‚',
    ),
    const ProductComparison(
      categoryId: 'perfumes',
      categoryLabel: 'Ø¹Ø·ÙˆØ±',
      expensiveName: 'Chanel Coco Mademoiselle',
      expensivePrice: 615.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1594035910387-fea47794261f?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ø¨Ø¯ÙŠÙ„ ÙÙ„ÙˆØ±Ø§Ù„ Ù…Ù† Ø¥Ø¨Ø±Ø§Ù‡ÙŠÙ… Ø§Ù„Ù‚Ø±Ø´ÙŠ',
      alternativePrice: 210.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1588405748880-12d1d2a59df9?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=ibrahim+alqurashi+perfume',
      rating: 4.7,
      reviewCount: 177,
      tags: ['Ø´Ø§Ù†ÙŠÙ„', 'Ø¥Ø¨Ø±Ø§Ù‡ÙŠÙ… Ø§Ù„Ù‚Ø±Ø´ÙŠ', 'ÙÙ„ÙˆØ±Ø§Ù„', 'Ù…Ø³Ùƒ'],
      fragranceNotes: 'Ø¨Ø±ØªÙ‚Ø§Ù„ØŒ ÙˆØ±Ø¯ ØªØ±ÙƒÙŠØŒ Ø¨Ø§ØªØ´ÙˆÙ„ÙŠØŒ Ù…Ø³Ùƒ Ø£Ø¨ÙŠØ¶',
    ),
    const ProductComparison(
      categoryId: 'cosmetics',
      categoryLabel: 'ØªØ¬Ù…ÙŠÙ„',
      expensiveName: 'The Ordinary Niacinamide 10% Serum',
      expensivePrice: 69.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ø³ÙŠØ±ÙˆÙ… Ù†ÙŠØ§Ø³ÙŠÙ†Ø§Ù…ÙŠØ¯ Ù…Ù† Ù„Ø§Ø¨ Ø³Ø¹ÙˆØ¯ÙŠ',
      alternativePrice: 34.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1625772452859-1c03d5bf1137?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=niacinamide+serum',
      rating: 4.6,
      reviewCount: 143,
      tags: ['Ù†ÙŠØ§Ø³ÙŠÙ†Ø§Ù…ÙŠØ¯', 'Ø³ÙŠØ±ÙˆÙ…', 'Ø¨Ø´Ø±Ø©', 'Ø£ÙØ¶Ù„ Ù‚ÙŠÙ…Ø©'],
      activeIngredients: 'Niacinamide 10% + Zinc PCA Ù„ØªÙ†Ø¸ÙŠÙ… Ø§Ù„Ø¯Ù‡ÙˆÙ† ÙˆØªÙ‚Ù„ÙŠÙ„ Ù…Ø¸Ù‡Ø± Ø§Ù„Ù…Ø³Ø§Ù…',
    ),
    const ProductComparison(
      categoryId: 'cosmetics',
      categoryLabel: 'ØªØ¬Ù…ÙŠÙ„',
      expensiveName: 'La Roche-Posay Vitamin C Serum',
      expensivePrice: 220.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1570194065650-d99fb4d8a5c8?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ø³ÙŠØ±ÙˆÙ… ÙÙŠØªØ§Ù…ÙŠÙ† C Ù…Ù† Ø¨Ø±Ø§Ù†Ø¯ Ø³Ø¹ÙˆØ¯ÙŠ Ù„Ù„Ø¹Ù†Ø§ÙŠØ©',
      alternativePrice: 96.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.amazon.sa/s?k=vitamin+c+serum',
      rating: 4.5,
      reviewCount: 109,
      tags: ['ÙÙŠØªØ§Ù…ÙŠÙ† Ø³ÙŠ', 'Ø³ÙŠØ±ÙˆÙ…', 'Ù†Ø¶Ø§Ø±Ø©', 'Ù…ÙƒÙˆÙ†Ø§Øª ÙØ¹Ø§Ù„Ø©'],
      activeIngredients: 'Vitamin C + Hyaluronic Acid + Vitamin E Ù„Ø¥Ø´Ø±Ø§Ù‚Ø© ÙˆØªØ±Ø·ÙŠØ¨ Ø£Ø¹Ù…Ù‚',
    ),
    const ProductComparison(
      categoryId: 'cosmetics',
      categoryLabel: 'ØªØ¬Ù…ÙŠÙ„',
      expensiveName: 'Maybelline Fit Me Concealer',
      expensivePrice: 58.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1631730486782-d5a6bdf9a7ec?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'ÙƒÙˆÙ†Ø³ÙŠÙ„Ø± Ø§Ù‚ØªØµØ§Ø¯ÙŠ Ø¨ØªØºØ·ÙŠØ© Ø®ÙÙŠÙØ© Ù…Ù† Ø¨ÙˆØªÙŠÙƒ Ø³Ø¹ÙˆØ¯ÙŠ',
      alternativePrice: 27.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.noon.com/saudi-en/search?q=concealer',
      rating: 4.4,
      reviewCount: 86,
      tags: ['ÙƒÙˆÙ†Ø³ÙŠÙ„Ø±', 'Ù…ÙƒÙŠØ§Ø¬', 'ØªØºØ·ÙŠØ©', 'Ø£ÙØ¶Ù„ Ù‚ÙŠÙ…Ø©'],
      activeIngredients: 'Pigment blend + Glycerin Ù„ØªØ±Ø·ÙŠØ¨ Ø®ÙÙŠÙ ÙˆØ«Ø¨Ø§Øª ÙŠÙˆÙ…ÙŠ',
    ),
    const ProductComparison(
      categoryId: 'pharmacy',
      categoryLabel: 'ØµÙŠØ¯Ù„ÙŠØ©',
      expensiveName: 'CeraVe Moisturizing Cream',
      expensivePrice: 89.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1556228578-dd6c36f7737d?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ù…Ø±Ø·Ø¨ Ø§Ù‚ØªØµØ§Ø¯ÙŠ Ù…Ù† Ø§Ù„ØµÙŠØ¯Ù„ÙŠØ©',
      alternativePrice: 44.00,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1617897903246-719242758050?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.nahdionline.com',
      rating: 4.7,
      reviewCount: 221,
      tags: ['Ø³ÙŠØ±Ø§ÙÙŠ', 'Ù…Ø±Ø·Ø¨', 'Ù†Ù‡Ø¯ÙŠ', 'Ø§Ù‚ØªØµØ§Ø¯ÙŠ'],
      activeIngredients: 'Ø³ÙŠØ±Ø§Ù…ÙŠØ¯Ø§Øª + Ù‡ÙŠØ§Ù„ÙˆØ±ÙˆÙ†ÙŠÙƒ Ø£Ø³ÙŠØ¯ + Ø¨Ø§Ù†Ø«ÙŠÙ†ÙˆÙ„ Ù„Ø¯Ø¹Ù… Ø­Ø§Ø¬Ø² Ø§Ù„Ø¨Ø´Ø±Ø©',
    ),
    const ProductComparison(
      categoryId: 'pharmacy',
      categoryLabel: 'ØµÙŠØ¯Ù„ÙŠØ©',
      expensiveName: 'Panadol Cold & Flu',
      expensivePrice: 24.00,
      expensiveImageUrl:
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=900&q=80',
      alternativeName: 'Ø®ÙŠØ§Ø± Ø§Ù‚ØªØµØ§Ø¯ÙŠ Ù„Ù†Ø²Ù„Ø§Øª Ø§Ù„Ø¨Ø±Ø¯',
      alternativePrice: 14.50,
      alternativeImageUrl:
          'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?auto=format&fit=crop&w=900&q=80',
      buyUrl: 'https://www.al-dawaa.com',
      rating: 4.3,
      reviewCount: 75,
      tags: ['Ø¨Ø§Ù†Ø§Ø¯ÙˆÙ„', 'Ø¨Ø±Ø¯', 'ØµÙŠØ¯Ù„ÙŠØ©', 'Ø¯ÙˆØ§Ø¡'],
      activeIngredients: 'Ø¨Ø§Ø±Ø§Ø³ÙŠØªØ§Ù…ÙˆÙ„ + Ù…Ø²ÙŠÙ„ Ø§Ø­ØªÙ‚Ø§Ù† Ø¨ØªØ±ÙƒÙŠØ¨Ø© Ø§Ù‚ØªØµØ§Ø¯ÙŠØ© Ù…Ø´Ø§Ø¨Ù‡Ø©',
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
  return '${formatAmountValue(price)} Ø±.Ø³';
}

String formatAmountValue(double amount) {
  final hasFraction = amount != amount.roundToDouble();
  return hasFraction ? amount.toStringAsFixed(2) : amount.toStringAsFixed(0);
}

String _normalizeArabic(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[Ø£Ø¥Ø¢]'), 'Ø§')
      .replaceAll('Ø¤', 'Ùˆ')
      .replaceAll('Ø¦', 'ÙŠ')
      .replaceAll('Ø©', 'Ù‡')
      .replaceAll('Ù‰', 'ÙŠ')
      .replaceAll(RegExp(r'[^0-9a-zA-Z\u0600-\u06FF\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
