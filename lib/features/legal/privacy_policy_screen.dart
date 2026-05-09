import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.shellBackground,
      appBar: AppBar(
        title: Text(
          tr('سياسة الخصوصية', 'Privacy Policy'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppPalette.cardBackground,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(
              tr('مقدمة', 'Introduction'),
              tr(
                'نحن في LeastPrice نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح هذه السياسة كيف نجمع ونستخدم ونحمي معلوماتك عند استخدام تطبيقنا.',
                'At LeastPrice, we respect your privacy and are committed to protecting your personal data. This policy explains how we collect, use, and protect your information when you use our app.',
              ),
            ),
            _section(
              tr('البيانات التي نجمعها', 'Data We Collect'),
              tr(
                '• رقم الجوال والبريد الإلكتروني: لإنشاء حسابك وتوثيقه.\n'
                '• الموقع الجغرافي: لتحديد المدينة وعرض الأسعار المحلية المناسبة لك.\n'
                '• معلومات الجهاز: لتحسين أداء التطبيق وحل المشكلات التقنية.',
                '• Phone number and email: To create and verify your account.\n'
                '• Location: To determine your city and show relevant local prices.\n'
                '• Device information: To improve app performance and resolve technical issues.',
              ),
            ),
            _section(
              tr('كيفية استخدام البيانات', 'How We Use Data'),
              tr(
                'نستخدم بياناتك لتوفير خدمة مقارنة الأسعار، ومعالجة الطلبات، وإرسال تنبيهات العروض المهمة، وتحليل أداء التطبيق لتقديم تجربة أفضل.',
                'We use your data to provide price comparison services, process requests, send important offer notifications, and analyze app performance to provide a better experience.',
              ),
            ),
            _section(
              tr('مشاركة البيانات', 'Data Sharing'),
              tr(
                'لا نقوم ببيع بياناتك لأطراف ثالثة. قد نشارك بيانات مجهولة الهوية لأغراض إحصائية فقط، أو عند الالتزام بمتطلبات قانونية رسمية.',
                'We do not sell your data to third parties. We may share anonymous data for statistical purposes only, or when complying with official legal requirements.',
              ),
            ),
            _section(
              tr('أمن المعلومات', 'Information Security'),
              tr(
                'نستخدم تقنيات تشفير ومعايير أمان عالية (عبر خدمات Google Firebase) لضمان حماية بياناتك من الوصول غير المصرح به.',
                'We use high-standard encryption and security technologies (via Google Firebase services) to ensure your data is protected from unauthorized access.',
              ),
            ),
            _section(
              tr('حقوقك', 'Your Rights'),
              tr(
                'يحق لك الوصول إلى بياناتك أو طلب تعديلها أو حذفها في أي وقت عبر إعدادات التطبيق أو التواصل معنا مباشرة.',
                'You have the right to access, modify, or delete your data at any time via app settings or by contacting us directly.',
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                tr('آخر تحديث: مايو 2026', 'Last Updated: May 2026'),
                style: TextStyle(
                  color: AppPalette.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppPalette.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: AppPalette.panelText,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
