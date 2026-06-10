import 'package:image_cropper/image_cropper.dart';

/// Native crop UI with two presets: free-form for receipts and square for QRs.
class CropService {
  static final _cropper = ImageCropper();

  /// Opens the crop UI for a receipt photo. Free aspect ratio, portrait hint.
  /// Returns the cropped path, or null if the user cancelled.
  static Future<String?> cropReceipt(String sourcePath) async {
    final result = await _cropper.cropImage(
      sourcePath: sourcePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Receipt',
          lockAspectRatio: false,
          initAspectRatio: CropAspectRatioPreset.original,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
          ],
        ),
        IOSUiSettings(title: 'Crop Receipt'),
      ],
    );
    return result?.path;
  }

  /// Opens the crop UI for a payment QR image, locked to a 1:1 square.
  /// Returns the cropped path, or null if the user cancelled.
  static Future<String?> cropQr(String sourcePath) async {
    final result = await _cropper.cropImage(
      sourcePath: sourcePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Payment QR',
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Crop Payment QR',
          minimumAspectRatio: 1.0,
          rotateButtonsHidden: true,
          resetButtonHidden: true,
        ),
      ],
    );
    return result?.path;
  }
}
