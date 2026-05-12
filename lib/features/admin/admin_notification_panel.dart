import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/services/notifications/onesignal_api_service.dart';

class AdminNotificationPanel extends StatefulWidget {
  const AdminNotificationPanel({super.key});

  @override
  State<AdminNotificationPanel> createState() => _AdminNotificationPanelState();
}

class _AdminNotificationPanelState extends State<AdminNotificationPanel> {
  final _formKey = GlobalKey<FormState>();
  final _titleArController = TextEditingController();
  final _bodyArController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _bodyEnController = TextEditingController();
  final _urlController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    if (!OneSignalApiService.hasApiKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'مفتاح OneSignal مفقود. راجع تعليمات البناء.',
                'OneSignal key is missing. Check build instructions.',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final success = await OneSignalApiService.sendGlobalNotification(
      titleAr: _titleArController.text.trim(),
      bodyAr: _bodyArController.text.trim(),
      titleEn: _titleEnController.text.trim(),
      bodyEn: _bodyEnController.text.trim(),
      url: _urlController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? tr('تم إرسال الإشعار بنجاح!', 'Notification sent successfully!')
                : tr('فشل إرسال الإشعار. حاول مرة أخرى.', 'Failed to send. Try again.'),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        _titleArController.clear();
        _bodyArController.clear();
        _titleEnController.clear();
        _bodyEnController.clear();
        _urlController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('إرسال إشعار عام', 'Send Global Notification'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppPalette.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'سيتم إرسال هذا الإشعار لجميع مستخدمي التطبيق المشتركين.',
                'This notification will be sent to all subscribed app users.',
              ),
              style: TextStyle(color: AppPalette.mutedText),
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle(tr('المحتوى العربي', 'Arabic Content')),
            _buildTextField(_titleArController, tr('العنوان بالعربية', 'Arabic Title')),
            const SizedBox(height: 12),
            _buildTextField(_bodyArController, tr('النص بالعربية', 'Arabic Body'), maxLines: 3),
            
            const SizedBox(height: 24),
            _buildSectionTitle(tr('المحتوى الإنجليزي', 'English Content')),
            _buildTextField(_titleEnController, tr('العنوان بالإنجليزية', 'English Title')),
            const SizedBox(height: 12),
            _buildTextField(_bodyEnController, tr('النص بالإنجليزية', 'English Body'), maxLines: 3),
            
            const SizedBox(height: 24),
            _buildSectionTitle(tr('رابط إضافي (اختياري)', 'Extra URL (Optional)')),
            _buildTextField(_urlController, 'https://...', icon: Icons.link),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
                label: Text(
                  tr('إرسال الإشعار الآن', 'Send Notification Now'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, IconData? icon}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      validator: (value) => (value == null || value.isEmpty) && maxLines < 5 ? tr('هذا الحقل مطلوب', 'Required') : null,
    );
  }
}
