import 'dart:async';
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/widgets/app_brand_mark.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'home_exports.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key, 
    required this.currentUserLabel,
    required this.inviteCode,
    required this.invitedFriendsCount,
    required this.estimatedSavingsText,
    required this.systemHealthLabel,
    required this.onInviteTap,
    required this.onLogoutTap,
  });

  final String currentUserLabel;
  final String inviteCode;
  final int invitedFriendsCount;
  final String estimatedSavingsText;
  final String systemHealthLabel;
  final VoidCallback onInviteTap;
  final Future<void> Function() onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final appleStyle = isAppleInterface(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: appleStyle
                  ? const [Color(0xFF243B6B), AppPalette.navy]
                  : const [AppPalette.navy, AppPalette.deepNavy],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    appleStyle ? const Color(0x101B2F5E) : AppPalette.shadow,
                blurRadius: appleStyle ? 20 : 28,
                offset: Offset(0, appleStyle ? 12 : 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                top: -20,
                left: -10,
                child: BackgroundBubble(size: 96, color: Color(0x33FFA052)),
              ),
              const Positioned(
                bottom: -28,
                right: -10,
                child: BackgroundBubble(size: 130, color: Color(0x267FB7E8)),
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
                            appLang.value = lang == 'ar' ? 'en' : 'ar';
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0x33FFFFFF)),
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
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatPill(
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
                              tr('كودك: $inviteCode',
                                  'Your code: $inviteCode'),
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
                              child: InviteMetric(
                                icon: Icons.group_add_rounded,
                                label: tr(
                                  '$invitedFriendsCount دعوة',
                                  '$invitedFriendsCount invites',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InviteMetric(
                                icon: Icons.savings_rounded,
                                label:
                                    '$estimatedSavingsText ${tr('ر.س توفير', 'SAR saved')}',
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

class CompactHeaderSection extends StatelessWidget {
  const CompactHeaderSection({super.key, 
    required this.currentUserLabel,
    required this.inviteCode,
    required this.invitedFriendsCount,
    required this.systemHealthLabel,
    required this.onInviteTap,
    required this.onLogoutTap,
  });

  final String currentUserLabel;
  final String inviteCode;
  final int invitedFriendsCount;
  final String systemHealthLabel;
  final VoidCallback onInviteTap;
  final Future<void> Function() onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final appleStyle = isAppleInterface(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: appleStyle
                  ? const [Color(0xFF243B6B), AppPalette.navy]
                  : const [AppPalette.navy, AppPalette.deepNavy],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    appleStyle ? const Color(0x101B2F5E) : AppPalette.shadow,
                blurRadius: appleStyle ? 20 : 28,
                offset: Offset(0, appleStyle ? 12 : 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                top: -8,
                left: -4,
                child: BackgroundBubble(size: 72, color: Color(0x30FFA052)),
              ),
              const Positioned(
                bottom: -16,
                right: -6,
                child: BackgroundBubble(size: 88, color: Color(0x267FB7E8)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppBrandMark(
                        size: 46,
                        padding: 5,
                        borderRadius: 16,
                        backgroundColor: AppPalette.softOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x22FFD9BA),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                tr('أرخص سعر', 'Smart savings'),
                                style: const TextStyle(
                                  color: AppPalette.paleOrange,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LeastPrice',
                              style: const TextStyle(
                                color: AppPalette.paleOrange,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tr('مرحباً', 'Hello')} $currentUserLabel',
                              style: const TextStyle(
                                color: Color(0xFFFFD9BA),
                                fontSize: 11.5,
                                height: 1.25,
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
                            appLang.value = lang == 'ar' ? 'en' : 'ar';
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x24E8711A),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0x55FFD9BA),
                              ),
                            ),
                            child: Text(
                              lang == 'ar' ? 'EN' : 'AR',
                              style: const TextStyle(
                                color: AppPalette.paleOrange,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: onLogoutTap,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0x24E8711A),
                          foregroundColor: AppPalette.paleOrange,
                          padding: const EdgeInsets.all(10),
                          minimumSize: const Size(38, 38),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        tooltip: tr('تسجيل الخروج', 'Sign Out'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: const Color(0x14E8711A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x40E8711A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                tr(
                                  'حسابك وكود الدعوة',
                                  'Your account and invite code',
                                ),
                                style: const TextStyle(
                                  color: AppPalette.paleOrange,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    inviteCode,
                                    style: const TextStyle(
                                      color: AppPalette.deepNavy,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11.5,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: onInviteTap,
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0x24E8711A),
                                    foregroundColor: AppPalette.paleOrange,
                                    padding: const EdgeInsets.all(10),
                                    minimumSize: const Size(36, 36),
                                  ),
                                  tooltip: tr('مشاركة الدعوة',
                                      'Share invite'),
                                  icon:
                                      const Icon(Icons.share_rounded, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            CompactStatPill(
                              icon: Icons.monitor_heart_rounded,
                              label: systemHealthLabel,
                            ),
                            CompactMetricPill(
                              icon: Icons.group_add_rounded,
                              label: tr(
                                '$invitedFriendsCount دعوة',
                                '$invitedFriendsCount invites',
                              ),
                            ),
                          ],
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
