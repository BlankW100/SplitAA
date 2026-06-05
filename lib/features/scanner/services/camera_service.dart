import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    return image?.path;
  }

  Future<String?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }
}
