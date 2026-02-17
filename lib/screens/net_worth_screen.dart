import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  bool _isLoading = true;
  String? _error;
  String _period = '6m';

  double _currentNetWorth = 0;
  double _totalAssets = 0;
  double _totalDebts = 0;
  double _totalSavings = 0;
  double _changeAmount = 0;
  double _changePercent = 0;
  List<_NetWorthPoint> _dataPoints = [];

  final _periods = const ['30d', '90d', '6m', '1y', 'all'];
  final _periodLabels = const {
    '30d': '30 Days',
    '90d': '90 Days',
    '6m': '6 Months',
    '1y': '1 Year',
    'all': 'All Time',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);

      // Record a snapshot first, then fetch history
      await apiService.recordNetWorthSnapshot();
      final data = await apiService.getNetWorthHistory(period: _period);

      final history = (data['history'] as List<dynamic>?) ?? [];
      final points = history.map((h) {
        final map = h as Map<String, dynamic>;
        return _NetWorthPoint(
          date: DateTime.fromMillisecondsSinceEpoch((map['date'] as num).toInt()),
          netWorth: (map['netWorth'] as num).toDouble(),
          assets: (map['totalAssets'] as num).toDouble(),
          debts: (map['totalDebts'] as num).toDouble(),
          savings: (map['totalSavings'] as num).toDouble(),
        );
      }).toList();

      setState(() {
        _currentNetWorth = (data['currentNetWorth'] as num?)?.toDouble() ?? 0;
        _totalAssets = (data['totalAssets'] as num?)?.toDouble() ?? 0;
        _totalDebts = (data['totalDebts'] as num?)?.toDouble() ?? 0;
        _totalSavings = (data['totalSavings'] as num?)?.toDouble() ?? 0;
        _changeAmount = (data['changeAmount'] as num?)?.toDouble() ?? 0;
        _changePercent = (data['changePercent'] as num?)?.toDouble() ?? 0;
        _dataPoints = points;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load net worth data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildNetWorthCard(theme, fmt),
                      const SizedBox(height: 16),
                      _buildPeriodSelector(theme),
                      const SizedBox(height: 16),
                      _buildChart(theme, fmt),
                      const SizedBox(height: 16),
                      _buildBreakdownCard(theme, fmt),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNetWorthCard(ThemeData theme, NumberFormat fmt) {
    final isPositive = _changeAmount >= 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.deepGreen, AppTheme.deepGreen.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepGreen.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Net Worth',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            fmt.format(_currentNetWorth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${fmt.format(_changeAmount)} (${_changePercent.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _periodLabels[_period] ?? _period,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((p) {
          final selected = p == _period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_periodLabels[p] ?? p),
              selected: selected,
              onSelected: (val) {
                if (val && p != _period) {
                  setState(() => _period = p);
                  _loadData();
                }
              },
              selectedColor: AppTheme.deepGreen,
              labelStyle: TextStyle(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(ThemeData theme, NumberFormat fmt) {
    if (_dataPoints.length < 2) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                _dataPoints.isEmpty
                    ? 'No history yet — check back tomorrow!'
                    : 'Need at least 2 data points for a graph',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'A snapshot is recorded each time you open this page',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < _dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), _dataPoints[i].netWorth));
    }

    final allValues = _dataPoints.map((p) => p.netWorth).toList();
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range == 0 ? 100.0 : range * 0.15;

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.deepGreen,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: _dataPoints.length <= 30,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppTheme.deepGreen,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.deepGreen.withAlpha(60),
                    AppTheme.deepGreen.withAlpha(10),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minY: minY - padding,
          maxY: maxY + padding,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _shortMoney(value),
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _dataPoints.length > 6 ? (_dataPoints.length / 5).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _dataPoints.length) return const SizedBox.shrink();
                  final date = _dataPoints[idx].date;
                  final label = _period == '30d'
                      ? DateFormat('d').format(date)
                      : DateFormat('MMM d').format(date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(label,
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range == 0 ? 50 : range / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final date = idx < _dataPoints.length
                      ? DateFormat('MMM d, yyyy').format(_dataPoints[idx].date)
                      : '';
                  return LineTooltipItem(
                    '$date\n${fmt.format(spot.y)}',
                    TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(ThemeData theme, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildBreakdownRow(theme, 'Assets', _totalAssets, fmt, Colors.green),
          const SizedBox(height: 12),
          _buildBreakdownRow(theme, 'Savings Goals', _totalSavings, fmt, Colors.blue),
          const SizedBox(height: 12),
          _buildBreakdownRow(theme, 'Debts', _totalDebts, fmt, Colors.red),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net Worth',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(fmt.format(_currentNetWorth),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _currentNetWorth >= 0 ? Colors.green : Colors.red,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          // Stacked bar showing composition
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: _buildCompositionBar(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(ThemeData theme, String label, double value, NumberFormat fmt, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
        Text(fmt.format(value), style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCompositionBar(ThemeData theme) {
    final total = _totalAssets + _totalSavings + _totalDebts;
    if (total == 0) {
      return Container(
        height: 8,
        color: theme.colorScheme.surfaceContainerHighest,
      );
    }
    return SizedBox(
      height: 8,
      child: Row(
        children: [
          if (_totalAssets > 0)
            Expanded(flex: (_totalAssets / total * 100).round(), child: Container(color: Colors.green)),
          if (_totalSavings > 0)
            Expanded(flex: (_totalSavings / total * 100).round(), child: Container(color: Colors.blue)),
          if (_totalDebts > 0)
            Expanded(flex: (_totalDebts / total * 100).round(), child: Container(color: Colors.red)),
        ],
      ),
    );
  }

  String _shortMoney(double value) {
    if (value.abs() >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(0)}';
  }
}

class _NetWorthPoint {
  final DateTime date;
  final double netWorth;
  final double assets;
  final double debts;
  final double savings;

  _NetWorthPoint({
    required this.date,
    required this.netWorth,
    required this.assets,
    required this.debts,
    required this.savings,
  });
}
