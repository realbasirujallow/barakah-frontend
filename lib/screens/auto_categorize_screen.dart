import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';

class AutoCategorizeScreen extends StatefulWidget {
  const AutoCategorizeScreen({super.key});

  @override
  State<AutoCategorizeScreen> createState() => _AutoCategorizeScreenState();
}

class _AutoCategorizeScreenState extends State<AutoCategorizeScreen> {
  Map<String, dynamic>? _review;
  bool _isLoading = true;
  bool _isApplying = false;
  int _appliedCount = 0;

  final _categoryIcons = <String, IconData>{
    'food': Icons.restaurant,
    'transportation': Icons.directions_car,
    'shopping': Icons.shopping_bag,
    'utilities': Icons.lightbulb,
    'housing': Icons.home,
    'healthcare': Icons.local_hospital,
    'education': Icons.school,
    'entertainment': Icons.movie,
    'subscription': Icons.subscriptions,
    'charity': Icons.volunteer_activism,
    'income': Icons.attach_money,
    'investment': Icons.trending_up,
    'transfer': Icons.swap_horiz,
    'interest': Icons.warning_amber,
    'other': Icons.category,
  };

  final _categoryColors = <String, Color>{
    'food': Colors.orange,
    'transportation': Colors.blue,
    'shopping': Colors.purple,
    'utilities': Colors.amber,
    'housing': Colors.brown,
    'healthcare': Colors.red,
    'education': Colors.indigo,
    'entertainment': Colors.pink,
    'subscription': Colors.teal,
    'charity': Colors.green,
    'income': Colors.green.shade800,
    'investment': Colors.blue.shade800,
    'transfer': Colors.cyan,
    'interest': Colors.red.shade800,
    'other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService(context.read<AuthService>());
      final data = await api.reviewCategories();
      setState(() {
        _review = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyCategories() async {
    setState(() => _isApplying = true);
    try {
      final api = ApiService(context.read<AuthService>());
      final result = await api.applyAutoCategories();
      setState(() {
        _appliedCount = result['updatedCount'] as int? ?? 0;
        _isApplying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'Done'),
            backgroundColor: AppTheme.deepGreen,
          ),
        );
      }
      _loadReview(); // Refresh
    } catch (e) {
      setState(() => _isApplying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Auto Categorize'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReview,
            tooltip: 'Re-scan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : _review == null
              ? const Center(child: Text('Failed to review'))
              : RefreshIndicator(
                  onRefresh: _loadReview,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary card
                      _buildSummaryCard(),
                      const SizedBox(height: 16),

                      // Category breakdown
                      _buildCategoryBreakdown(),
                      const SizedBox(height: 16),

                      // Apply button
                      if ((_review!['autoCategorizableCount'] as int? ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ElevatedButton.icon(
                            onPressed: _isApplying ? null : _applyCategories,
                            icon: _isApplying
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.auto_fix_high),
                            label: Text(_isApplying
                                ? 'Applying...'
                                : 'Auto-Categorize ${_review!['autoCategorizableCount']} Transactions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.deepGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                      // Transaction suggestions
                      const Text('Transaction Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._buildTransactionList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _review!['totalTransactions'] as int? ?? 0;
    final canChange = _review!['autoCategorizableCount'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade700, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_fix_high, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          const Text('Smart Categorization', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('$total transactions scanned',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(canChange > 0
              ? '$canChange can be auto-categorized'
              : 'All transactions are properly categorized!',
              style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
          if (_appliedCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('✓ $_appliedCount updated this session',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final summary = _review!['categorySummary'] as Map<String, dynamic>? ?? {};
    if (summary.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: summary.entries.map((e) {
            final color = _categoryColors[e.key] ?? Colors.grey;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_categoryIcons[e.key] ?? Icons.category, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text('${e.key} (${e.value})',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildTransactionList() {
    final theme = Theme.of(context);
    final transactions = _review!['transactions'] as List<dynamic>? ?? [];
    if (transactions.isEmpty) {
      return [
        Center(
          child: Column(children: [
            const SizedBox(height: 40),
            Icon(Icons.inbox, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No transactions to review', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ];
    }

    // Show transactions that would change first
    final sorted = List<Map<String, dynamic>>.from(
        transactions.map((t) => t as Map<String, dynamic>));
    sorted.sort((a, b) {
      final aChange = a['wouldChange'] == true ? 0 : 1;
      final bChange = b['wouldChange'] == true ? 0 : 1;
      return aChange.compareTo(bChange);
    });

    return sorted.take(50).map((tx) {
      final suggested = tx['suggestedCategory'] as String? ?? 'other';
      final current = tx['currentCategory'] as String? ?? 'other';
      final wouldChange = tx['wouldChange'] as bool? ?? false;
      final confidence = tx['confidence'] as int? ?? 0;
      final color = _categoryColors[suggested] ?? Colors.grey;

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: wouldChange ? Colors.blue.shade50 : theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: wouldChange ? Border.all(color: Colors.blue.shade200) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withAlpha(30),
              child: Icon(_categoryIcons[suggested] ?? Icons.category, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx['description'] as String? ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (wouldChange)
                    Row(children: [
                      Text(current, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, decoration: TextDecoration.lineThrough)),
                      const Icon(Icons.arrow_forward, size: 12, color: Colors.blue),
                      Text(suggested, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                    ])
                  else
                    Text(suggested, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (wouldChange)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$confidence%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
              ),
          ],
        ),
      );
    }).toList();
  }
}
