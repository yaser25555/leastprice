import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/core/widgets/app_brand_mark.dart';

class AboutLeastPriceSection extends StatelessWidget {
  const AboutLeastPriceSection({
    super.key,
    required this.onContactTap,
  });

  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPalette.cardBackground,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppPalette.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: AppPalette.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBrandMark(
                  size: 54,
                  padding: 8,
                  borderRadius: 18,
                ),
                const SizedBox(height: 14),
                Text(
                  tr('من نحن', 'About Us'),
                  style: const TextStyle(
                    color: AppPalette.panelText,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(
                    'LeastPrice منصة تساعد المستهلك على العثور على السعر الأقل والأفضل عبر المنصات المختلفة داخل المدن السعودية، ثم تعرض النتائج بشكل واضح وسريع لتوفير الوقت والجهد.',
                    'LeastPrice is a platform that helps shoppers find the lowest and best prices across different platforms within Saudi cities, then presents the results clearly and quickly to save time and effort.',
                  ),
                  style: const TextStyle(
                    color: AppPalette.mutedText,
                    fontSize: 15,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AboutFeatureCard(
            icon: Icons.search_rounded,
            title: tr('خدماتنا للمستهلك', 'Our value for shoppers'),
            description: tr(
              'نقارن بين الأسعار داخل المدينة المختارة عبر المنصات والمتاجر المختلفة، حتى لا يضطر المستخدم إلى التنقل الطويل بين التطبيقات والمواقع للوصول إلى الخيار الأنسب.',
              'We compare prices inside the selected city across different platforms and stores, so users do not have to spend long periods moving between apps and websites to find the best option.',
            ),
          ),
          const SizedBox(height: 14),
          _AboutFeatureCard(
            icon: Icons.campaign_rounded,
            title: tr('خدماتنا للتجار', 'Our value for merchants'),
            description: tr(
              'نوفر للتاجر وسيلة أسهل لإيصال منتجه أو عرضه إلى المستهلك داخل التطبيق، بما يختصر الطريق بين الإعلان والشراء ويزيد فرص الوصول المباشر.',
              'We give merchants an easier way to bring their products and offers to shoppers inside the app, shortening the path between promotion and purchase and increasing direct reach.',
            ),
          ),
          const SizedBox(height: 14),
          _AboutFeatureCard(
            icon: Icons.chat_rounded,
            title: tr('اتصل بنا', 'Contact Us'),
            description: tr(
              'إذا كنت ترغب في الإعلان عن منتجاتك أو الاستفادة من خدمات التطبيق التجارية، يسعدنا التواصل معك مباشرة عبر واتساب.',
              'If you want to advertise your products or benefit from the app commercial services, we are happy to connect with you directly on WhatsApp.',
            ),
            actionLabel: tr('اتصل بنا', 'Contact Us'),
            onTap: onContactTap,
          ),
        ],
      ),
    );
  }
}

class _AboutFeatureCard extends StatelessWidget {
  const _AboutFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.softNavy,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPalette.paleOrange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppPalette.orange),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.panelText,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppPalette.mutedText,
              fontSize: 14.4,
              fontWeight: FontWeight.w600,
              height: 1.7,
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
              ),
              icon: const Icon(Icons.forum_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
