import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'admin_exports.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.adminUser,
  });

  final User adminUser;

  @override
  Widget build(BuildContext context) {
    const service = FirestoreCatalogService();
    final isPrimaryAdmin = adminUser.email == LeastPriceDataConfig.adminEmail;

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
            Text(
              tr('لوحة تحكم LeastPrice', 'LeastPrice Admin Dashboard'),
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
            label: Text(tr('خروج', 'Exit')),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: AdminDashboardBody(
        service: service,
        isPrimaryAdmin: isPrimaryAdmin,
      ),
    );
  }
}

class AdminDashboardBody extends StatefulWidget {
  const AdminDashboardBody({
    super.key,
    required this.service,
    required this.isPrimaryAdmin,
  });

  final FirestoreCatalogService service;
  final bool isPrimaryAdmin;

  @override
  State<AdminDashboardBody> createState() => _AdminDashboardBodyState();
}

class _AdminDashboardBodyState extends State<AdminDashboardBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppPalette.cardBackground,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.local_offer_rounded),
                text: tr('العروض', 'Deals'),
              ),
              Tab(
                icon: const Icon(Icons.notifications_active_rounded),
                text: tr('الإشعارات', 'Notifications'),
              ),
              Tab(
                icon: const Icon(Icons.people_alt_rounded),
                text: tr('المستخدمين', 'Users'),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AdminExclusiveDealsTable(catalogService: widget.service),
              const AdminNotificationPanel(),
              AdminSimpleUsersPanel(
                service: widget.service,
                isPrimaryAdmin: widget.isPrimaryAdmin,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
