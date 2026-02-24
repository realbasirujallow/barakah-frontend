import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  List<Map<String, dynamic>> _accounts = [];
  Map<String, dynamic> _summary = {};
  bool _loading = true;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  ApiService get _api => ApiService(Provider.of<AuthService>(context, listen: false));

  Future<void> _loadData() async {
    try {
      final api = _api;
      final results = await Future.wait([
        api.getInvestmentAccounts(),
        api.getPortfolioSummary(),
      ]);
      setState(() {
        _accounts = List<Map<String, dynamic>>.from(results[0]['accounts'] ?? []);
        _summary = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  IconData _accountTypeIcon(String type) {
    switch (type) {
      case 'brokerage': return Icons.trending_up;
      case 'retirement_401k': return Icons.account_balance;
      case 'ira': return Icons.savings;
      case 'roth_ira': return Icons.savings;
      case 'hsa': return Icons.health_and_safety;
      case 'education_529': return Icons.school;
      case 'crypto': return Icons.currency_bitcoin;
      case 'mutual_fund': return Icons.pie_chart;
      default: return Icons.account_balance_wallet;
    }
  }

  String _accountTypeLabel(String type) {
    switch (type) {
      case 'brokerage': return 'Brokerage';
      case 'retirement_401k': return '401(k)';
      case 'ira': return 'IRA';
      case 'roth_ira': return 'Roth IRA';
      case 'hsa': return 'HSA';
      case 'education_529': return '529 Plan';
      case 'crypto': return 'Crypto';
      case 'mutual_fund': return 'Mutual Fund';
      default: return 'Other';
    }
  }

  void _showAddAccountSheet() {
    final nameCtrl = TextEditingController();
    final institutionCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final contributedCtrl = TextEditingController();
    String accountType = 'brokerage';
    bool isHalal = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Add Investment Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g. My Brokerage',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: accountType,
                  decoration: InputDecoration(
                    labelText: 'Account Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'brokerage', child: Text('Brokerage')),
                    DropdownMenuItem(value: 'retirement_401k', child: Text('401(k)')),
                    DropdownMenuItem(value: 'ira', child: Text('IRA')),
                    DropdownMenuItem(value: 'roth_ira', child: Text('Roth IRA')),
                    DropdownMenuItem(value: 'hsa', child: Text('HSA')),
                    DropdownMenuItem(value: 'education_529', child: Text('529 Plan')),
                    DropdownMenuItem(value: 'crypto', child: Text('Crypto')),
                    DropdownMenuItem(value: 'mutual_fund', child: Text('Mutual Fund')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setSheetState(() => accountType = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: institutionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Institution (optional)',
                    hintText: 'e.g. Fidelity, Vanguard',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: valueCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Current Value',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: contributedCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Total Contributed',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Halal Compliant'),
                  subtitle: const Text('Is this account shariah-compliant?'),
                  value: isHalal,
                  activeThumbColor: AppTheme.deepGreen,
                  onChanged: (v) => setSheetState(() => isHalal = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        await _api.addInvestmentAccount({
                          'name': nameCtrl.text.trim(),
                          'accountType': accountType,
                          'institution': institutionCtrl.text.trim(),
                          'totalValue': double.tryParse(valueCtrl.text) ?? 0,
                          'totalContributed': double.tryParse(contributedCtrl.text) ?? 0,
                          'isHalal': isHalal,
                        });
                        _loadData();
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalValue = (_summary['totalValue'] ?? 0).toDouble();
    final totalGainLoss = (_summary['totalGainLoss'] ?? 0).toDouble();
    final overallReturn = (_summary['overallReturnPercent'] ?? 0).toDouble();
    final halalPercent = (_summary['halalPercent'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Investments')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountSheet,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Portfolio summary card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.deepGreen, Color(0xFF2E7D32)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Portfolio', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          _currencyFormat.format(totalValue),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _summaryPill(
                              totalGainLoss >= 0 ? '+${_currencyFormat.format(totalGainLoss)}' : _currencyFormat.format(totalGainLoss),
                              totalGainLoss >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                            ),
                            const SizedBox(width: 8),
                            _summaryPill(
                              '${overallReturn >= 0 ? "+" : ""}${overallReturn.toStringAsFixed(2)}%',
                              overallReturn >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                            ),
                            const SizedBox(width: 8),
                            _summaryPill(
                              '${halalPercent.toStringAsFixed(0)}% Halal',
                              AppTheme.gold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_accounts.length} accounts · ${_summary['holdingCount'] ?? 0} holdings',
                              style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sector allocation (if any)
                  if (_summary['sectorAllocation'] != null && (_summary['sectorAllocation'] as List).isNotEmpty) ...[
                    Text('Sector Allocation', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...List<Map<String, dynamic>>.from(_summary['sectorAllocation']).take(5).map((s) {
                      final weight = (s['weight'] ?? 0).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(s['sector'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text('${weight.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (weight / 100).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.grey.withAlpha(40),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.deepGreen),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // Accounts list
                  Text('Accounts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_accounts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.trending_up, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('No investment accounts yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Tap + to add your first account', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._accounts.map((a) {
                      final value = (a['totalValue'] ?? 0).toDouble();
                      final gainLoss = (a['totalGainLoss'] ?? 0).toDouble();
                      final returnPct = (a['returnPercentage'] ?? 0).toDouble();
                      final isHalal = a['isHalal'] == true;
                      final type = a['accountType'] ?? 'other';

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openAccountDetail(a),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.deepGreen.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_accountTypeIcon(type), color: AppTheme.deepGreen, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(a['name'] ?? '', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                          ),
                                          if (isHalal)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.deepGreen.withAlpha(20),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text('HALAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(_accountTypeLabel(type), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                          if (a['institution'] != null && (a['institution'] as String).isNotEmpty) ...[
                                            Text(' · ${a['institution']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(_currencyFormat.format(value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${gainLoss >= 0 ? "+" : ""}${_currencyFormat.format(gainLoss)} (${returnPct >= 0 ? "+" : ""}${returnPct.toStringAsFixed(1)}%)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: gainLoss >= 0 ? Colors.green : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _summaryPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  void _openAccountDetail(Map<String, dynamic> account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AccountDetailScreen(
          accountId: account['id'] as int,
          accountName: account['name'] as String,
          onChanged: _loadData,
        ),
      ),
    );
  }
}

// ─── Account Detail Screen ─────────────────────────────

class _AccountDetailScreen extends StatefulWidget {
  final int accountId;
  final String accountName;
  final VoidCallback onChanged;

  const _AccountDetailScreen({
    required this.accountId,
    required this.accountName,
    required this.onChanged,
  });

  @override
  State<_AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<_AccountDetailScreen> {
  Map<String, dynamic> _account = {};
  List<Map<String, dynamic>> _holdings = [];
  bool _loading = true;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  ApiService get _api => ApiService(Provider.of<AuthService>(context, listen: false));

  Future<void> _loadAccount() async {
    try {
      final data = await _api.getInvestmentAccount(widget.accountId);
      setState(() {
        _account = data;
        _holdings = List<Map<String, dynamic>>.from(data['holdings'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddHoldingSheet() {
    final symbolCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final sharesCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final sectorCtrl = TextEditingController();
    String holdingType = 'stock';
    bool isHalal = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Add Holding', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: symbolCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Symbol',
                          hintText: 'AAPL',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Apple Inc.',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: holdingType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'stock', child: Text('Stock')),
                    DropdownMenuItem(value: 'etf', child: Text('ETF')),
                    DropdownMenuItem(value: 'mutual_fund', child: Text('Mutual Fund')),
                    DropdownMenuItem(value: 'bond', child: Text('Bond')),
                    DropdownMenuItem(value: 'crypto', child: Text('Crypto')),
                    DropdownMenuItem(value: 'reit', child: Text('REIT')),
                    DropdownMenuItem(value: 'sukuk', child: Text('Sukuk')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setSheetState(() => holdingType = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sharesCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Shares',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Avg Cost',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Current Price',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: sectorCtrl,
                        decoration: InputDecoration(
                          labelText: 'Sector',
                          hintText: 'Technology',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Halal Compliant'),
                  value: isHalal,
                  activeThumbColor: AppTheme.deepGreen,
                  onChanged: (v) => setSheetState(() => isHalal = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (symbolCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        await _api.addInvestmentHolding(widget.accountId, {
                          'symbol': symbolCtrl.text.trim(),
                          'name': nameCtrl.text.trim(),
                          'holdingType': holdingType,
                          'shares': double.tryParse(sharesCtrl.text) ?? 0,
                          'avgCostPerShare': double.tryParse(costCtrl.text) ?? 0,
                          'currentPrice': double.tryParse(priceCtrl.text) ?? 0,
                          'isHalal': isHalal,
                          'sector': sectorCtrl.text.trim(),
                        });
                        _loadAccount();
                        widget.onChanged();
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Holding', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdatePriceDialog(Map<String, dynamic> holding) {
    final priceCtrl = TextEditingController(text: (holding['currentPrice'] ?? 0).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update ${holding['symbol']}'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Current Price',
            prefixText: '\$ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text);
              if (price == null) return;
              Navigator.pop(ctx);
              try {
                await _api.updateHoldingPrice(holding['id'] as int, price);
                _loadAccount();
                widget.onChanged();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = (_account['totalValue'] ?? 0).toDouble();
    final gainLoss = (_account['totalGainLoss'] ?? 0).toDouble();
    final returnPct = (_account['returnPercentage'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text('This will delete the account and all its holdings.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await _api.deleteInvestmentAccount(widget.accountId);
                    widget.onChanged();
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete Account', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHoldingSheet,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAccount,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Account summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.deepGreen, Color(0xFF2E7D32)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statCol('Value', _currencyFormat.format(value), Colors.white),
                            Container(height: 40, width: 1, color: Colors.white.withAlpha(60)),
                            _statCol('Gain/Loss', '${gainLoss >= 0 ? "+" : ""}${_currencyFormat.format(gainLoss)}',
                                gainLoss >= 0 ? Colors.green.shade300 : Colors.red.shade300),
                            Container(height: 40, width: 1, color: Colors.white.withAlpha(60)),
                            _statCol('Return', '${returnPct >= 0 ? "+" : ""}${returnPct.toStringAsFixed(2)}%',
                                returnPct >= 0 ? AppTheme.gold : Colors.red.shade300),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('${_holdings.length} Holdings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_holdings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('No holdings yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Tap + to add stocks, ETFs, or crypto', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._holdings.map((h) {
                      final gl = (h['gainLoss'] ?? 0).toDouble();
                      final glPct = (h['gainLossPercent'] ?? 0).toDouble();
                      final mv = (h['marketValue'] ?? 0).toDouble();
                      final weight = (h['weight'] ?? 0).toDouble();
                      final shares = (h['shares'] ?? 0).toDouble();
                      final isHalal = h['isHalal'] == true;

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showUpdatePriceDialog(h),
                          onLongPress: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Delete ${h['symbol']}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await _api.deleteInvestmentHolding(h['id'] as int);
                                _loadAccount();
                                widget.onChanged();
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Symbol badge
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: gl >= 0 ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      h['symbol'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: (h['symbol']?.toString().length ?? 0) > 3 ? 10 : 12,
                                        color: gl >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(h['name'] ?? h['symbol'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isHalal)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Icon(Icons.verified, color: AppTheme.deepGreen, size: 16),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${shares.toStringAsFixed(shares == shares.roundToDouble() ? 0 : 2)} shares · ${weight.toStringAsFixed(1)}%',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(_currencyFormat.format(mv), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      '${gl >= 0 ? "+" : ""}${_currencyFormat.format(gl)} (${glPct >= 0 ? "+" : ""}${glPct.toStringAsFixed(1)}%)',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: gl >= 0 ? Colors.green : Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
