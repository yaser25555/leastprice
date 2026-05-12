import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/core/utils/helpers.dart';

class HomePageActions {
  const HomePageActions();

  Future<void> openExternalUrl(
    BuildContext context,
    String url, {
    bool enforceSupportedStore = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final isWhatsApp = AffiliateLinkService.looksLikeWhatsAppContact(url);

    try {
      final preparedUrl = enforceSupportedStore
          ? AffiliateLinkService.prepareForOpen(url)
          : url;
      final preparedUri = Uri.parse(preparedUrl);

      if (enforceSupportedStore &&
          !AffiliateLinkService.isSupportedStore(preparedUri)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'الرابط الحالي لا يوجّه إلى متجر سعودي مدعوم.',
                'This link does not point to a supported Saudi store.',
              ),
            ),
          ),
        );
        return;
      }

      final opened = await launchUrl(
        preparedUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              tr(
                isWhatsApp
                    ? 'تعذر فتح واتساب حالياً.'
                    : 'تعذر فتح رابط التواصل حالياً.',
                isWhatsApp
                    ? 'Unable to open WhatsApp right now.'
                    : 'Unable to open the contact link right now.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tr(
              isWhatsApp
                  ? 'رقم واتساب أو رابطه غير صالح حالياً.'
                  : 'رابط التواصل غير صالح أو غير متاح حالياً.',
              isWhatsApp
                  ? 'The WhatsApp number or link is invalid right now.'
                  : 'The contact link is invalid or unavailable right now.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> copyCouponCode(BuildContext context, String code) async {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: trimmedCode));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'تم نسخ الكود، سيتم تطبيقه عند الدفع.',
            'The code was copied and can be used at checkout.',
          ),
        ),
      ),
    );
  }

  double estimatedInviteSavingsFor(List<ProductComparison> products) {
    if (products.isEmpty) return 0;

    final topSavings = [...products]
      ..sort((a, b) => b.savingsAmount.compareTo(a.savingsAmount));

    return topSavings
        .take(math.min(3, topSavings.length))
        .fold<double>(0, (total, item) => total + item.savingsAmount);
  }

  Future<void> inviteFriend(
    BuildContext context,
    UserSavingsProfile userProfile,
    List<ProductComparison> products,
  ) async {
    final inviteLink =
        '${userProfile.shareBaseUrl}/invite/${userProfile.inviteCode}';
    final savedAmount = formatAmountValue(estimatedInviteSavingsFor(products));
    final message = userProfile.inviteMessageTemplate
        .replaceAll('{SAVED_AMOUNT}', savedAmount)
        .replaceAll('{USER_CODE}', userProfile.inviteCode)
        .replaceAll('{APP_LINK}', inviteLink);

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: tr(
          'ادعُ صديقاً للتوفير مع أقل سعر',
          'Invite a friend to save with LeastPrice',
        ),
      ),
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<bool> verifyLocalAdminPassword(BuildContext context) async {
    final passwordController = TextEditingController();
    var obscurePassword = true;
    var hasError = false;

    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tr('دخول المسؤول', 'Admin access')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr(
                      'أدخل كلمة المرور المحلية لفتح لوحة التحكم على الجوال.',
                      'Enter the local password to open the mobile admin center.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: tr('كلمة المرور', 'Password'),
                      errorText: hasError
                          ? tr('كلمة المرور غير صحيحة.',
                              'The password is incorrect.')
                          : null,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      final isValid = passwordController.text.trim() ==
                          LeastPriceDataConfig.adminPassword;
                      if (isValid) {
                        Navigator.of(context).pop(true);
                        return;
                      }
                      setDialogState(() {
                        hasError = true;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(tr('إلغاء', 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final isValid = passwordController.text.trim() ==
                        LeastPriceDataConfig.adminPassword;
                    if (isValid) {
                      Navigator.of(context).pop(true);
                      return;
                    }
                    setDialogState(() {
                      hasError = true;
                    });
                  },
                  child: Text(tr('دخول', 'Open')),
                ),
              ],
            );
          },
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      passwordController.dispose();
    });
    return allowed ?? false;
  }
}
