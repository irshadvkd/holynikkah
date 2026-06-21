import 'dart:io';
import 'dart:ui';

import 'package:image_cropper/image_cropper.dart';

class CommonImageCropper {
  static Future<File?> cropImage({
    required String imagePath,
    double ratioX = 3,
    double ratioY = 4,
  }) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,

      aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),

      compressQuality: 100,

      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color(0xFF032544),
          toolbarWidgetColor: const Color(0xFFFFFFFF),
          lockAspectRatio: true,
          hideBottomControls: false,
        ),

        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) {
      return null;
    }

    return File(croppedFile.path);
  }
}
