import 'package:flutter/material.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';

class AdminImageInputSection extends StatelessWidget {
  const AdminImageInputSection({
    super.key,
    required this.controller,
    required this.label,
    required this.uploading,
    required this.validator,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    this.textFieldLabel,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final bool uploading;
  final String? Function(String?) validator;
  final Future<void> Function() onPickFromGallery;
  final Future<void> Function() onPickFromCamera;
  final String? textFieldLabel;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final imageUrl = value.text.trim();
        final hasImage = imageUrl.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                ),
                if (uploading) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('جارٍ الرفع...', 'Uploading...'),
                    style: const TextStyle(
                      color: AppPalette.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 158,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3EE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasImage
                      ? AppPalette.orange.withValues(alpha: 0.45)
                      : const Color(0x1F1B2F5E),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _ImagePlaceholder(label: label);
                      },
                    )
                  : _ImagePlaceholder(label: label),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: uploading ? null : onPickFromGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(tr('المعرض', 'Gallery')),
                ),
                OutlinedButton.icon(
                  onPressed: uploading ? null : onPickFromCamera,
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: Text(tr('الكاميرا', 'Camera')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: textFieldLabel ?? tr('رابط الصورة', 'Image URL'),
                helperText: helperText ??
                    tr(
                      'يمكنك الرفع مباشرة أو لصق رابط صورة يدويًا.',
                      'You can upload directly or paste an image URL manually.',
                    ),
                prefixIcon: const Icon(Icons.link_rounded),
              ),
              validator: validator,
            ),
          ],
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF8F4),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_outlined,
            size: 38,
            color: Color(0xFFB67D4A),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7D6655),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
