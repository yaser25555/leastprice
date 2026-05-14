import 'dart:async';
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/widgets/app_brand_mark.dart';
import 'package:leastprice/services/preferences/user_preferences_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'header_metrics.dart';
import 'metrics.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({
    super.key,
    required this.currentUserLabel,
    required this.inviteCode,
    required this.invitedFriendsCount,
    required this.estimatedSavingsText,
    required this.systemHealthLabel,
    required this.onInviteTap,
    required this.onLogoutTap,
    required this.onFavoritesTap,
    required this.onPriceAlertsTap,
  });

  final String currentUserLabel;
  final String inviteCode;
  final int invitedFriendsCount;
  final String estimatedSavingsText;
  final String systemHealthLabel;
  final VoidCallback onInviteTap;
  final Future<void> Function() onLogoutTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onPriceAlertsTap;

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
                  ? [Color(0xFF243B6B), AppPalette.navy]
                  : [AppPalette.navy, AppPalette.deepNavy],
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppBrandMark(size: 60, borderRadius: 20),
                          const SizedBox(height: 4),
                          Text(
                            '${tr('مرحباً', 'Hello')} $currentUserLabel',
                            style: TextStyle(
                              color: AppPalette.pureWhiteOpacity(0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onFavoritesTap,
                        style: IconButton.styleFrom(
                          backgroundColor: AppPalette.pureWhiteOpacity(0.08),
                          foregroundColor: AppPalette.orange,
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.favorite, size: 18),
                        tooltip: tr('المفضلة', 'Favorites'),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: onPriceAlertsTap,
                        style: IconButton.styleFrom(
                          backgroundColor: AppPalette.pureWhiteOpacity(0.08),
                          foregroundColor: AppPalette.orange,
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_outlined, size: 18),
                        tooltip: tr('تنبيهات السعر', 'Price Alerts'),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: onLogoutTap,
                        style: IconButton.styleFrom(
                          backgroundColor: AppPalette.pureWhiteOpacity(0.08),
                          foregroundColor: AppPalette.orange,
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
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
                                style: TextStyle(
                                  color: AppPalette.pureWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              tr('كودك: $inviteCode', 'Your code: $inviteCode'),
                              style: TextStyle(
                                color: AppPalette.pureWhite,
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
                          style: TextStyle(
                            color: AppPalette.pureWhiteOpacity(0.85),
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
                              foregroundColor: AppPalette.pureWhite,
                              side: BorderSide(
                                  color: AppPalette.pureWhiteOpacity(0.33)),
                              backgroundColor:
                                  AppPalette.pureWhiteOpacity(0.06),
                            ),
                            icon: Icon(Icons.share_rounded, color: AppPalette.orange),
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

class CompactHeaderSection extends StatefulWidget {
  const CompactHeaderSection({
    super.key,
    required this.currentUserLabel,
    required this.inviteCode,
    required this.invitedFriendsCount,
    required this.systemHealthLabel,
    required this.onInviteTap,
    required this.onLogoutTap,
    required this.onFavoritesTap,
    required this.onPriceAlertsTap,
  });

  final String currentUserLabel;
  final String inviteCode;
  final int invitedFriendsCount;
  final String systemHealthLabel;
  final VoidCallback onInviteTap;
  final Future<void> Function() onLogoutTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onPriceAlertsTap;

  @override
  State<CompactHeaderSection> createState() => _CompactHeaderSectionState();
}

class _CompactHeaderSectionState extends State<CompactHeaderSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final appleStyle = isAppleInterface(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: appleStyle
                    ? [Color(0xFF243B6B), AppPalette.navy]
                    : [AppPalette.navy, AppPalette.deepNavy],
              ),
            ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppBrandMark(
                                size: 44,
                                padding: 5,
                                borderRadius: 14,
                                backgroundColor: AppPalette.softOrange,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_rounded,
                                      size: 12, color: Color(0xFFFFD9BA)),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      '${tr('مرحباً', 'Hello')} ${widget.currentUserLabel}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFD9BA),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppPalette.paleOrange,
                        ),
                        const SizedBox(width: 4),
                        ValueListenableBuilder<bool>(
                          valueListenable: isFeminineTheme,
                          builder: (context, isFem, _) => IconButton(
                            onPressed: () {
                              final newVal = !isFeminineTheme.value;
                              isFeminineTheme.value = newVal;
                              UserPreferencesService.saveFeminineTheme(newVal);
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: AppPalette.pureWhiteOpacity(0.08),
                              foregroundColor: AppPalette.pureWhiteOpacity(0.9),
                              padding: const EdgeInsets.all(6),
                              minimumSize: const Size(32, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Icon(
                                isFem
                                    ? Icons.spa_rounded
                                    : Icons.palette_rounded,
                                size: 16),
                            tooltip: tr('تغيير الثيم', 'Change Theme'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: widget.onFavoritesTap,
                          style: IconButton.styleFrom(
                            backgroundColor: AppPalette.pureWhiteOpacity(0.08),
                            foregroundColor: AppPalette.orange,
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.favorite, size: 16),
                          tooltip: tr('المفضلة', 'Favorites'),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: widget.onPriceAlertsTap,
                          style: IconButton.styleFrom(
                            backgroundColor: AppPalette.pureWhiteOpacity(0.08),
                            foregroundColor: AppPalette.orange,
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.notifications_outlined, size: 16),
                          tooltip: tr('تنبيهات السعر', 'Price Alerts'),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: widget.onLogoutTap,
                          style: IconButton.styleFrom(
                            backgroundColor: AppPalette.pureWhiteOpacity(0.08),
                            foregroundColor: AppPalette.orange,
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          tooltip: tr('تسجيل الخروج', 'Sign Out'),
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded) ...[
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
                                  child: Row(
                                children: [
                                  Icon(Icons.discount_rounded,
                                      color: AppPalette.orange, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr(
                                      'كود الدعوة',
                                      'Invite code',
                                    ),
                                    style: TextStyle(
                                      color: AppPalette.paleOrange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              )),
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
                                      widget.inviteCode,
                                      style: TextStyle(
                                        color: AppPalette.deepNavy,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11.5,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    onPressed: widget.onInviteTap,
                                    style: IconButton.styleFrom(
                                      backgroundColor: Color(0x24E8711A),
                                      foregroundColor: AppPalette.paleOrange,
                                      padding: const EdgeInsets.all(10),
                                      minimumSize: const Size(36, 36),
                                    ),
                                    tooltip:
                                        tr('مشاركة الدعوة', 'Share invite'),
                                    icon: Icon(Icons.share_rounded,
                                        color: AppPalette.orange, size: 18),
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
                                label: widget.systemHealthLabel,
                              ),
                              CompactMetricPill(
                                icon: Icons.group_add_rounded,
                                label: tr(
                                  '${widget.invitedFriendsCount} دعوة',
                                  '${widget.invitedFriendsCount} invites',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
