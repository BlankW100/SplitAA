import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's own payment QR (DuitNow / bank / e-wallet screenshot) so
/// it can be embedded into generated receipts. Fully local — the image is
/// copied into the app's documents directory and its path kept in prefs.
class PaymentProfileService {
  static const _kQrPath = 'payment_qr_path';

  /// Returns the saved QR image path, or null if none / the file is gone.
  static Future<String?> getQrPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kQrPath);
    if (path != null && File(path).existsSync()) return path;
    return null;
  }

  /// Copies [sourcePath] into app storage and remembers it. Returns the new path.
  static Future<String> setQr(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(sourcePath);
    final dest = p.join(dir.path, 'payment_qr$ext');
    // Remove any previous file first to avoid stale extensions lingering.
    await _deleteExisting();
    await File(sourcePath).copy(dest);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kQrPath, dest);
    return dest;
  }

  static Future<void> clear() async {
    await _deleteExisting();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kQrPath);
  }

  static Future<void> _deleteExisting() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kQrPath);
    if (path != null) {
      try {
        final f = File(path);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
    }
  }
}
