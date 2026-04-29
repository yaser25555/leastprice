import 'package:flutter/material.dart';

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/admin_product_draft.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/core/utils/helpers.dart';

class AdminAddProductDialog extends StatefulWidget {
  const AdminAddProductDialog({super.key});

  @override
  State<AdminAddProductDialog> createState() => _AdminAddProductDialogState();
}

class _AdminAddProductDialogState extends State<AdminAddProductDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _originalNameController = TextEditingController();
  final TextEditingController _originalPriceController =
      TextEditingController();
  final TextEditingController _alternativePriceController =
      TextEditingController();
  final TextEditingController _affiliateUrlController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  bool _obscurePassword = true;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _categoryController.text = localizedCategoryLabelForId('coffee');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _originalNameController.dispose();
    _originalPriceController.dispose();
    _alternativePriceController.dispose();
    _affiliateUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (_passwordController.text.trim() != LeastPriceDataConfig.adminPassword) {
      setState(() {
        _passwordError = tr(
          'كلمة المرور غير صحيحة.',
          'The admin password is incorrect.',
        );
      });
      return;
    }

    final draft = AdminProductDraft(
      referenceName: _originalNameController.text,
      referencePrice: _parsePrice(_originalPriceController.text),
      comparisonName: _originalNameController.text,
      comparisonPrice: _parsePrice(_alternativePriceController.text),
      buyUrl: AffiliateLinkService.normalizeContactLink(
        _affiliateUrlController.text,
      ),
      categoryLabel: _categoryController.text,
    );

    Navigator.of(context).pop(draft);
  }

  double _parsePrice(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  String? _validateRequired(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return requiredFieldMessage(label, label);
    }

    return null;
  }

  String? _validatePrice(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return requiredFieldMessage(label, label);
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return validValueMessage(label, label);
    }

    return null;
  }

  String? _validateWhatsApp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(
      AffiliateLinkService.normalizeContactLink(value.trim()),
    );
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return tr(
        'أدخل رقم واتساب صحيحاً أو رابط واتساب صالحاً، أو اترك الحقل فارغاً.',
        'Enter a valid WhatsApp number or link, or leave it empty.',
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2FBF7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Color(0xFFE8711A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('لوحة المسؤول', 'Admin panel'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF17332B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr(
                                'أضف منتجاً جديداً ليظهر فوراً داخل التطبيق.',
                                'Add a new product and publish it instantly inside the app.',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF667C74),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: tr('كلمة المرور', 'Password'),
                      prefixIcon: const Icon(Icons.lock_rounded),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() {
                          _passwordError = null;
                        });
                      }
                    },
                    validator: (value) => _validateRequired(
                      value,
                      label: tr('كلمة المرور', 'Password'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _originalNameController,
                    decoration: InputDecoration(
                      labelText: tr(
                        'اسم المنتج المرجعي',
                        'Reference product name',
                      ),
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) => _validateRequired(
                      value,
                      label: tr('اسم المنتج المرجعي', 'Reference product name'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _originalPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: tr(
                        'سعر المنتج المرجعي',
                        'Reference product price',
                      ),
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                    ),
                    validator: (value) => _validatePrice(
                      value,
                      label:
                          tr('سعر المنتج المرجعي', 'Reference product price'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _alternativePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: tr(
                        'سعر الخيار المقارن',
                        'Compared option price',
                      ),
                      prefixIcon: const Icon(Icons.savings_rounded),
                    ),
                    validator: (value) => _validatePrice(
                      value,
                      label: tr('سعر الخيار المقارن', 'Compared option price'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _affiliateUrlController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: tr(
                        'رقم التواصل عبر واتساب (اختياري)',
                        'WhatsApp contact number (optional)',
                      ),
                      prefixIcon: const Icon(Icons.chat_rounded),
                    ),
                    validator: _validateWhatsApp,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: tr('القسم', 'Category'),
                      prefixIcon: const Icon(Icons.category_rounded),
                    ),
                    validator: (value) => _validateRequired(
                      value,
                      label: tr('القسم', 'Category'),
                    ),
                  ),
                  const SizedBox(height: 22),
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
                  const SizedBox(height: 10),
                  Text(
                    tr(
                      'يمكن تغيير كلمة المرور من الثابت adminPassword داخل LeastPriceDataConfig.',
                      'You can change the admin password from the adminPassword constant in LeastPriceDataConfig.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF667C74),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
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
