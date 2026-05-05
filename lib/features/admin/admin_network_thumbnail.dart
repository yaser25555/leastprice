import 'package:flutter/material.dart';

class AdminNetworkThumbnail extends StatelessWidget {
  const AdminNetworkThumbnail({
    super.key,
    required this.imageUrl,
    required this.label,
  });

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF2FBF7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_not_supported_rounded),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 52,
            height: 52,
            color: const Color(0xFFF2FBF7),
            alignment: Alignment.center,
            child: Text(
              label.trim().isNotEmpty ? label.trim()[0] : '?',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          );
        },
      ),
    );
  }
}
