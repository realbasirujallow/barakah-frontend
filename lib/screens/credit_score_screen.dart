import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';

class CreditScoreScreen extends StatefulWidget {
  const CreditScoreScreen({super.key});

  @override
  State<CreditScoreScreen> createState() => _CreditScoreScreenState();
}

class _CreditScoreScreenState extends State<CreditScoreScreen>
    with SingleTickerProviderStateMixin {
  late ApiService _apiService;
  Map<String, dynamic>? _latestScore;
  List<dynamic> _history = [];
  Map<String, dynamic>? _summary;
  List<dynamic> _factors = [];
  List<dynamic> _tips = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _apiService = ApiService(Provider.of<AuthService>(context, listen: false));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _apiService.getLatestCreditScore(),
        _apiService.getCreditScoreHistory(),
        _apiService.getCreditScoreTips(),
      ]);

      setState(() {
        _latestScore = results[0]['creditScore'];
        _history = results[1]['history'] ?? [];
        _summary = results[1]['summary'];
        _factors = results[2]['factors'] ?? [];
        _tips = results[2]['tips'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Score'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Score'),
            Tab(text: 'Factors'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddScoreSheet,
            tooltip: 'Add Score',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScoreTab(isDark),
                _buildFactorsTab(isDark),
                _buildHistoryTab(isDark),
              ],
            ),
    );
  }

  Widget _buildScoreTab(bool isDark) {
    if (_latestScore == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No credit score recorded yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Tap + to add your first score'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddScoreSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Score'),
            ),
          ],
        ),
      );
    }

    final score = _latestScore!['score'] as int;
    final range = _latestScore!['scoreRange'] ?? 'unknown';
    final source = _latestScore!['source'] ?? 'manual';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score Gauge
            _buildScoreGauge(score, range, isDark),
            const SizedBox(height: 20),
            // Source badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Source: ${_formatSource(source)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ),
            const SizedBox(height: 24),
            // Summary cards
            if (_summary != null) _buildSummaryCards(isDark),
            const SizedBox(height: 24),
            // Tips
            if (_tips.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Tips & Recommendations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
              ),
              const SizedBox(height: 12),
              ..._tips.map((tip) => _buildTipCard(tip, isDark)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreGauge(int score, String range, bool isDark) {
    final color = _scoreColor(score);
    final percentage = (score - 300) / 550;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: CustomPaint(
              painter: _ScoreGaugePainter(
                score: score,
                percentage: percentage,
                color: color,
                isDark: isDark,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'out of 850',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatRange(range),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (_summary != null && _summary!['change'] != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  (_summary!['change'] as int) >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: (_summary!['change'] as int) >= 0
                      ? Colors.green
                      : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${(_summary!['change'] as int).abs()} pts since first record',
                  style: TextStyle(
                    color: (_summary!['change'] as int) >= 0
                        ? Colors.green
                        : Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    return Row(
      children: [
        _buildStatCard('Highest', '${_summary!['highest']}',
            Icons.arrow_upward, Colors.green, isDark),
        const SizedBox(width: 12),
        _buildStatCard('Lowest', '${_summary!['lowest']}',
            Icons.arrow_downward, Colors.red, isDark),
        const SizedBox(width: 12),
        _buildStatCard('Average', '${_summary!['average']}',
            Icons.show_chart, Colors.blue, isDark),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(dynamic tip, bool isDark) {
    final priority = tip['priority'] ?? 'info';
    Color color;
    IconData icon;
    switch (priority) {
      case 'high':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.info;
        break;
      case 'low':
        color = Colors.blue;
        icon = Icons.lightbulb;
        break;
      default:
        color = Colors.teal;
        icon = Icons.star;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip['title'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(tip['description'] ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Factors Tab ─────────────────────────────────────

  Widget _buildFactorsTab(bool isDark) {
    if (_factors.isEmpty) {
      return const Center(
        child: Text('Add a score with factor details to see analysis'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Score Factors',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text('Based on your latest recorded data',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 16),
          ..._factors.map((f) => _buildFactorCard(f, isDark)),
          const SizedBox(height: 24),
          // Impact legend
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Impact Legend',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildLegendRow('Very High', 'Payment History, Derogatory Marks', Colors.red),
                _buildLegendRow('High', 'Credit Utilization', Colors.orange),
                _buildLegendRow('Medium', 'Credit Age', Colors.amber),
                _buildLegendRow('Low', 'Hard Inquiries, Credit Mix', Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String level, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(level, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(desc,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorCard(dynamic factor, bool isDark) {
    final status = factor['status'] ?? 'unknown';
    final impact = factor['impact'] ?? 'low';
    Color statusColor;
    switch (status) {
      case 'excellent':
        statusColor = Colors.green;
        break;
      case 'good':
        statusColor = Colors.lightGreen;
        break;
      case 'fair':
        statusColor = Colors.orange;
        break;
      case 'poor':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    Color impactColor;
    switch (impact) {
      case 'very_high':
        impactColor = Colors.red;
        break;
      case 'high':
        impactColor = Colors.orange;
        break;
      case 'medium':
        impactColor = Colors.amber;
        break;
      default:
        impactColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(factor['name'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(factor['value'] ?? '',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _capitalize(status),
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: impactColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatImpact(impact)} impact',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── History Tab ─────────────────────────────────────

  Widget _buildHistoryTab(bool isDark) {
    if (_history.isEmpty) {
      return const Center(child: Text('No score history yet'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mini chart
          if (_history.length > 1) ...[
            Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: _ScoreChartPainter(
                  scores: _history.reversed
                      .map<int>((h) => (h['score'] as int))
                      .toList(),
                  isDark: isDark,
                ),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text('Score History (${_history.length} records)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          ..._history.asMap().entries.map((entry) {
            final h = entry.value;
            final isLatest = entry.key == 0;
            int? delta;
            if (entry.key < _history.length - 1) {
              delta = (h['score'] as int) -
                  (_history[entry.key + 1]['score'] as int);
            }
            return _buildHistoryCard(h, isDark, isLatest, delta);
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
      dynamic h, bool isDark, bool isLatest, int? delta) {
    final score = h['score'] as int;
    final color = _scoreColor(score);
    final date = DateTime.fromMillisecondsSinceEpoch(h['recordedAt'] as int);
    final source = h['source'] ?? 'manual';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isLatest
            ? Border.all(color: color, width: 1.5)
            : Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatRange(h['scoreRange'] ?? ''),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                    if (isLatest)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Latest',
                            style: TextStyle(color: color, fontSize: 10)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.month}/${date.day}/${date.year} · ${_formatSource(source)}',
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          if (delta != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: delta >= 0
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    delta >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: delta >= 0 ? Colors.green : Colors.red,
                  ),
                  Text(
                    '${delta.abs()}',
                    style: TextStyle(
                        color: delta >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Colors.grey.shade400, size: 20),
            onPressed: () => _deleteScore(h['id'] as int),
          ),
        ],
      ),
    );
  }

  // ─── Add Score Sheet ─────────────────────────────────

  void _showAddScoreSheet() {
    final scoreCtrl = TextEditingController();
    final utilCtrl = TextEditingController();
    final payCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final accountsCtrl = TextEditingController();
    final inquiriesCtrl = TextEditingController();
    final derogatoryCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String source = 'manual';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Add Credit Score',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: scoreCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Credit Score *',
                            hintText: '300-850',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.speed),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: source,
                          decoration: const InputDecoration(
                            labelText: 'Source',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.source),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'manual', child: Text('Manual Entry')),
                            DropdownMenuItem(value: 'experian', child: Text('Experian')),
                            DropdownMenuItem(value: 'equifax', child: Text('Equifax')),
                            DropdownMenuItem(value: 'transunion', child: Text('TransUnion')),
                            DropdownMenuItem(value: 'credit_karma', child: Text('Credit Karma')),
                            DropdownMenuItem(value: 'mint', child: Text('Mint')),
                          ],
                          onChanged: (v) => setSheetState(() => source = v!),
                        ),
                        const SizedBox(height: 20),
                        Text('Score Factors (Optional)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 4),
                        Text('Add these for personalized tips',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: utilCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Utilization %',
                                  hintText: '0-100',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: payCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'On-Time Pay %',
                                  hintText: '0-100',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: ageCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Credit Age (months)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: accountsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Total Accounts',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: inquiriesCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Hard Inquiries',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: derogatoryCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Derogatory Marks',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _submitScore(
                              ctx,
                              scoreCtrl.text,
                              source,
                              utilCtrl.text,
                              payCtrl.text,
                              ageCtrl.text,
                              accountsCtrl.text,
                              inquiriesCtrl.text,
                              derogatoryCtrl.text,
                              notesCtrl.text,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Save Score',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitScore(
    BuildContext ctx,
    String scoreText,
    String source,
    String util,
    String pay,
    String age,
    String accounts,
    String inquiries,
    String derogatory,
    String notes,
  ) async {
    final score = int.tryParse(scoreText);
    if (score == null || score < 300 || score > 850) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid score (300-850)')),
      );
      return;
    }

    final data = <String, dynamic>{
      'score': score,
      'source': source,
    };
    if (util.isNotEmpty) data['creditUtilization'] = int.parse(util);
    if (pay.isNotEmpty) data['onTimePayments'] = int.parse(pay);
    if (age.isNotEmpty) data['accountAge'] = int.parse(age);
    if (accounts.isNotEmpty) data['totalAccounts'] = int.parse(accounts);
    if (inquiries.isNotEmpty) data['hardInquiries'] = int.parse(inquiries);
    if (derogatory.isNotEmpty) data['derogatory'] = int.parse(derogatory);
    if (notes.isNotEmpty) data['notes'] = notes;

    try {
      await _apiService.addCreditScore(data);
      if (mounted) Navigator.pop(ctx);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credit score saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteScore(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Score Record?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteCreditScore(id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────

  Color _scoreColor(int score) {
    if (score >= 800) return Colors.green.shade700;
    if (score >= 740) return Colors.green;
    if (score >= 670) return Colors.lightGreen;
    if (score >= 580) return Colors.orange;
    return Colors.red;
  }

  String _formatRange(String range) {
    switch (range) {
      case 'excellent': return 'Excellent';
      case 'very_good': return 'Very Good';
      case 'good': return 'Good';
      case 'fair': return 'Fair';
      case 'poor': return 'Poor';
      default: return range;
    }
  }

  String _formatSource(String source) {
    switch (source) {
      case 'manual': return 'Manual';
      case 'experian': return 'Experian';
      case 'equifax': return 'Equifax';
      case 'transunion': return 'TransUnion';
      case 'credit_karma': return 'Credit Karma';
      case 'mint': return 'Mint';
      default: return source;
    }
  }

  String _formatImpact(String impact) {
    switch (impact) {
      case 'very_high': return 'Very high';
      case 'high': return 'High';
      case 'medium': return 'Medium';
      case 'low': return 'Low';
      default: return impact;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ─── Score Gauge Painter ───────────────────────────────

class _ScoreGaugePainter extends CustomPainter {
  final int score;
  final double percentage;
  final Color color;
  final bool isDark;

  _ScoreGaugePainter({
    required this.score,
    required this.percentage,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const startAngle = 2.3; // ~132 degrees
    const sweepAngle = 4.58; // ~262 degrees (arc)

    // Background arc
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = isDark ? Colors.white12 : Colors.grey.shade200;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Foreground arc
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [Colors.red, Colors.orange, Colors.yellow, Colors.lightGreen, Colors.green],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * percentage,
      false,
      fgPaint,
    );

    // Dot at end
    final dotAngle = startAngle + sweepAngle * percentage;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(dotX, dotY), 8, dotPaint);
    final dotBorder = Paint()
      ..color = isDark ? const Color(0xFF1E1E2E) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(dotX, dotY), 8, dotBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Score Chart Painter ───────────────────────────────

class _ScoreChartPainter extends CustomPainter {
  final List<int> scores;
  final bool isDark;

  _ScoreChartPainter({required this.scores, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;

    final minScore = scores.reduce(math.min) - 20;
    final maxScore = scores.reduce(math.max) + 20;
    final range = (maxScore - minScore).toDouble();

    final points = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      final x = (i / (scores.length - 1)) * size.width;
      final y = size.height - ((scores[i] - minScore) / range) * size.height;
      points.add(Offset(x, y));
    }

    // Gradient fill
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.teal.withValues(alpha: 0.3),
          Colors.teal.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.teal);
      canvas.drawCircle(
          p,
          4,
          Paint()
            ..color = isDark ? const Color(0xFF1E1E2E) : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    // Labels
    final textStyle = TextStyle(
      color: Colors.grey.shade500,
      fontSize: 10,
    );
    for (int i = 0; i < points.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: '${scores[i]}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, points[i].dy - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
