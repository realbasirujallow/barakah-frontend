import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class RibaDetectorScreen extends StatefulWidget {
  const RibaDetectorScreen({super.key});

  @override
  State<RibaDetectorScreen> createState() => _RibaDetectorScreenState();
}

class _RibaDetectorScreenState extends State<RibaDetectorScreen> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;
  bool _showAlternatives = false;

  @override
  void initState() {
    super.initState();
    _scanTransactions();
  }

  Future<void> _scanTransactions() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService(context.read<AuthService>());
      final data = await api.scanForRiba();
      setState(() {
        _report = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'HIGH': return Colors.red;
      case 'MEDIUM': return Colors.orange;
      default: return Colors.green;
    }
  }

  IconData _riskIcon(String level) {
    switch (level) {
      case 'HIGH': return Icons.dangerous;
      case 'MEDIUM': return Icons.warning_amber;
      default: return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Riba Detector'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scanTransactions,
            tooltip: 'Re-scan',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.deepGreen),
                const SizedBox(height: 16),
                Text('Scanning transactions for riba...', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ))
          : _report == null
              ? Center(child: Text('Failed to scan', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
              : RefreshIndicator(
                  onRefresh: _scanTransactions,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Status card
                      _buildStatusCard(fmt),
                      const SizedBox(height: 16),

                      // Quranic reminder
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.menu_book, color: Colors.amber.shade800, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '"Those who consume riba cannot stand [on the Day of Resurrection] except as one stands who is being beaten by Satan into insanity." — Quran 2:275',
                                style: TextStyle(fontSize: 13, color: Colors.amber.shade900, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Flagged transactions
                      if (_report!['ribaCount'] > 0) ...[
                        Text('Flagged Transactions (${_report!['ribaCount']})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...(_buildFlaggedList(fmt)),
                        const SizedBox(height: 20),
                      ],

                      // Islamic alternatives
                      GestureDetector(
                        onTap: () => setState(() => _showAlternatives = !_showAlternatives),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.deepGreen.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.deepGreen.withAlpha(40)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb, color: AppTheme.deepGreen),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text('Islamic Alternatives to Riba',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepGreen, fontSize: 15)),
                              ),
                              Icon(_showAlternatives ? Icons.expand_less : Icons.expand_more, color: AppTheme.deepGreen),
                            ],
                          ),
                        ),
                      ),
                      if (_showAlternatives) ..._buildAlternativesList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard(NumberFormat fmt) {
    final isClean = _report!['isClean'] as bool? ?? true;
    final ribaCount = _report!['ribaCount'] as int? ?? 0;
    final totalRiba = (_report!['totalRibaAmount'] as num?)?.toDouble() ?? 0;
    final ribaPercent = (_report!['ribaPercentage'] as num?)?.toDouble() ?? 0;
    final totalTx = _report!['totalTransactions'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isClean
              ? [Colors.green.shade600, Colors.green.shade400]
              : [Colors.red.shade600, Colors.orange.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(isClean ? Icons.verified : Icons.warning_amber, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            isClean ? 'Riba-Free! ✨' : '$ribaCount Riba Transaction${ribaCount > 1 ? 's' : ''} Found',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _report!['message'] as String? ?? '',
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCol('Scanned', '$totalTx'),
              Container(width: 1, height: 40, color: Colors.white30),
              _statCol('Flagged', '$ribaCount'),
              Container(width: 1, height: 40, color: Colors.white30),
              _statCol('Riba Amount', fmt.format(totalRiba)),
              Container(width: 1, height: 40, color: Colors.white30),
              _statCol('Riba %', '${ribaPercent.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }

  List<Widget> _buildFlaggedList(NumberFormat fmt) {
    final theme = Theme.of(context);
    final ribaList = _report!['ribaTransactions'] as List<dynamic>? ?? [];
    return ribaList.map((item) {
      final tx = item as Map<String, dynamic>;
      final riskLevel = tx['riskLevel'] as String? ?? 'LOW';
      final flags = tx['flags'] as List<dynamic>? ?? [];
      final alternatives = tx['islamicAlternatives'] as Map<String, dynamic>?;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _riskColor(riskLevel).withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_riskIcon(riskLevel), color: _riskColor(riskLevel), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tx['description'] as String? ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _riskColor(riskLevel).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(riskLevel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _riskColor(riskLevel))),
                ),
                const SizedBox(width: 8),
                Text(fmt.format(tx['amount']),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
              ],
            ),
            const SizedBox(height: 8),
            ...flags.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(Icons.flag, size: 14, color: Colors.red.shade300),
                const SizedBox(width: 6),
                Expanded(child: Text(f as String, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant))),
              ]),
            )),
            if (alternatives != null) ...[
              const Divider(height: 16),
              Text('Islamic Alternative:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
              const SizedBox(height: 4),
              if (alternatives['alternative1'] != null)
                Row(children: [
                  const Icon(Icons.check_circle, size: 14, color: AppTheme.deepGreen),
                  const SizedBox(width: 6),
                  Expanded(child: Text(alternatives['alternative1'] as String, style: const TextStyle(fontSize: 12))),
                ]),
            ],
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildAlternativesList() {
    final theme = Theme.of(context);
    final alternatives = _report!['islamicAlternatives'] as Map<String, dynamic>? ?? {};
    return alternatives.entries.map((e) {
      final alt = e.value as Map<String, dynamic>;
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
            const SizedBox(height: 6),
            if (alt['alternative1'] != null)
              _altRow(alt['alternative1'] as String),
            if (alt['alternative2'] != null)
              _altRow(alt['alternative2'] as String),
          ],
        ),
      );
    }).toList();
  }

  Widget _altRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_forward, size: 14, color: AppTheme.deepGreen),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
