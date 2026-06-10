import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

enum QrValidationStatus { ok, noQrFound, tooSmall }

class QrValidationResult {
  final QrValidationStatus status;
  final String? previewData;

  const QrValidationResult(this.status, {this.previewData});

  bool get isOk => status == QrValidationStatus.ok;

  String get message {
    switch (status) {
      case QrValidationStatus.ok:
        return 'QR detected — will display correctly on receipts.';
      case QrValidationStatus.noQrFound:
        return 'No QR code detected. Try cropping tighter around the QR, '
            'or use a clearer image. You can still save it, but it may not scan.';
      case QrValidationStatus.tooSmall:
        return 'QR code found but content is very short — double-check it is '
            'your payment QR.';
    }
  }
}

/// Scans [imagePath] with ML Kit barcode scanner and returns a validation result.
class QrValidator {
  static Future<QrValidationResult> validate(String imagePath) async {
    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final barcodes = await scanner.processImage(input);
      if (barcodes.isEmpty) {
        return const QrValidationResult(QrValidationStatus.noQrFound);
      }
      final raw = barcodes.first.rawValue ?? barcodes.first.displayValue ?? '';
      if (raw.length < 4) {
        return QrValidationResult(QrValidationStatus.tooSmall, previewData: raw);
      }
      final preview = raw.length > 60 ? '${raw.substring(0, 60)}…' : raw;
      return QrValidationResult(QrValidationStatus.ok, previewData: preview);
    } finally {
      await scanner.close();
    }
  }
}
