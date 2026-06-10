/// A supported display currency.
///
/// The app stores all monetary values in [baseCode] (MYR). The user can pick a
/// different currency just for *display*; conversion happens at render time
/// using cached exchange rates.
class Currency {
  final String code; // ISO 4217, e.g. "USD"
  final String symbol; // e.g. "$"
  final String name; // e.g. "US Dollar"

  const Currency(this.code, this.symbol, this.name);
}

/// The currency every stored amount is denominated in.
const String baseCode = 'MYR';

/// Currencies offered in the picker. All are supported by the Frankfurter API
/// (ECB reference set), so cached rates will always cover them.
const List<Currency> supportedCurrencies = [
  Currency('MYR', 'RM', 'Malaysian Ringgit'),
  Currency('USD', '\$', 'US Dollar'),
  Currency('EUR', '€', 'Euro'),
  Currency('GBP', '£', 'British Pound'),
  Currency('SGD', 'S\$', 'Singapore Dollar'),
  Currency('AUD', 'A\$', 'Australian Dollar'),
  Currency('JPY', '¥', 'Japanese Yen'),
  Currency('CNY', '¥', 'Chinese Yuan'),
  Currency('INR', '₹', 'Indian Rupee'),
  Currency('THB', '฿', 'Thai Baht'),
  Currency('IDR', 'Rp', 'Indonesian Rupiah'),
  Currency('PHP', '₱', 'Philippine Peso'),
  Currency('KRW', '₩', 'South Korean Won'),
];

Currency currencyForCode(String code) => supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => supportedCurrencies.first,
    );
