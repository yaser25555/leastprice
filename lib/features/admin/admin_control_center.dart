import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'admin_exports.dart';

class AdminControlCenter extends StatelessWidget {
  const AdminControlCenter({
    super.key,
    required this.adminUser,
  });

  final User adminUser;

  bool get _isPrimaryAdmin =>
      (adminUser.email ?? '').trim().toLowerCase() ==
      LeastPriceDataConfig.adminEmail.toLowerCase();

  @override
  Widget build(BuildContext context) {
    const service = FirestoreCatalogService();

    return Scaffold(
      backgroundColor: AppPalette.shellBackground,
      appBar: AppBar(
        backgroundColor: AppPalette.cardBackground,
        surfaceTintColor: AppPalette.cardBackground,
        elevation: 0,
        titleSpacing: 24,
        toolbarHeight: 82,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'لوحة تحكم LeastPrice',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2F5E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              adminUser.email ?? LeastPriceDataConfig.adminEmail,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7A9A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: Text(tr('خروج', 'Sign out')),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<UserSavingsProfile?>(
        stream: service.watchUserProfile(adminUser.uid),
        builder: (context, snapshot) {
          final profile = snapshot.data ?? UserSavingsProfile.initial();
          final isMarketingManager = !_isPrimaryAdmin && profile.isMarketingManager;
          final hasAdminAccess = _isPrimaryAdmin || isMarketingManager;

          if (!hasAdminAccess) {
            return AdminAccessDeniedScreen(user: adminUser);
          }

          final tabs = <Tab>[
            if (_isPrimaryAdmin)
              Tab(
                icon: const Icon(Icons.view_carousel_rounded),
                text: tr('البنرات', 'Banners'),
              ),
            if (_isPrimaryAdmin)
              Tab(
                icon: const Icon(Icons.compare_arrows_rounded),
                text: tr('المقارنات', 'Comparisons'),
              ),
            Tab(
              icon: const Icon(Icons.local_offer_rounded),
              text: tr('العروض', 'Deals'),
            ),
            if (_isPrimaryAdmin)
              Tab(
                icon: const Icon(Icons.manage_accounts_rounded),
                text: tr('المستخدمون', 'Users'),
              ),
          ];

          final pages = <Widget>[
            if (_isPrimaryAdmin) const AdminSimpleBannersPanel(service: service),
            if (_isPrimaryAdmin) const AdminSimpleProductsPanel(service: service),
            const AdminSimpleExclusiveDealsPanel(service: service),
            if (_isPrimaryAdmin)
              const AdminSimpleUsersPanel(
                service: service,
                isPrimaryAdmin: true,
              ),
          ];

          return DefaultTabController(
            length: tabs.length,
            child: Column(
              children: [
                Material(
                  color: AppPalette.cardBackground,
                  child: TabBar(tabs: tabs),
                ),
                Expanded(
                  child: TabBarView(children: pages),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
