import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';

class AdminSimpleUsersPanel extends StatelessWidget {
  const AdminSimpleUsersPanel({
    super.key,
    required this.service,
    required this.isPrimaryAdmin,
  });

  final FirestoreCatalogService service;
  final bool isPrimaryAdmin;

  Future<void> _togglePlanActivation(
    BuildContext context,
    UserSavingsProfile user,
  ) async {
    final nextValue = !user.planActivated;
    try {
      await service.setUserPlanActivation(
        userId: user.userId,
        planActivated: nextValue,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? tr('تم تفعيل الخطة للمستخدم.', 'Plan activated for user.')
                : tr('تم إلغاء تفعيل الخطة للمستخدم.',
                    'Plan deactivated for user.'),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('خطأ: $error', 'Error: $error'))),
      );
    }
  }

  Future<void> _toggleMarketingRole(
    BuildContext context,
    UserSavingsProfile user,
  ) async {
    final nextRole = user.isMarketingManager ? 'user' : 'marketing_manager';
    try {
      await service.setUserAdminRole(userId: user.userId, adminRole: nextRole);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextRole == 'marketing_manager'
                ? tr('تم منح صلاحية مدير التسويق.',
                    'Marketing manager role granted.')
                : tr('تم سحب صلاحية مدير التسويق.',
                    'Marketing manager role revoked.'),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('خطأ: $error', 'Error: $error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.shellBackground,
      body: StreamBuilder<List<UserSavingsProfile>>(
        stream: service.watchAdminUserProfiles(),
        builder: (context, snap) {
          final users = snap.data ?? const <UserSavingsProfile>[];
          final isLoading = snap.connectionState == ConnectionState.waiting;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  tr('إدارة خطط المستخدمين', 'User plan management'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B2F5E),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  tr(
                    'من هنا يمكنك تفعيل أو إلغاء تفعيل الخطة لكل مستخدم بعد التحقق من التحويل.',
                    'From here, you can activate or deactivate each user plan after verifying transfer.',
                  ),
                  style: TextStyle(
                    color: AppPalette.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text(
                    tr('خطأ: ${snap.error}', 'Error: ${snap.error}'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (users.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      tr(
                        'لا يوجد مستخدمون بعد.',
                        'No users found yet.',
                      ),
                      style: TextStyle(
                        color: AppPalette.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final user = users[index];
                      final phoneLabel = user.phoneNumber.trim().isEmpty
                          ? tr('بدون رقم', 'No phone')
                          : user.phoneNumber;

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: user.planActivated
                                ? AppPalette.comparisonEmerald
                                : AppPalette.softNavy,
                            child: Icon(
                              user.planActivated
                                  ? Icons.verified_rounded
                                  : Icons.person_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            phoneLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            'UID: ${user.userId}\n'
                            '${tr('الخطة', 'Plan')}: ${user.planStatus} • '
                            '${tr('الدور', 'Role')}: ${user.adminRole}',
                            style: const TextStyle(height: 1.5),
                          ),
                          isThreeLine: true,
                          trailing: SizedBox(
                            width: isPrimaryAdmin ? 290 : 150,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: () =>
                                      _togglePlanActivation(context, user),
                                  icon: Icon(
                                    user.planActivated
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_rounded,
                                  ),
                                  label: Text(
                                    user.planActivated
                                        ? tr('إلغاء التفعيل', 'Deactivate')
                                        : tr('تفعيل', 'Activate'),
                                  ),
                                ),
                                if (isPrimaryAdmin)
                                  FilledButton.tonalIcon(
                                    onPressed: () =>
                                        _toggleMarketingRole(context, user),
                                    icon: Icon(
                                      user.isMarketingManager
                                          ? Icons.person_remove_alt_1_rounded
                                          : Icons.person_add_alt_1_rounded,
                                    ),
                                    label: Text(
                                      user.isMarketingManager
                                          ? tr('سحب التسويق', 'Revoke marketing')
                                          : tr('مدير تسويق', 'Marketing manager'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
