import 'package:flutter/material.dart';

import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/admin/admin_dashboard_section_card.dart';
import 'admin_exports.dart';

class AdminBuildFailurePanel extends StatelessWidget {
  const AdminBuildFailurePanel({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AdminDashboardSectionCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFD14B4B),
                  size: 34,
                ),
                const SizedBox(height: 14),
                Text(
                  tr(
                    'تعذر بناء واجهة الإدارة',
                    'Unable to build the admin interface',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF17332B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7A9A),
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
