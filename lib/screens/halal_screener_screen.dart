import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';

class HalalScreenerScreen extends StatefulWidget {
  const HalalScreenerScreen({super.key});

  @override
  State<HalalScreenerScreen> createState() => _HalalScreenerScreenState();
}

class _HalalScreenerScreenState extends State<HalalScreenerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _halalStocks = [];
  Map<String, dynamic>? _searchResult;
  bool _isLoadingList = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHalalList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  ApiService get _api {
    final auth = context.read<AuthService>();
    return ApiService(auth);
  }

  Future<void> _loadHalalList() async {
    setState(() => _isLoadingList = true);
    try {
      final data = await _api.getHalalStocks();
      setState(() {
        _halalStocks = List<Map<String, dynamic>>.from(data['stocks'] ?? []);
        _isLoadingList = false;
      });
    } catch (e) {
      setState(() => _isLoadingList = false);
    }
  }

  Future<void> _checkStock(String symbol) async {
    if (symbol.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final result = await _api.checkHalalStock(symbol.trim().toUpperCase());
      setState(() {
        _searchResult = result;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResult = {'symbol': symbol.toUpperCase(), 'found': false};
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halal Screener'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Check Stock'),
            Tab(icon: Icon(Icons.check_circle), text: 'Halal List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildListTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.deepGreen, Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            children: [
              Text('☪', style: TextStyle(fontSize: 40)),
              SizedBox(height: 8),
              Text('Shariah Compliance Check',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Verify if a stock is halal to invest in',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Search bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter stock symbol (e.g., AAPL)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                ),
                onSubmitted: _checkStock,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => _checkStock(_searchController.text),
                child: _isSearching
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Result
        if (_searchResult != null) _buildResultCard(_searchResult!),

        // Popular checks
        const SizedBox(height: 24),
        const Text('Quick Check', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepGreen,
        )),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['AAPL', 'MSFT', 'TSLA', 'JPM', 'GOOGL', 'NVDA', 'HLAL', 'BUD']
              .map((s) => ActionChip(
                    label: Text(s),
                    onPressed: () {
                      _searchController.text = s;
                      _checkStock(s);
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final found = result['found'] == true;
    if (!found) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange.shade700, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result['symbol'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Text('Not in our database yet. Check with your Shariah advisor.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isHalal = result['isHalal'] == true;
    final color = isHalal ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHalal ? Icons.check_circle : Icons.cancel,
                  color: color.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result['symbol'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(result['name'] ?? '',
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isHalal ? 'HALAL' : 'HARAM',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: color.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result['reason'] ?? '',
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          ),
          if (result['sector'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Sector: ${result['sector']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListTab() {
    final theme = Theme.of(context);
    if (_isLoadingList) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen));
    }

    // Group by sector
    final Map<String, List<Map<String, dynamic>>> bySector = {};
    for (var s in _halalStocks) {
      final sector = s['sector'] as String? ?? 'Other';
      bySector.putIfAbsent(sector, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.deepGreen.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified, color: AppTheme.deepGreen),
              const SizedBox(width: 12),
              Text(
                '${_halalStocks.length} Halal-Compliant Stocks & ETFs',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepGreen),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...bySector.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepGreen,
                    ),
                  ),
                ),
                ...entry.value.map((stock) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.deepGreen.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              stock['symbol'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.deepGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stock['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(stock['reason'] ?? '',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: AppTheme.deepGreen),
                        ],
                      ),
                    )),
              ],
            )),
      ],
    );
  }
}
