import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({
    super.key,
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
              color: AppPalette.cardBackground,
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
