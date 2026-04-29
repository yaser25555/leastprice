import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/core/widgets/app_brand_mark.dart';
import 'package:leastprice/core/utils/helpers.dart';

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
    final normalizedEmail = normalizeEmailAddress(_emailController.text);
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

    if (!isAllowedAdminEmail(normalizedEmail)) {
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
        _statusMessage = arabicAuthMessage(error);
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
                    tr('لوحة تحكم LeastPrice',
                        'LeastPrice Admin Dashboard'),
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
