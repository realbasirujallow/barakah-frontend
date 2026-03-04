import 'package:dio/dio.dart';

class CurrencyService {
  static const Map<String, String> supportedCurrencies = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'SAR': 'Saudi Riyal',
    'AED': 'UAE Dirham',
    'MYR': 'Malaysian Ringgit',
    'IDR': 'Indonesian Rupiah',
    'TRY': 'Turkish Lira',
    'PKR': 'Pakistani Rupee',
    'BDT': 'Bangladeshi Taka',
    'NGN': 'Nigerian Naira',
    'EGP': 'Egyptian Pound',
    'INR': 'Indian Rupee',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
  };

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'SAR': '﷼',
    'AED': 'د.إ',
    'MYR': 'RM',
    'IDR': 'Rp',
    'TRY': '₺',
    'PKR': '₨',
    'BDT': '৳',
    'NGN': '₦',
    'EGP': 'E£',
    'INR': '₹',
    'CAD': 'C\$',
    'AUD': 'A\$',
  };

  final Dio _dio = Dio();
  Map<String, double> _rates = {};
  DateTime? _lastFetch;

  static final CurrencyService _instance = CurrencyService._();
  factory CurrencyService() => _instance;
  CurrencyService._();

  Future<Map<String, double>> getRates({String base = 'USD'}) async {
    // Cache rates for 1 hour
    if (_rates.isNotEmpty && _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 60) {
      return _rates;
    }

    try {
      // Using free Open Exchange Rates API (no key required)
      final response = await _dio.get(
        'https://open.er-api.com/v6/latest/$base',
      );

      if (response.data != null && response.data['rates'] != null) {
        final Map<String, dynamic> rawRates = response.data['rates'];
        _rates = rawRates.map((key, value) => MapEntry(key, (value as num).toDouble()));
        _lastFetch = DateTime.now();
      }
    } catch (_) {
      // Fallback with approximate rates if API fails
      if (_rates.isEmpty) {
        _rates = {
          'USD': 1.0, 'EUR': 0.92, 'GBP': 0.79, 'SAR': 3.75,
          'AED': 3.67, 'MYR': 4.47, 'IDR': 15700.0, 'TRY': 30.5,
          'PKR': 278.0, 'BDT': 110.0, 'NGN': 1550.0, 'EGP': 30.9,
          'INR': 83.1, 'CAD': 1.36, 'AUD': 1.53,
        };
      }
    }
    return _rates;
  }

  Future<double> convert(double amount, String from, String to) async {
    if (from == to) return amount;
    final rates = await getRates();
    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;
    return amount / fromRate * toRate;
  }

  String getSymbol(String code) => currencySymbols[code] ?? code;
  String getName(String code) => supportedCurrencies[code] ?? code;
}
