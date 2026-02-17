import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/models/transaction.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _filterType;
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);
      final results = await Future.wait([
        apiService.getTransactions(type: _filterType),
        apiService.getTransactionSummary(period: _period),
      ]);
      setState(() {
        _transactions = results[0] as List<Transaction>;
        _summary = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTransaction(Transaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete "${t.description.isNotEmpty ? t.description : t.category}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final authService = context.read<AuthService>();
      await ApiService(authService).deleteTransaction(t.id!);
      _loadData();
    } catch (_) {}
  }

  void _showAddTransactionDialog() {
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String type = 'expense';
    String category = 'food';
    bool isRecurring = false;
    String frequency = 'monthly';

    final incomeCategories = ['salary', 'business', 'investment', 'gift', 'other'];
    final expenseCategories = [
      'food', 'transport', 'shopping', 'bills', 'rent',
      'health', 'education', 'entertainment', 'charity', 'sadaqah', 'zakat', 'other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final categories = type == 'income' ? incomeCategories : expenseCategories;
          if (!categories.contains(category)) category = categories.first;

          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Add Transaction',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
                const SizedBox(height: 20),

                // Type toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => type = 'income'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'income' ? Colors.green : theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Income',
                                style: TextStyle(
                                  color: type == 'income' ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => type = 'expense'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'expense' ? Colors.red : theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Expense',
                                style: TextStyle(
                                  color: type == 'expense' ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: theme.colorScheme.surfaceContainerLowest,
                  ),
                  items: categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c[0].toUpperCase() + c.substring(1)),
                  )).toList(),
                  onChanged: (v) => setModalState(() => category = v!),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (USD)',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: theme.colorScheme.surfaceContainerLowest,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: theme.colorScheme.surfaceContainerLowest,
                  ),
                ),
                const SizedBox(height: 16),

                // Recurring toggle
                Row(
                  children: [
                    const Icon(Icons.repeat, color: AppTheme.deepGreen, size: 20),
                    const SizedBox(width: 8),
                    const Text('Recurring', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: isRecurring,
                      onChanged: (v) => setModalState(() => isRecurring = v),
                      activeTrackColor: AppTheme.deepGreen,
                    ),
                  ],
                ),
                if (isRecurring)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DropdownButtonFormField<String>(
                      initialValue: frequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        prefixIcon: const Icon(Icons.schedule),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: theme.colorScheme.surfaceContainerLowest,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                      ],
                      onChanged: (v) => setModalState(() => frequency = v!),
                    ),
                  ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text.trim());
                      if (amount == null || amount <= 0) return;
                      Navigator.pop(ctx);
                      try {
                        final authService = context.read<AuthService>();
                        await ApiService(authService).addTransaction(Transaction(
                          type: type,
                          category: category,
                          amount: amount,
                          description: descriptionController.text.trim(),
                          recurring: isRecurring,
                          frequency: isRecurring ? frequency : null,
                        ));
                        _loadData();
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: type == 'income' ? Colors.green : Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Add ${type[0].toUpperCase()}${type.substring(1)}',
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final totalIncome = (_summary['totalIncome'] as num?)?.toDouble() ?? 0;
    final totalExpenses = (_summary['totalExpenses'] as num?)?.toDouble() ?? 0;
    final netIncome = (_summary['netIncome'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              setState(() => _filterType = v == 'all' ? null : v);
              _loadData();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'income', child: Text('Income')),
              const PopupMenuItem(value: 'expense', child: Text('Expenses')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (v) {
              setState(() => _period = v);
              _loadData();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(child: _SummaryCard(
                        label: 'Income', amount: currencyFormat.format(totalIncome),
                        color: Colors.green, icon: Icons.arrow_downward,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _SummaryCard(
                        label: 'Expenses', amount: currencyFormat.format(totalExpenses),
                        color: Colors.red, icon: Icons.arrow_upward,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _SummaryCard(
                        label: 'Net', amount: currencyFormat.format(netIncome),
                        color: netIncome >= 0 ? AppTheme.deepGreen : Colors.red,
                        icon: netIncome >= 0 ? Icons.trending_up : Icons.trending_down,
                      )),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text('${_period[0].toUpperCase()}${_period.substring(1)} Transactions',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
                  const SizedBox(height: 12),

                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.cardColor, borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: theme.dividerColor),
                          const SizedBox(height: 16),
                          Text('No transactions yet', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  else
                    ..._transactions.map((t) => _TransactionTile(
                      transaction: t,
                      currencyFormat: currencyFormat,
                      onDelete: () => _deleteTransaction(t),
                    )),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label, required this.amount,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat currencyFormat;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.currencyFormat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.isIncome;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (isIncome ? Colors.green : Colors.red).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(transaction.categoryIcon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isNotEmpty
                      ? transaction.description
                      : transaction.category[0].toUpperCase() + transaction.category.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${transaction.category[0].toUpperCase()}${transaction.category.substring(1)} • ${dateFormat.format(transaction.dateTime)}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
                if (transaction.recurring)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(Icons.repeat, size: 12, color: AppTheme.deepGreen.withAlpha(180)),
                        const SizedBox(width: 4),
                        Text(
                          transaction.frequency ?? 'recurring',
                          style: TextStyle(color: AppTheme.deepGreen.withAlpha(180), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
