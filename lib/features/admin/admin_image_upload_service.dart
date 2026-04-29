import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/core/utils/helpers.dart';

class AdminImageUploadService {
  const AdminImageUploadService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndUploadImage(
    BuildContext context, {
    required String folder,
    required String label,
    ImageSource? preferredSource,
  }) async {
    final source = preferredSource ?? await _pickSource(context);
    if (source == null) {
      return null;
    }

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (pickedFile == null) {
      return null;
    }

    final Uint8List bytes = await pickedFile.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError(
        tr(
          'تعذر قراءة الصورة التي تم اختيارها.',
          'Unable to read the selected image.',
        ),
      );
    }

    final extension = _resolveExtension(pickedFile.name);
    final fileName = _buildFileName(label, extension);
    final objectPath =
        '${LeastPriceDataConfig.adminUploadsPath}/$folder/$fileName';

    final metadata = SettableMetadata(
      contentType: _resolveContentType(extension),
      customMetadata: <String, String>{
        'uploadedBy': 'leastprice-admin',
        'label': label.trim(),
      },
    );

    final storageRef = FirebaseStorage.instance.ref().child(objectPath);
    final uploadTask = storageRef.putData(bytes, metadata);
    await uploadTask.whenComplete(() {});
    return storageRef.getDownloadURL();
  }

  static Future<ImageSource?> _pickSource(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: Text(tr('اختيار من المعرض', 'Choose from gallery')),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: Text(tr('التقاط من الكاميرا', 'Capture from camera')),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _buildFileName(String label, String extension) {
    final sanitizedLabel = label
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u0621-\u064A]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final safeLabel = sanitizedLabel.isEmpty ? 'leastprice' : sanitizedLabel;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${safeLabel}_$timestamp.$extension';
  }

  static String _resolveExtension(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'png';
    }
    if (normalized.endsWith('.webp')) {
      return 'webp';
    }
    if (normalized.endsWith('.gif')) {
      return 'gif';
    }
    return 'jpg';
  }

  static String _resolveContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
