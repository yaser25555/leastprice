import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/admin/admin_image_input_section.dart';
import 'package:leastprice/features/admin/admin_image_upload_service.dart';

class AdminExclusiveDealEditorDialog extends StatefulWidget {
  const AdminExclusiveDealEditorDialog({
    super.key,
    this.initialDeal,
  });

  final ExclusiveDeal? initialDeal;

  @override
  State<AdminExclusiveDealEditorDialog> createState() =>
      _AdminExclusiveDealEditorDialogState();
}

class _AdminExclusiveDealEditorDialogState
    extends State<AdminExclusiveDealEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _phoneController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _priceController;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDeal;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _phoneController = TextEditingController(text: initial?.phone ?? '');
    _imageUrlController = TextEditingController(text: initial?.imageUrl ?? '');
    _priceController = TextEditingController(
      text: initial != null ? initial.beforePrice.toString() : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _phoneController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return requiredFieldMessage(label, label);
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return tr('أدخل قيمة صحيحة', 'Enter a valid value');
    }
    return null;
  }

  String? _validateUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return validUrlMessage('رابط صورة', 'image URL');
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
        folder: 'exclusive_deals',
        label: _titleController.text.trim().isEmpty
            ? 'exclusive_deal'
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

    final priceInput = _priceController.text.trim();
    final price = priceInput.isNotEmpty ? double.parse(priceInput) : 0.0;
    final now = DateTime.now();

    Navigator.of(context).pop(
      ExclusiveDeal(
        id: widget.initialDeal?.id ?? '',
        title: _titleController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        beforePrice: price,
        afterPrice: 0,
        expiryDate: now.add(const Duration(days: 365)),
        phone: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer_rounded,
                          color: AppPalette.orange, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        widget.initialDeal == null
                            ? tr('إضافة عرض', 'Add deal')
                            : tr('تعديل العرض', 'Edit deal'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2F5E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: tr('اسم المتجر', 'Store name'),
                      hintText: tr('مثال: نون', 'e.g. Noon'),
                      prefixIcon: Icon(Icons.store_rounded),
                    ),
                    validator: (value) => _validateRequired(
                        value, tr('اسم المتجر', 'Store name')),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: tr('هاتف للتواصل', 'Contact phone'),
                      hintText: tr('مثال: 0551234567', 'e.g. 0551234567'),
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AdminImageInputSection(
                    controller: _imageUrlController,
                    label: tr('صورة العرض', 'Deal image'),
                    uploading: _isUploadingImage,
                    validator: _validateUrl,
                    textFieldLabel: tr('صورة العرض', 'Deal image'),
                    helperText: tr(
                      'يمكنك رفع صورة أو لصق رابط صورة.',
                      'Upload or paste an image URL.',
                    ),
                    onPickFromGallery: () =>
                        _pickAndUploadImage(ImageSource.gallery),
                    onPickFromCamera: () =>
                        _pickAndUploadImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: tr('السعر', 'Price'),
                      hintText: tr('مثال: 299', 'e.g. 299'),
                      prefixIcon: Icon(Icons.money_rounded),
                    ),
                    validator: _validatePrice,
                  ),
                  const SizedBox(height: 24),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.orange,
                            foregroundColor: Colors.white,
                          ),
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
