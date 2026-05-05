import 'package:flutter/material.dart';

import 'package:leastprice/core/utils/helpers.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({
    super.key,
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
