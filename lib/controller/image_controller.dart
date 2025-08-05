import 'dart:io';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';
import '../model/image_model.dart';
import '../model/db_helper.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageController {
  final DBHelper dbHelper = DBHelper();

  Future<String?> pickAndSaveImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      // Step 1: Load image
      final Uint8List bytes = await picked.readAsBytes();
      final img.Image? original = img.decodeImage(bytes);
      if (original == null) return null;

      // Step 2: Resize to 600x600 pixels
      final img.Image squareImage = img.copyResizeCropSquare(
        original,
        size: 400,
      );

      // Step 3: Create circular avatar
      final img.Image circularAvatar = createCircularAvatar(squareImage);

      // Step 4: Encode as PNG (preserves transparency)
      final avatarBytes = img.encodePng(circularAvatar);

      // Step 5: Save to file
      final Directory dir = await getApplicationDocumentsDirectory();
      final String newPath =
          join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      final File avatarFile = File(newPath);
      await avatarFile.writeAsBytes(avatarBytes);

      // Save to DB (assuming dbHelper and ImageModel are defined)
      await dbHelper.insertImage(
        ImageModel(
          path: avatarFile.path,
          status: 'pending',
        ),
      );

      return avatarFile.path;
    }

    return null;
  }

  /// Converts a square image to a circular image with a transparent background.
  ///
  /// This function is optimized to work with any square image size.
  img.Image createCircularAvatar(img.Image squareImage) {
    final int size = squareImage.width;
    final int radius = size ~/ 2;
    final int centerX = radius;
    final int centerY = radius;

    // Step 1: Create a new image with a transparent background.
    final img.Image circularAvatar = img.Image(width: size, height: size);
    // Step 2: Iterate through the pixels of the original image.
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dx = x - centerX;
        final dy = y - centerY;

        // Step 3: Use the circle equation to check if the pixel is within the radius.
        if (dx * dx + dy * dy <= radius * radius) {
          // If inside the circle, copy the pixel color from the original image.
          circularAvatar.setPixel(x, y, squareImage.getPixel(x, y));
        } else {
          circularAvatar.setPixelRgba(x, y, 255, 255, 255, 0);
        }
        // Pixels outside the circle are already transparent from the initial fill.
      }
    }

    return circularAvatar;
  }

  Future<List<ImageModel>> getAllImages() {
    return dbHelper.fetchImages(); // ✅ get list of stored image paths
  }

  Future<void> deleteImage(int id) async {
    await dbHelper.deleteImage(id); // ✅ delete image from DB
  }

  Future<void> updateImage(ImageModel image) async {
    await dbHelper.updateImage(image); // ✅ update image status in DB
  }
}
