import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String updateUrl;
  final bool forceUpdate;
  final String messageAr;
  final String messageEn;

  const AppUpdateDialog({
    super.key,
    required this.latestVersion,
    required this.updateUrl,
    required this.forceUpdate,
    required this.messageAr,
    required this.messageEn,
  });

  Future<void> _launchUpdateUrl() async {
    final uri = Uri.parse(updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = isEn;
    
    return PopScope(
      canPop: !forceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: AppPalette.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppPalette.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  size: 40,
                  color: AppPalette.orange,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr('تحديث جديد متوفر', 'New Update Available'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'v$latestVersion',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.orange,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEnglish ? messageEn : messageAr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppPalette.softNavy,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _launchUpdateUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  tr('تحديث الآن', 'Update Now'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (!forceUpdate) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    tr('ليس الآن', 'Later'),
                    style: TextStyle(
                      color: AppPalette.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
