import 'package:flutter/material.dart';

import 'package:leastprice/core/utils/helpers.dart';

class ProductPane extends StatelessWidget {
  const ProductPane({
    super.key,
    required this.label,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.highlighted,
    required this.icon,
  });

  final String label;
  final String name;
  final double price;
  final String imageUrl;
  final bool highlighted;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        highlighted ? const Color(0xFFE8711A) : const Color(0xFFB54D4D);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF2FBF7) : const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              highlighted ? const Color(0xFFB5E4D4) : const Color(0xFFE2EBE7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.35,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFFFF0E6)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        size: 34,
                        color: Color(0xFF7E9A8F),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF17332B),
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatPrice(price),
            style: TextStyle(
              color: highlighted
                  ? const Color(0xFF0B7A5E)
                  : const Color(0xFF394A44),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
