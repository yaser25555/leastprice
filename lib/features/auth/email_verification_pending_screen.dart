import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class EmailVerificationPendingScreen extends StatefulWidget {
  const EmailVerificationPendingScreen({super.key, 
    required this.user,
  });

  final User user;

  @override
  State<EmailVerificationPendingScreen> createState() =>
      _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState
    extends State<EmailVerificationPendingScreen> {
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
        _statusMessage = arabicAuthMessage(error);
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
        _statusMessage = arabicAuthMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _statusMessage =
            'تعذر إعادة إرسال رسالة التفعيل: $error';
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
                color: AppPalette.cardBackground,
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
                    label: Text(tr(
                        'تحققت من البريد', 'I verified my email')),
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
                    label: Text(tr(
                        'إعادة إرسال رابط التفعيل',
                        'Resend verification link')),
                  ),
                  TextButton(
                    onPressed: _isRefreshing || _isResending ? null : _signOut,
                    child: Text(tr(
                        'استخدام بريد إلكتروني آخر',
                        'Use another email')),
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
