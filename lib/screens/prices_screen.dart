import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/models/price.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PricesScreen extends StatefulWidget {
  const PricesScreen({super.key});

  @override
  State<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<PricesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  // Popular cryptos to show by default
  final _popularCryptos = ['BTC', 'ETH', 'BNB', 'SOL', 'ADA', 'XRP', 'DOT', 'MATIC'];
  final _popularStocks = ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA', 'META'];

  final Map<String, CryptoPrice> _cryptoPrices = {};
  final Map<String, StockPrice> _stockPrices = {};
  bool _isLoadingCrypto = true;
  bool _isLoadingStocks = true;
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCryptoPrices();
    _loadStockPrices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCryptoPrices() async {
    setState(() => _isLoadingCrypto = true);
    final authService = context.read<AuthService>();
    final apiService = ApiService(authService);

    for (final symbol in _popularCryptos) {
      try {
        final price = await apiService.getCryptoPrice(symbol);
        if (mounted) {
          setState(() => _cryptoPrices[symbol] = price);
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _isLoadingCrypto = false);
  }

  Future<void> _loadStockPrices() async {
    setState(() => _isLoadingStocks = true);
    final authService = context.read<AuthService>();
    final apiService = ApiService(authService);

    for (final symbol in _popularStocks) {
      try {
        final price = await apiService.getStockPrice(symbol);
        if (mounted) {
          setState(() => _stockPrices[symbol] = price);
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _isLoadingStocks = false);
  }

  Future<void> _searchPrice(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final authService = context.read<AuthService>();
    final apiService = ApiService(authService);
    final symbol = query.trim().toUpperCase();

    try {
      if (_tabController.index == 0) {
        final price = await apiService.getCryptoPrice(symbol);
        setState(() {
          _cryptoPrices[symbol] = price;
          _isSearching = false;
        });
      } else {
        final price = await apiService.getStockPrice(symbol);
        setState(() {
          _stockPrices[symbol] = price;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchError = 'Could not find "$symbol"';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Live Prices'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Crypto', icon: Icon(Icons.currency_bitcoin)),
            Tab(text: 'Stocks', icon: Icon(Icons.show_chart)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search symbol (e.g. BTC, AAPL)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _searchPrice(_searchController.text),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
              ),
              onSubmitted: _searchPrice,
            ),
          ),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_searchError!, style: TextStyle(color: Colors.red[700])),
            ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Crypto tab
                _isLoadingCrypto && _cryptoPrices.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
                    : RefreshIndicator(
                        onRefresh: _loadCryptoPrices,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cryptoPrices.length,
                          itemBuilder: (context, index) {
                            final entry = _cryptoPrices.entries.elementAt(index);
                            final price = entry.value;
                            final isPositive = price.change24h >= 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.deepGreen.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text('₿', style: TextStyle(fontSize: 22)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          price.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          price.symbol.toUpperCase(),
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormat.format(price.price),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPositive
                                                ? Icons.arrow_drop_up
                                                : Icons.arrow_drop_down,
                                            color: isPositive ? Colors.green : Colors.red,
                                            size: 20,
                                          ),
                                          Text(
                                            '${price.change24h.toStringAsFixed(2)}%',
                                            style: TextStyle(
                                              color: isPositive ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                // Stocks tab
                _isLoadingStocks && _stockPrices.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
                    : RefreshIndicator(
                        onRefresh: _loadStockPrices,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _stockPrices.length,
                          itemBuilder: (context, index) {
                            final entry = _stockPrices.entries.elementAt(index);
                            final price = entry.value;
                            final isPositive = price.changePercent >= 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.deepGreen.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text('📈', style: TextStyle(fontSize: 22)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Open: ${currencyFormat.format(price.openPrice)}',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormat.format(price.currentPrice),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPositive
                                                ? Icons.arrow_drop_up
                                                : Icons.arrow_drop_down,
                                            color: isPositive ? Colors.green : Colors.red,
                                            size: 20,
                                          ),
                                          Text(
                                            '${price.changePercent.toStringAsFixed(2)}%',
                                            style: TextStyle(
                                              color: isPositive ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
