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
  final _listSearchController = TextEditingController();
  
  List<Map<String, dynamic>> _halalStocks = [];
  List<Map<String, dynamic>> _filteredStocks = [];
  List<Map<String, dynamic>> _sectors = [];
  Map<String, dynamic>? _searchResult;
  Map<String, dynamic>? _stats;
  String? _selectedSector;
  bool _isLoadingList = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHalalList();
    _loadSectors();
    _loadStats();
    _listSearchController.addListener(_filterStocks);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _listSearchController.dispose();
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
        _filteredStocks = _halalStocks;
        _isLoadingList = false;
      });
    } catch (e) {
      setState(() => _isLoadingList = false);
    }
  }

  Future<void> _loadSectors() async {
    try {
      final data = await _api.getHalalSectors();
      setState(() {
        _sectors = List<Map<String, dynamic>>.from(data['sectors'] ?? []);
      });
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final data = await _api.getHalalStats();
      setState(() => _stats = data);
    } catch (_) {}
  }

  void _filterStocks() {
    final query = _listSearchController.text.toLowerCase();
    setState(() {
      _filteredStocks = _halalStocks.where((s) {
        final matchesSearch = query.isEmpty ||
            (s['symbol'] as String? ?? '').toLowerCase().contains(query) ||
            (s['name'] as String? ?? '').toLowerCase().contains(query) ||
            (s['sector'] as String? ?? '').toLowerCase().contains(query);
        final matchesSector = _selectedSector == null ||
            (s['sector'] as String? ?? '') == _selectedSector;
        return matchesSearch && matchesSector;
      }).toList();
    });
  }

  void _selectSector(String? sector) {
    setState(() {
      _selectedSector = sector == _selectedSector ? null : sector;
    });
    _filterStocks();
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
          children: ['AAPL', 'MSFT', 'TSLA', 'JPM', 'GOOGL', 'NVDA', 'HLAL', 'BUD', 'AMZN', 'META', 'LLY', 'V']
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

    // Group filtered stocks by sector
    final Map<String, List<Map<String, dynamic>>> bySector = {};
    for (var s in _filteredStocks) {
      final sector = s['sector'] as String? ?? 'Other';
      bySector.putIfAbsent(sector, () => []).add(s);
    }

    return Column(
      children: [
        // Stats banner
        if (_stats != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.deepGreen, Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('${_stats!['totalStocks'] ?? 0}', 'Total\nStocks'),
                Container(width: 1, height: 36, color: Colors.white24),
                _statItem('${_stats!['halalCount'] ?? 0}', 'Halal\nStocks'),
                Container(width: 1, height: 36, color: Colors.white24),
                _statItem('${_stats!['totalSectors'] ?? 0}', 'Sectors\nCovered'),
              ],
            ),
          ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _listSearchController,
            decoration: InputDecoration(
              hintText: 'Search halal stocks...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.deepGreen),
              suffixIcon: _listSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _listSearchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Sector filter chips
        if (_sectors.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedSector == null,
                    selectedColor: AppTheme.deepGreen.withAlpha(40),
                    checkmarkColor: AppTheme.deepGreen,
                    onSelected: (_) => _selectSector(null),
                  ),
                ),
                ..._sectors.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text('${s['sector']} (${s['count']})'),
                        selected: _selectedSector == s['sector'],
                        selectedColor: AppTheme.deepGreen.withAlpha(40),
                        checkmarkColor: AppTheme.deepGreen,
                        onSelected: (_) => _selectSector(s['sector'] as String),
                      ),
                    )),
              ],
            ),
          ),

        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.verified, color: AppTheme.deepGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                '${_filteredStocks.length} Halal-Compliant Stocks',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepGreen, fontSize: 13),
              ),
              if (_selectedSector != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.deepGreen.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedSector!,
                          style: const TextStyle(fontSize: 11, color: AppTheme.deepGreen)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _selectSector(null),
                        child: const Icon(Icons.close, size: 14, color: AppTheme.deepGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Stock list
        Expanded(
          child: _filteredStocks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No stocks found',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _filteredStocks.length,
                  itemBuilder: (context, index) {
                    final stock = _filteredStocks[index];
                    return Container(
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
                                fontSize: 10,
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
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.deepGreen.withAlpha(15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        stock['sector'] ?? '',
                                        style: const TextStyle(fontSize: 10, color: AppTheme.deepGreen),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(stock['reason'] ?? '',
                                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: AppTheme.deepGreen, size: 20),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
