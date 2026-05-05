import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/core/utils/helpers.dart';

bool isAllowedAdminEmail(String? email) {
  return (email ?? '').trim().toLowerCase() ==
      LeastPriceDataConfig.adminEmail.toLowerCase();
}

bool isAdminDashboardRequest([Uri? uri]) {
  final target = uri ?? Uri.base;
  final path = target.path;
  final fragment = target.fragment;

  return isAdminPathToken(path) ||
      isAdminPathToken(fragment) ||
      target.queryParameters['admin'] == '1' ||
      target.queryParameters['view']?.toLowerCase() == 'admin';
}

String? normalizeEmailAddress(String rawEmail) {
  final value = rawEmail.trim().toLowerCase();
  if (value.isEmpty) {
    return null;
  }

  const pattern = r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$';
  return RegExp(pattern, caseSensitive: false).hasMatch(value) ? value : null;
}
