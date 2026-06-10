import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'currency.dart';

/// Holds the user's chosen display currency and the cached exchange rates.
///
/// Offline-first: rates are fetched from the free, key-less Frankfurter API and
/// cached in [SharedPreferences]. Conversions always read from the cache, so the
/// app is fully usable with no network — it only reaches out when the user (or
/// first launch) explicitly refreshes.
class CurrencyProvider with ChangeNotifier {
  static const _kDisplayCode = 'display_currency';
  static const _kRates = 'fx_rates';
  static const _kUpdatedAt = 'fx_updated_at';

  // Rates expressed as: 1 MYR = _rates[code] units of `code`.
  Map<String, double> _rates = {baseCode: 1.0};
  String _displayCode = baseCode;
  DateTime? _updatedAt;
  bool _refreshing = false;

  String get displayCode => _displayCode;
  Currency get displayCurrency => currencyForCode(_displayCode);
  DateTime? get updatedAt => _updatedAt;
  bool get refreshing => _refreshing;

  /// True once we have rates beyond the trivial base entry.
  bool get hasRates => _rates.length > 1;

  /// Load persisted preference + cached rates. Call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _displayCode = prefs.getString(_kDisplayCode) ?? baseCode;

    final cached = prefs.getString(_kRates);
    if (cached != null) {
      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      _rates = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      _rates[baseCode] = 1.0;
    }
    final ts = prefs.getInt(_kUpdatedAt);
    if (ts != null) _updatedAt = DateTime.fromMillisecondsSinceEpoch(ts);

    notifyListeners();
  }

  Future<void> setDisplayCurrency(String code) async {
    _displayCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayCode, code);
  }

  /// Fetch fresh rates. Returns true on success; on failure keeps the old cache
  /// and returns false so the UI can say "couldn't update, using saved rates".
  Future<bool> refreshRates() async {
    _refreshing = true;
    notifyListeners();
    try {
      final symbols = supportedCurrencies
          .map((c) => c.code)
          .where((c) => c != baseCode)
          .join(',');
      final uri = Uri.parse(
        'https://api.frankfurter.dev/v1/latest?base=$baseCode&symbols=$symbols',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return false;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final rates = (body['rates'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      rates[baseCode] = 1.0;

      _rates = rates;
      _updatedAt = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRates, jsonEncode(_rates));
      await prefs.setInt(_kUpdatedAt, _updatedAt!.millisecondsSinceEpoch);
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  /// Convert an amount stored in MYR into the display currency.
  double convertFromBase(double amountInBase) {
    final rate = _rates[_displayCode] ?? 1.0;
    return amountInBase * rate;
  }

  /// Format a base-currency (MYR) amount into the user's display currency,
  /// e.g. 25.0 -> "$5.30" when USD is selected.
  String format(double amountInBase) {
    final value = convertFromBase(amountInBase);
    final c = displayCurrency;
    // No-decimal currencies look odd with cents.
    final fractionDigits = (c.code == 'JPY' || c.code == 'KRW' || c.code == 'IDR') ? 0 : 2;
    return '${c.symbol}${value.toStringAsFixed(fractionDigits)}';
  }
}
