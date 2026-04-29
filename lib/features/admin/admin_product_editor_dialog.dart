import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:leastprice/data/models/product_category.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/features/admin/admin_image_input_section.dart';
import 'package:leastprice/features/admin/admin_image_upload_service.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/core/utils/helpers.dart';

class AdminProductEditorDialog extends StatefulWidget {
  const AdminProductEditorDialog({
    super.key,
    this.initialProduct,
  });

  final ProductComparison? initialProduct;

  @override
  State<AdminProductEditorDialog> createState() =>
      _AdminProductEditorDialogState();
}

class _AdminProductEditorDialogState extends State<AdminProductEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _expensiveNameController;
  late final TextEditingController _expensivePriceController;
  late final TextEditingController _expensiveImageUrlController;
  late final TextEditingController _alternativePriceController;
  late final TextEditingController _alternativeImageUrlController;
  late final TextEditingController _buyUrlController;
  late String _selectedCategoryId;
  late final List<ProductCategory> _categories;
  bool _isUploadingReferenceImage = false;
  bool _isUploadingComparisonImage = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProduct;
    _expensiveNameController = TextEditingController(
      text: initial?.expensiveName ?? '',
    );
    _expensivePriceController = TextEditingController(
      text: initial != null ? initial.expensivePrice.toString() : '',
    );
    _expensiveImageUrlController = TextEditingController(
      text: initial?.expensiveImageUrl ?? '',
    );
    _alternativePriceController = TextEditingController(
      text: initial != null ? initial.alternativePrice.toString() : '',
    );
    _alternativeImageUrlController = TextEditingController(
      text: initial?.alternativeImageUrl ?? '',
    );
    _buyUrlController = TextEditingController(text: initial?.buyUrl ?? '');

    _categories = ProductCategoryCatalog.defaults
        .where((category) => category.id != ProductCategoryCatalog.allId)
        .toList();

    final currentCategoryId =
        initial?.categoryId ?? ProductCategoryCatalog.defaults[1].id;
    if (!_categories.any((category) => category.id == currentCategoryId)) {
      _categories.insert(
        0,
        ProductCategoryCatalog.lookup(
          currentCategoryId,
          fallbackLabel: initial?.categoryLabel ?? currentCategoryId,
        ),
      );
    }
    _selectedCategoryId = currentCategoryId;
  }

  @override
  void dispose() {
    _expensiveNameController.dispose();
    _expensivePriceController.dispose();
    _expensiveImageUrlController.dispose();
    _alternativePriceController.dispose();
    _alternativeImageUrlController.dispose();
    _buyUrlController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label مطلوب.';
    }
    return null;
  }

  String? _validatePrice(String? value, String label) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'أدخل قيمة صحيحة لـ $label.';
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
      return validUrlMessage('رابطاً', 'URL');
    }
    return null;
  }

  String? _validateWhatsApp(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(
      AffiliateLinkService.normalizeContactLink(trimmed),
    );
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return tr(
        'أدخل رقم واتساب صحيحاً أو رابط واتساب صالحاً.',
        'Enter a valid WhatsApp number or link.',
      );
    }
    return null;
  }

  List<String> _composeTags(ProductCategory category) {
    final tags = <String>{
      category.label,
      _expensiveNameController.text.trim(),
      ...?widget.initialProduct?.tags,
    };

    return tags.where((tag) => tag.trim().isNotEmpty).toList();
  }

  Future<void> _pickAndUploadReferenceImage(ImageSource source) async {
    await _pickAndUploadIntoController(
      controller: _expensiveImageUrlController,
      source: source,
      folder: 'products/reference',
      defaultLabel: 'reference_product',
      onUploadingChanged: (value) {
        setState(() {
          _isUploadingReferenceImage = value;
        });
      },
    );
  }

  Future<void> _pickAndUploadComparisonImage(ImageSource source) async {
    await _pickAndUploadIntoController(
      controller: _alternativeImageUrlController,
      source: source,
      folder: 'products/comparison',
      defaultLabel: 'comparison_option',
      onUploadingChanged: (value) {
        setState(() {
          _isUploadingComparisonImage = value;
        });
      },
    );
  }

  Future<void> _pickAndUploadIntoController({
    required TextEditingController controller,
    required ImageSource source,
    required String folder,
    required String defaultLabel,
    required ValueChanged<bool> onUploadingChanged,
  }) async {
    onUploadingChanged(true);
    try {
      final imageUrl = await AdminImageUploadService.pickAndUploadImage(
        context,
        folder: folder,
        label: _expensiveNameController.text.trim().isEmpty
            ? defaultLabel
            : _expensiveNameController.text.trim(),
        preferredSource: source,
      );
      if (imageUrl == null || !mounted) {
        return;
      }
      controller.text = imageUrl;
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
        onUploadingChanged(false);
      }
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final selectedCategory = ProductCategoryCatalog.lookup(_selectedCategoryId);
    final initial = widget.initialProduct;

    Navigator.of(context).pop(
      ProductComparison(
        documentId: initial?.documentId,
        categoryId: selectedCategory.id,
        categoryLabel: selectedCategory.label,
        expensiveName: _expensiveNameController.text.trim(),
        expensivePrice: double.parse(_expensivePriceController.text.trim()),
        expensiveImageUrl: _expensiveImageUrlController.text.trim(),
        alternativeName: _expensiveNameController.text.trim(),
        alternativePrice: double.parse(_alternativePriceController.text.trim()),
        alternativeImageUrl: _alternativeImageUrlController.text.trim(),
        buyUrl: AffiliateLinkService.normalizeContactLink(
          _buyUrlController.text.trim(),
        ),
        rating: initial?.rating ?? 0,
        reviewCount: initial?.reviewCount ?? 0,
        tags: _composeTags(selectedCategory),
        fragranceNotes: initial?.fragranceNotes,
        activeIngredients: initial?.activeIngredients,
        localLocationLabel: initial?.localLocationLabel,
        localLocationUrl: initial?.localLocationUrl,
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
                    widget.initialProduct == null
                        ? tr('إضافة منتج جديد', 'Add new product')
                        : tr('تعديل المنتج', 'Edit product'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2F5E),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: tr('القسم', 'Category'),
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(
                              localizedCategoryLabelForId(
                                category.id,
                                fallbackLabel: category.label,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expensiveNameController,
                    decoration: InputDecoration(
                      labelText:
                          tr('اسم المنتج المرجعي', 'Reference product name'),
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) => _validateRequired(
                      value,
                      tr('اسم المنتج المرجعي', 'Reference product name'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expensivePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          tr('سعر المنتج المرجعي', 'Reference product price'),
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    validator: (value) => _validatePrice(
                      value,
                      tr('سعر المنتج المرجعي', 'Reference product price'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AdminImageInputSection(
                    controller: _expensiveImageUrlController,
                    label: tr('إضافة صورة اختيارية', 'Optional image'),
                    uploading: _isUploadingReferenceImage,
                    validator: _validateUrl,
                    textFieldLabel:
                        tr('إضافة صورة اختيارية', 'Optional image'),
                    helperText: tr(
                      'يمكنك رفع صورة للمنتج المرجعي أو تركها فارغة.',
                      'You can upload a reference product image or leave it empty.',
                    ),
                    onPickFromGallery: () =>
                        _pickAndUploadReferenceImage(ImageSource.gallery),
                    onPickFromCamera: () =>
                        _pickAndUploadReferenceImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          tr('سعر الخيار المقارن', 'Compared option price'),
                      prefixIcon: Icon(Icons.savings_rounded),
                    ),
                    validator: (value) => _validatePrice(
                      value,
                      tr('سعر الخيار المقارن', 'Compared option price'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AdminImageInputSection(
                    controller: _alternativeImageUrlController,
                    label: tr('إضافة صورة اختيارية', 'Optional image'),
                    uploading: _isUploadingComparisonImage,
                    validator: _validateUrl,
                    textFieldLabel:
                        tr('إضافة صورة اختيارية', 'Optional image'),
                    helperText: tr(
                      'يمكنك رفع صورة للخيار المقارن أو تركها فارغة.',
                      'You can upload a comparison image or leave it empty.',
                    ),
                    onPickFromGallery: () =>
                        _pickAndUploadComparisonImage(ImageSource.gallery),
                    onPickFromCamera: () =>
                        _pickAndUploadComparisonImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _buyUrlController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: tr(
                        'رقم التواصل عبر واتساب',
                        'WhatsApp contact number',
                      ),
                      prefixIcon: Icon(Icons.chat_rounded),
                    ),
                    validator: _validateWhatsApp,
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
