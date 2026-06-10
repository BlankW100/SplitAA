import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../database/db_helper.dart';

/// Result of attempting to import a backup file.
enum ImportStatus { success, wrongFormat, tampered, unreadable }

class ImportResult {
  final ImportStatus status;
  final int restoredCount;
  const ImportResult(this.status, [this.restoredCount = 0]);

  String get message => switch (status) {
        ImportStatus.success => 'Restored $restoredCount record(s).',
        ImportStatus.wrongFormat => 'This is not a Splitaa backup file.',
        ImportStatus.tampered =>
          'This backup has been modified or is corrupted — it was not imported.',
        ImportStatus.unreadable => 'The file could not be read.',
      };
}

/// Exports/imports the local database as a signed, tamper-evident file.
///
/// The file is JSON wrapped in an envelope with a magic [_magic] marker and an
/// HMAC-SHA256 [signature] over the payload. On import we recompute the HMAC; if
/// it doesn't match (file edited, or not produced by Splitaa) the import is
/// rejected. Note: the key is embedded in the app, so this detects casual
/// tampering and fake files — it is not protection against a determined attacker
/// who reverse-engineers the key.
class BackupService {
  static const _magic = 'splitaa.backup';
  static const _version = 1;
  // App-embedded HMAC key. Changing this invalidates older backups.
  static const _secret = 'sPL1t4a-b@ckup-k3y-v1-7Qz';

  static String _sign(String payload) {
    final hmac = Hmac(sha256, utf8.encode(_secret));
    return hmac.convert(utf8.encode(payload)).toString();
  }

  /// Build a signed backup file and return its path (for sharing/saving).
  static Future<String> export() async {
    final db = await DatabaseHelper.instance.database;
    final ledger = await db.query('ledger');

    final data = {'ledger': ledger};
    final payload = jsonEncode(data);

    final envelope = {
      'format': _magic,
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
      'signature': _sign(payload),
    };

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File('${dir.path}/splitaa_backup_$stamp.splitaa');
    await file.writeAsString(jsonEncode(envelope));
    return file.path;
  }

  /// Validate and restore a backup file. Replaces existing ledger data.
  static Future<ImportResult> import(String path) async {
    Map<String, dynamic> envelope;
    try {
      final raw = await File(path).readAsString();
      envelope = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const ImportResult(ImportStatus.unreadable);
    }

    if (envelope['format'] != _magic || envelope['data'] is! Map) {
      return const ImportResult(ImportStatus.wrongFormat);
    }

    final data = envelope['data'] as Map<String, dynamic>;
    final expected = _sign(jsonEncode(data));
    if (envelope['signature'] != expected) {
      return const ImportResult(ImportStatus.tampered);
    }

    final rows = (data['ledger'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('ledger');
      for (final row in rows) {
        await txn.insert('ledger', row);
      }
    });
    return ImportResult(ImportStatus.success, rows.length);
  }
}
