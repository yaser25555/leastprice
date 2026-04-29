import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/features/admin/admin_image_input_section.dart';
import 'package:leastprice/features/admin/admin_image_upload_service.dart';

class AdminExclusiveDealEditorDialog extends StatefulWidget {
  const AdminExclusiveDealEditorDialog({super.key, 
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
  late final TextEditingController _imageUrlController;
  late final TextEditingController _beforePriceController;
  late final TextEditingController _afterPriceController;
  late DateTime _expiryDate;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDeal;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _imageUrlController = TextEditingController(text: initial?.imageUrl ?? '');
    _beforePriceController = TextEditingController(
      text: initial != null ? initial.beforePrice.toString() : '',
    );
    _afterPriceController = TextEditingController(
      text: initial != null ? initial.afterPrice.toString() : '',
    );
    _expiryDate =
        initial?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _beforePriceController.dispose();
    _afterPriceController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return requiredFieldMessage(label, label);
    }
    return null;
  }

  String? _validatePrice(String? value, String label) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return validValueMessage(label, label);
    }
    return null;
  }

  String? _validateDiscountPrice(String? value) {
    final afterPrice = double.tryParse(value?.trim() ?? '');
    final beforePrice = double.tryParse(_beforePriceController.text.trim());
    if (afterPrice == null || afterPrice <= 0) {
      return tr(
        'أدخل قيمة صحيحة للسعر بعد الخصم.',
        'Enter a valid value for the discounted price.',
      );
    }
    if (beforePrice != null && afterPrice >= beforePrice) {
      return tr(
        'يجب أن يكون السعر بعد الخصم أقل من السعر قبل الخصم.',
        'The discounted price must be lower than the original price.',
      );
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

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _expiryDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
      );
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      ExclusiveDeal(
        id: widget.initialDeal?.id ?? '',
        title: _titleController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        beforePrice: double.parse(_beforePriceController.text.trim()),
        afterPrice: double.parse(_afterPriceController.text.trim()),
        expiryDate: _expiryDate,
        active: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
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
                    widget.initialDeal == null
                        ? tr('إضافة عرض حصري', 'Add exclusive deal')
                        : tr('تعديل العرض الحصري',
                            'Edit exclusive deal'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: tr('عنوان العرض', 'Deal title'),
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (value) => _validateRequired(
                        value, tr('عنوان العرض', 'Deal title')),
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
                      'يمكنك رفع صورة للعرض أو تركها فارغة.',
                      'You can upload a deal image or leave it empty.',
                    ),
                    onPickFromGallery: () =>
                        _pickAndUploadImage(ImageSource.gallery),
                    onPickFromCamera: () =>
                        _pickAndUploadImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _beforePriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: tr('السعر قبل', 'Before price'),
                      prefixIcon: Icon(Icons.money_off_csred_rounded),
                    ),
                    validator: (value) => _validatePrice(
                        value, tr('السعر قبل', 'Before price')),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _afterPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: tr('السعر بعد', 'After price'),
                      prefixIcon: Icon(Icons.local_offer_rounded),
                    ),
                    validator: _validateDiscountPrice,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickExpiryDate,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppPalette.dealsSoftRed,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppPalette.dealsBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded,
                              color: AppPalette.dealsRed),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('تاريخ انتهاء العرض',
                                      'Deal expiry date'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1B2F5E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatDealExpiryLabel(_expiryDate),
                                  style: const TextStyle(
                                    color: Color(0xFF6B7A9A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_calendar_rounded,
                              color: AppPalette.dealsRed),
                        ],
                      ),
                    ),
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
