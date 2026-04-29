import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/admin/admin_image_input_section.dart';
import 'package:leastprice/features/admin/admin_image_upload_service.dart';

class AdminBannerEditorDialog extends StatefulWidget {
  const AdminBannerEditorDialog({super.key, 
    this.initialBanner,
  });

  final AdBannerItem? initialBanner;

  @override
  State<AdminBannerEditorDialog> createState() =>
      _AdminBannerEditorDialogState();
}

class _AdminBannerEditorDialogState extends State<AdminBannerEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _storeNameController;
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _orderController;
  late bool _active;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final banner = widget.initialBanner;
    _storeNameController = TextEditingController(text: banner?.storeName ?? '');
    _titleController = TextEditingController(text: banner?.title ?? '');
    _subtitleController = TextEditingController(text: banner?.subtitle ?? '');
    _imageUrlController = TextEditingController(text: banner?.imageUrl ?? '');
    _orderController = TextEditingController(
      text: banner?.order.toString() ?? '1',
    );
    _active = banner?.active ?? true;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _imageUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return requiredFieldMessage(label, label);
    }
    return null;
  }

  String? _validateUrl(String? value, {bool required = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return required
          ? tr('هذا الرابط مطلوب.', 'This URL is required.')
          : null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return validUrlMessage('رابطاً', 'URL');
    }
    return null;
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await AdminImageUploadService.pickAndUploadImage(
        context,
        folder: 'banners',
        label: _titleController.text.trim().isEmpty
            ? 'banner'
            : _titleController.text.trim(),
        preferredSource: source,
      );
      if (imageUrl == null || !mounted) {
        return;
      }
      _imageUrlController.text = imageUrl;
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر رفع الصورة الآن: $error',
              'Unable to upload the image right now: $error',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      AdBannerItem(
        id: widget.initialBanner?.id ?? '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        targetUrl: LeastPriceDataConfig.adminWhatsAppUrl,
        storeName: _storeNameController.text.trim(),
        active: _active,
        order: int.tryParse(_orderController.text.trim()) ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.initialBanner == null
                        ? tr('إضافة بنر جديد', 'Add new banner')
                        : tr('تعديل البنر', 'Edit banner'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _storeNameController,
                    decoration: InputDecoration(
                      labelText: tr('اسم المتجر', 'Store name'),
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                    validator: (value) => _validateRequired(
                        value, tr('اسم المتجر', 'Store name')),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: tr('عنوان البنر', 'Banner title'),
                      prefixIcon: Icon(Icons.campaign_rounded),
                    ),
                    validator: (value) => _validateRequired(
                      value,
                      tr('عنوان البنر', 'Banner title'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _subtitleController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText:
                          tr('الوصف المختصر', 'Short description'),
                      prefixIcon: Icon(Icons.subject_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AdminImageInputSection(
                    controller: _imageUrlController,
                    label: tr('إضافة صورة اختيارية', 'Optional image'),
                    uploading: _isUploadingImage,
                    validator: _validateUrl,
                    textFieldLabel:
                        tr('إضافة صورة اختيارية', 'Optional image'),
                    helperText: tr(
                      'يمكنك رفع صورة للبنر أو ترك هذا الحقل فارغاً.',
                      'You can upload a banner image or leave this field empty.',
                    ),
                    onPickFromGallery: () =>
                        _pickAndUploadImage(ImageSource.gallery),
                    onPickFromCamera: () =>
                        _pickAndUploadImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _orderController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr('الترتيب', 'Order'),
                      prefixIcon: Icon(Icons.format_list_numbered_rounded),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 0) {
                        return tr(
                          'أدخل رقماً صحيحاً للترتيب.',
                          'Enter a valid number for the order.',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _active,
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('البنر نشط', 'Banner is active')),
                    subtitle: Text(
                      tr(
                        'البنرات غير النشطة لن تظهر للمستخدمين.',
                        'Inactive banners will not appear for users.',
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _active = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(tr('إلغاء', 'Cancel')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text(tr('حفظ', 'Save')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
