import 'package:flutter/material.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:barakah_app/services/currency_service.dart';

/// Standalone currency converter screen.
/// Uses the existing CurrencyService (local free API + fallback static rates).
/// Accessible from Settings → Finance → Currency Converter.
class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _currencyService = CurrencyService();
  final _amountController = TextEditingController(text: '100');

  final _currencies = CurrencyService.supportedCurrencies.keys.toList();
  String _fromCurrency = 'USD';
  String _toCurrency = 'GBP';

  Map<String, double>? _rates;
  double? _result;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadAndConvert();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadAndConvert() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rates = await _currencyService.getRates();
      if (!mounted) return;
      setState(() {
        _rates = rates;
        _lastUpdated = DateTime.now();
      });
      await _convert();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load exchange rates. Using cached rates.');
      await _convert(); // still try with fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _convert() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null) {
      setState(() => _result = null);
      return;
    }
    try {
      final result =
          await _currencyService.convert(amount, _fromCurrency, _toCurrency);
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) setState(() => _result = null);
    }
  }

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convert();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final symbols = CurrencyService.currencySymbols;
    final names = CurrencyService.supportedCurrencies;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(
            onPressed: _loadAndConvert,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh rates',
          ),
        ],
      ),
      body: _isLoading && _rates == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Rate freshness chip ────────────────────────────────────
                  if (_lastUpdated != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.deepGreen.withAlpha(isDark ? 30 : 15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.deepGreen.withAlpha(40)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: AppTheme.deepGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Rates updated ${_timeAgo(_lastUpdated!)}',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.deepGreen),
                          ),
                        ],
                      ),
                    ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12)),
                  ],

                  const SizedBox(height: 24),

                  // ── Amount input ───────────────────────────────────────────
                  Text('Amount',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      prefixText:
                          '${symbols[_fromCurrency] ?? _fromCurrency} ',
                      hintText: '0.00',
                    ),
                    onChanged: (_) => _convert(),
                  ),
                  const SizedBox(height: 24),

                  // ── From / Swap / To ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _CurrencyDropdown(
                          label: 'From',
                          value: _fromCurrency,
                          currencies: _currencies,
                          symbols: symbols,
                          names: names,
                          onChanged: (v) {
                            setState(() => _fromCurrency = v!);
                            _convert();
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: _swap,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppTheme.deepGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_horiz,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      Expanded(
                        child: _CurrencyDropdown(
                          label: 'To',
                          value: _toCurrency,
                          currencies: _currencies,
                          symbols: symbols,
                          names: names,
                          onChanged: (v) {
                            setState(() => _toCurrency = v!);
                            _convert();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Result card ────────────────────────────────────────────
                  if (_result != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.deepGreen, Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_amountController.text} ${names[_fromCurrency] ?? _fromCurrency}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          const Icon(Icons.arrow_downward,
                              color: Colors.white60, size: 22),
                          const SizedBox(height: 6),
                          Text(
                            '${symbols[_toCurrency] ?? _toCurrency}${_result!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            names[_toCurrency] ?? _toCurrency,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // ── Live rates grid ────────────────────────────────────────
                  if (_rates != null) ...[
                    Text(
                      'Live Rates (1 USD base)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.0,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _currencies.length,
                      itemBuilder: (_, i) {
                        final code = _currencies[i];
                        final rate = _rates![code] ?? 1.0;
                        final sym = symbols[code] ?? code;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ??
                                (isDark ? AppTheme.darkCard : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(sym,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(code,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text(
                                      rate.toStringAsFixed(rate >= 100 ? 0 : 2),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ── Reusable currency dropdown ─────────────────────────────────────────────────
class _CurrencyDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> currencies;
  final Map<String, String> symbols;
  final Map<String, String> names;
  final ValueChanged<String?> onChanged;

  const _CurrencyDropdown({
    required this.label,
    required this.value,
    required this.currencies,
    required this.symbols,
    required this.names,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: currencies
              .map((code) => DropdownMenuItem(
                    value: code,
                    child: Text(
                      '${symbols[code] ?? ''} $code',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
