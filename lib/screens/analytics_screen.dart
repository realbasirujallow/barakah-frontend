import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/models/asset.dart';
import 'package:barakah_app/models/transaction.dart';
import 'package:barakah_app/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Asset> _assets = [];
  List<Transaction> _transactions = [];

  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ApiService get _api {
    final auth = context.read<AuthService>();
    return ApiService(auth);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getAssets(),
        _api.getTransactions(),
        _api.getTransactionSummary(period: _selectedPeriod),
      ]);
      setState(() {
        _assets = results[0] as List<Asset>;
        _transactions = results[1] as List<Transaction>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Portfolio'),
            Tab(text: 'Spending'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPortfolioTab(),
                _buildSpendingTab(),
                _buildTrendsTab(),
              ],
            ),
    );
  }

  // ─── Portfolio Tab ──────────────────────────────────
  Widget _buildPortfolioTab() {
    final theme = Theme.of(context);
    if (_assets.isEmpty) {
      return const Center(child: Text('No assets to analyze'));
    }

    // Group by type
    final Map<String, double> byType = {};
    double total = 0;
    for (var a in _assets) {
      final t = a.type;
      byType[t] = (byType[t] ?? 0) + a.value;
      total += a.value;
    }

    final colors = [
      AppTheme.deepGreen,
      AppTheme.gold,
      const Color(0xFF1565C0),
      const Color(0xFFE65100),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
      const Color(0xFFAD1457),
    ];

    final entries = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final formatter = NumberFormat.currency(symbol: '\$');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pie chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('Asset Allocation', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepGreen,
              )),
              const SizedBox(height: 4),
              Text(formatter.format(total), style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: entries.asMap().entries.map((e) {
                      final i = e.key;
                      final entry = e.value;
                      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
                      return PieChartSectionData(
                        color: colors[i % colors.length],
                        value: entry.value,
                        title: '${pct.toStringAsFixed(1)}%',
                        titleStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white,
                        ),
                        radius: 55,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Legend
              ...entries.asMap().entries.map((e) {
                final i = e.key;
                final entry = e.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      Text(formatter.format(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top holdings
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Top Holdings', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepGreen,
              )),
              const SizedBox(height: 16),
              ...(_assets.toList()..sort((a, b) => b.value.compareTo(a.value)))
                  .take(5)
                  .map((a) {
                final pct = total > 0 ? (a.value / total * 100) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(a.type, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatter.format(a.value),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${pct.toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Spending Tab ───────────────────────────────────
  Widget _buildSpendingTab() {
    final theme = Theme.of(context);
    // Group expenses by category
    final expenses = _transactions.where((t) => t.type == 'expense').toList();
    final income = _transactions.where((t) => t.type == 'income').toList();
    
    final Map<String, double> byCategory = {};
    double totalExpense = 0;
    for (var t in expenses) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      totalExpense += t.amount;
    }
    double totalIncome = 0;
    for (var t in income) {
      totalIncome += t.amount;
    }

    final catEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFFE53935),
      const Color(0xFFF57C00),
      const Color(0xFFFDD835),
      const Color(0xFF43A047),
      const Color(0xFF1E88E5),
      const Color(0xFF8E24AA),
      const Color(0xFF00ACC1),
      const Color(0xFFD81B60),
    ];

    final formatter = NumberFormat.currency(symbol: '\$');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period selector
        Row(
          children: ['week', 'month', 'year'].map((p) {
            final isSelected = p == _selectedPeriod;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p[0].toUpperCase() + p.substring(1)),
                selected: isSelected,
                selectedColor: AppTheme.deepGreen,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                ),
                onSelected: (_) {
                  setState(() => _selectedPeriod = p);
                  _loadData();
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Summary cards
        Row(
          children: [
            _summaryCard('Income', formatter.format(totalIncome), Colors.green),
            const SizedBox(width: 12),
            _summaryCard('Expenses', formatter.format(totalExpense), Colors.red),
            const SizedBox(width: 12),
            _summaryCard('Net', formatter.format(totalIncome - totalExpense),
                totalIncome >= totalExpense ? Colors.green : Colors.red),
          ],
        ),
        const SizedBox(height: 20),

        // Category pie chart
        if (catEntries.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Spending by Category', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepGreen,
                )),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 45,
                      sections: catEntries.asMap().entries.map((e) {
                        final i = e.key;
                        final entry = e.value;
                        final pct = totalExpense > 0 ? (entry.value / totalExpense * 100) : 0.0;
                        return PieChartSectionData(
                          color: colors[i % colors.length],
                          value: entry.value,
                          title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '',
                          titleStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white,
                          ),
                          radius: 50,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...catEntries.asMap().entries.map((e) {
                  final i = e.key;
                  final entry = e.value;
                  final pct = totalExpense > 0 ? (entry.value / totalExpense * 100) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(entry.key)),
                        Text('${pct.toStringAsFixed(1)}%',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(formatter.format(entry.value),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.pie_chart_outline, size: 64, color: theme.dividerColor),
                const SizedBox(height: 16),
                Text('No spending data yet',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Add transactions to see spending analytics',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Trends Tab ─────────────────────────────────────
  Widget _buildTrendsTab() {
    final theme = Theme.of(context);
    // Group transactions by day for a line chart
    final Map<String, double> incomeByDay = {};
    final Map<String, double> expenseByDay = {};

    for (var t in _transactions) {
      if (t.timestamp == null) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(t.timestamp!);
      final key = DateFormat('MM/dd').format(date);
      if (t.type == 'income') {
        incomeByDay[key] = (incomeByDay[key] ?? 0) + t.amount;
      } else {
        expenseByDay[key] = (expenseByDay[key] ?? 0) + t.amount;
      }
    }

    // Merge all dates
    final allDates = {...incomeByDay.keys, ...expenseByDay.keys}.toList()..sort();
    final last7 = allDates.length > 7 ? allDates.sublist(allDates.length - 7) : allDates;

    final formatter = NumberFormat.currency(symbol: '\$');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Income vs Expense line chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Income vs Expenses', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepGreen,
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legendDot(Colors.green, 'Income'),
                  const SizedBox(width: 16),
                  _legendDot(Colors.red, 'Expenses'),
                ],
              ),
              const SizedBox(height: 20),
              if (last7.isEmpty)
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text('No trend data available',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calcInterval(last7, incomeByDay, expenseByDay),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withAlpha(40),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, _) => Text(
                              _shortAmount(value),
                              style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= last7.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(last7[i],
                                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        _lineData(last7, incomeByDay, Colors.green),
                        _lineData(last7, expenseByDay, Colors.red),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((s) {
                            return LineTooltipItem(
                              formatter.format(s.y),
                              TextStyle(
                                color: s.bar.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category bar chart (horizontal)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Top Expense Categories', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepGreen,
              )),
              const SizedBox(height: 16),
              if (_transactions.where((t) => t.type == 'expense').isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(child: Text('No expense data',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
                )
              else
                ..._buildCategoryBars(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategoryBars() {
    final Map<String, double> byCategory = {};
    double maxVal = 0;
    for (var t in _transactions.where((t) => t.type == 'expense')) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isNotEmpty) maxVal = entries.first.value;

    final formatter = NumberFormat.currency(symbol: '\$');

    return entries.take(6).map((e) {
      final pct = maxVal > 0 ? e.value / maxVal : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(formatter.format(e.value),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation(AppTheme.deepGreen),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: color)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(value,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  LineChartBarData _lineData(List<String> dates, Map<String, double> data, Color color) {
    return LineChartBarData(
      spots: dates.asMap().entries.map((e) =>
          FlSpot(e.key.toDouble(), data[e.value] ?? 0)).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4, color: color, strokeWidth: 2, strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withAlpha(30),
      ),
    );
  }

  double _calcInterval(List<String> dates, Map<String, double> inc, Map<String, double> exp) {
    double maxVal = 0;
    for (var d in dates) {
      final v1 = inc[d] ?? 0;
      final v2 = exp[d] ?? 0;
      if (v1 > maxVal) maxVal = v1;
      if (v2 > maxVal) maxVal = v2;
    }
    if (maxVal <= 0) return 100;
    return (maxVal / 4).ceilToDouble();
  }

  String _shortAmount(double value) {
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(0)}K';
    return '\$${value.toStringAsFixed(0)}';
  }
}
