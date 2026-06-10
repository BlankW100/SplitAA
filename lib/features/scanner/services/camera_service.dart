import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  // Receipts are tall and text-dense. ML Kit reads small print far better from
  // a high-resolution, uncompressed image, so we ask for the largest the
  // picker will give us and skip JPEG re-compression.
  Future<String?> takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 100,
      preferredCameraDevice: CameraDevice.rear,
    );
    return image?.path;
  }

  Future<String?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 100,
    );
    return image?.path;
  }
}
