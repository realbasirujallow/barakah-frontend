import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/services/notification_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<dynamic> _budgets = [];
  double _totalLimit = 0;
  double _totalSpent = 0;
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final _categories = [
    'food', 'transport', 'housing', 'utilities', 'entertainment',
    'shopping', 'health', 'education', 'clothing', 'charity', 'other'
  ];

  final _categoryIcons = {
    'food': Icons.restaurant,
    'transport': Icons.directions_car,
    'housing': Icons.home,
    'utilities': Icons.bolt,
    'entertainment': Icons.movie,
    'shopping': Icons.shopping_bag,
    'health': Icons.local_hospital,
    'education': Icons.school,
    'clothing': Icons.checkroom,
    'charity': Icons.volunteer_activism,
    'other': Icons.category,
  };

  final _categoryColors = {
    'food': Colors.orange,
    'transport': Colors.blue,
    'housing': Colors.brown,
    'utilities': Colors.yellow.shade700,
    'entertainment': Colors.purple,
    'shopping': Colors.pink,
    'health': Colors.red,
    'education': Colors.teal,
    'clothing': Colors.indigo,
    'charity': Colors.green,
    'other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService(context.read<AuthService>());
      final data = await api.getBudgets(month: _selectedMonth, year: _selectedYear);
      setState(() {
        _budgets = data['budgets'] as List<dynamic>? ?? [];
        _totalLimit = (data['totalLimit'] as num?)?.toDouble() ?? 0;
        _totalSpent = (data['totalSpent'] as num?)?.toDouble() ?? 0;
        _isLoading = false;
      });
      // Check budget alerts
      for (final b in _budgets) {
        final cat = b['category'] as String? ?? '';
        final spent = (b['spent'] as num?)?.toDouble() ?? 0;
        final limit = (b['budgetLimit'] as num?)?.toDouble() ?? 0;
        if (limit > 0) {
          NotificationService().showBudgetAlert(
            category: cat,
            spent: spent,
            budgetLimit: limit,
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddBudget() {
    String selectedCategory = _categories.first;
    final limitController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Budget', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Row(children: [
                    Icon(_categoryIcons[c], size: 20, color: _categoryColors[c]),
                    const SizedBox(width: 8),
                    Text(c[0].toUpperCase() + c.substring(1)),
                  ]),
                )).toList(),
                onChanged: (v) => setSheetState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Limit (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (limitController.text.isEmpty) return;
                    try {
                      final api = ApiService(context.read<AuthService>());
                      await api.addBudget(
                        category: selectedCategory,
                        monthlyLimit: double.parse(limitController.text),
                        month: _selectedMonth,
                        year: _selectedYear,
                      );
                      if (mounted) Navigator.pop(ctx);
                      _loadBudgets();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Add Budget'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Budget Planning'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : RefreshIndicator(
              onRefresh: _loadBudgets,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Month selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedMonth == 1) {
                              _selectedMonth = 12;
                              _selectedYear--;
                            } else {
                              _selectedMonth--;
                            }
                          });
                          _loadBudgets();
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '${monthNames[_selectedMonth - 1]} $_selectedYear',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedMonth == 12) {
                              _selectedMonth = 1;
                              _selectedYear++;
                            } else {
                              _selectedMonth++;
                            }
                          });
                          _loadBudgets();
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _totalSpent > _totalLimit && _totalLimit > 0
                              ? Colors.red.shade700
                              : AppTheme.deepGreen,
                          _totalSpent > _totalLimit && _totalLimit > 0
                              ? Colors.red.shade500
                              : const Color(0xFF2E7D32),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Budget',
                          style: TextStyle(color: Colors.green.shade100, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fmt.format(_totalLimit),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _totalLimit > 0 ? (_totalSpent / _totalLimit).clamp(0, 1) : 0,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation(
                            _totalSpent > _totalLimit ? Colors.red.shade300 : Colors.white,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Spent: ${fmt.format(_totalSpent)}',
                                style: const TextStyle(color: Colors.white70)),
                            Text('Left: ${fmt.format((_totalLimit - _totalSpent).clamp(0, double.infinity))}',
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Budget list
                  if (_budgets.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.pie_chart_outline, size: 64, color: theme.dividerColor),
                          const SizedBox(height: 16),
                          Text('No budgets set', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          const Text('Tap + to create your first budget'),
                        ],
                      ),
                    )
                  else
                    ...(_budgets.map((b) {
                      final category = b['category'] as String? ?? 'other';
                      final limit = (b['monthlyLimit'] as num?)?.toDouble() ?? 0;
                      final spent = (b['spent'] as num?)?.toDouble() ?? 0;
                      final pct = (b['percentage'] as num?)?.toDouble() ?? 0;
                      final overBudget = b['overBudget'] as bool? ?? false;
                      final id = b['id'] as int? ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: overBudget ? Border.all(color: Colors.red, width: 1.5) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: (_categoryColors[category] ?? Colors.grey).withAlpha(30),
                                  child: Icon(_categoryIcons[category] ?? Icons.category,
                                      color: _categoryColors[category] ?? Colors.grey, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category[0].toUpperCase() + category.substring(1),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                if (overBudget)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Over!', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'delete') {
                                      final api = ApiService(context.read<AuthService>());
                                      await api.deleteBudget(id);
                                      _loadBudgets();
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (pct / 100).clamp(0, 1),
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  pct > 100 ? Colors.red : pct > 80 ? Colors.orange : AppTheme.deepGreen,
                                ),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${fmt.format(spent)} / ${fmt.format(limit)}',
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                                Text('${pct.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: pct > 100 ? Colors.red : pct > 80 ? Colors.orange : AppTheme.deepGreen,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      );
                    })),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudget,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
