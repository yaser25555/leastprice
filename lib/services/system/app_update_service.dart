import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  static Future<Map<String, dynamic>?> checkUpdate() async {
    if (kIsWeb) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_info')
          .get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      final latestVersion = data['latest_version'] as String?;
      final updateUrl = data['update_url'] as String?;
      final forceUpdate = data['force_update'] as bool? ?? false;
      final messageAr = data['message_ar'] as String? ?? 'يوجد تحديث جديد متوفر للتطبيق يتضمن تحسينات هامة للأسعار والمتاجر.';
      final messageEn = data['message_en'] as String? ?? 'A new update is available with important price and store improvements.';

      if (latestVersion == null || updateUrl == null) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isVersionNewer(latestVersion, currentVersion)) {
        return {
          'latestVersion': latestVersion,
          'updateUrl': updateUrl,
          'forceUpdate': forceUpdate,
          'messageAr': messageAr,
          'messageEn': messageEn,
        };
      }
    } catch (e) {
      debugPrint('LeastPrice AppUpdateService Error: $e');
    }
    return null;
  }

  static bool _isVersionNewer(String latest, String current) {
    try {
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
    } catch (_) {}
    return false;
  }
}
