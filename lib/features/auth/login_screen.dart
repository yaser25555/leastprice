import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/widgets/app_brand_mark.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/auth/pending_auth_session.dart';
import 'auth_exports.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _rememberMePrefKey = 'remember_login_enabled';
  static const String _rememberedEmailPrefKey = 'remembered_login_email';
  final FirestoreCatalogService _catalogService =
      const FirestoreCatalogService();
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
    final normalizedPhone =
        _isRegisterMode ? formatSaudiPhoneNumber(_phoneController.text) : null;
    final normalizedEmail = normalizeEmailAddress(_emailController.text);
    final password = _passwordController.text.trim();
    final referralCode =
        _isRegisterMode ? _referralController.text.trim().toUpperCase() : '';

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
            : tr('تم تسجيل الدخول بنجاح.',
                'Signed in successfully.');
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
          'تعذر إكمال تسجيل الدخول حالياً: $error',
          'Unable to complete sign-in right now: $error',
        );
      });
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final normalizedEmail = normalizeEmailAddress(_emailController.text);
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
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: normalizedEmail);
      if (!mounted) return;
      setState(() {
        _isSendingPasswordReset = false;
        _statusMessage = tr(
          'أرسلنا إلى $normalizedEmail رابطاً لإعادة تعيين كلمة المرور. افحص البريد وصندوق الرسائل غير المرغوبة.',
          'We sent a password reset link to $normalizedEmail. Check your inbox and spam folder.',
        );
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSendingPasswordReset = false;
        _statusMessage = arabicAuthMessage(error);
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
    final appleStyle = isAppleInterface(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: appleStyle
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8F8FB), Color(0xFFF1F2F7)],
                )
              : const LinearGradient(
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
                        borderRadius: BorderRadius.circular(
                          appleStyle ? 32 : 30,
                        ),
                        border: appleStyle
                            ? Border.all(color: const Color(0xFFE6E8EF))
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: appleStyle
                                ? const Color(0x0F1B2F5E)
                                : AppPalette.shadow,
                            blurRadius: appleStyle ? 18 : 26,
                            offset: Offset(0, appleStyle ? 8 : 16),
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
                                    Text(
                                      'LeastPrice',
                                      style: TextStyle(
                                        fontSize: appleStyle ? 24 : 22,
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
                              labelText: tr(
                                  'البريد الإلكتروني', 'Email'),
                              hintText: 'name@example.com',
                              prefixIcon:
                                  const Icon(Icons.alternate_email_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText:
                                  tr('كلمة المرور', 'Password'),
                              hintText: tr('6 أحرف أو أكثر',
                                  '6 characters or more'),
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
                                labelText:
                                    tr('رقم الجوال', 'Phone number'),
                                hintText: '05XXXXXXXX',
                                prefixIcon:
                                    const Icon(Icons.phone_android_rounded),
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
                                prefixIcon:
                                    const Icon(Icons.card_giftcard_rounded),
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
                                border:
                                    Border.all(color: AppPalette.paleOrange),
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
                                  ? tr('جارٍ التنفيذ...',
                                      'Processing...')
                                  : (_isRegisterMode
                                      ? tr('إنشاء الحساب',
                                          'Create account')
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
                                  child: Text(tr(
                                      'إنشاء حساب', 'Create account')),
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
