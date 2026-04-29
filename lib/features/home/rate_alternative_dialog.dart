import 'package:flutter/material.dart';

import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/core/utils/helpers.dart';

class RateAlternativeDialog extends StatefulWidget {
  const RateAlternativeDialog({super.key, 
    required this.product,
  });

  final ProductComparison product;

  @override
  State<RateAlternativeDialog> createState() => _RateAlternativeDialogState();
}

class _RateAlternativeDialogState extends State<RateAlternativeDialog> {
  late double _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.product.rating > 0 ? widget.product.rating : 4.0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('تقييم جودة الخيار المقارن',
                  'Rate the compared option'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17332B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'كيف ترى "${widget.product.alternativeName}" من حيث الجودة والمكوّنات مقارنةً بـ "${widget.product.expensiveName}"؟',
                'How do you rate "${widget.product.alternativeName}" in quality and ingredients compared with "${widget.product.expensiveName}"?',
              ),
              style: const TextStyle(
                color: Color(0xFF667C74),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                spacing: 8,
                children: List.generate(5, (index) {
                  final value = index + 1.0;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedRating = value;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _selectedRating >= value
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFF5B400),
                        size: 34,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                tr(
                  '${_selectedRating.toStringAsFixed(1)} من 5',
                  '${_selectedRating.toStringAsFixed(1)} out of 5',
                ),
                style: const TextStyle(
                  color: Color(0xFF7A5A00),
                  fontWeight: FontWeight.w800,
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
                    onPressed: () => Navigator.of(context).pop(_selectedRating),
                    child:
                        Text(tr('إرسال التقييم', 'Submit rating')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
