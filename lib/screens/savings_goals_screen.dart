import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/services/notification_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  List<Map<String, dynamic>> _goals = [];
  double _totalSaved = 0;
  double _totalTarget = 0;
  bool _loading = true;

  final _categories = [
    {'key': 'hajj', 'label': 'Hajj/Umrah', 'icon': Icons.mosque},
    {'key': 'emergency', 'label': 'Emergency Fund', 'icon': Icons.health_and_safety},
    {'key': 'education', 'label': 'Education', 'icon': Icons.school},
    {'key': 'wedding', 'label': 'Wedding / Nikah', 'icon': Icons.favorite},
    {'key': 'home', 'label': 'Home', 'icon': Icons.home},
    {'key': 'vehicle', 'label': 'Vehicle', 'icon': Icons.directions_car},
    {'key': 'charity', 'label': 'Charity / Sadaqah', 'icon': Icons.volunteer_activism},
    {'key': 'other', 'label': 'Other', 'icon': Icons.flag},
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(Provider.of<AuthService>(context, listen: false));
      final data = await api.getSavingsGoals();
      setState(() {
        _goals = (data['goals'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _totalSaved = (data['totalSaved'] as num?)?.toDouble() ?? 0;
        _totalTarget = (data['totalTarget'] as num?)?.toDouble() ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  IconData _categoryIcon(String category) {
    final cat = _categories.firstWhere(
      (c) => c['key'] == category,
      orElse: () => {'icon': Icons.flag},
    );
    return cat['icon'] as IconData;
  }

  String _categoryLabel(String category) {
    final cat = _categories.firstWhere(
      (c) => c['key'] == category,
      orElse: () => {'label': category},
    );
    return cat['label'] as String;
  }

  void _showAddGoalDialog() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'hajj';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('New Savings Goal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target Amount (\$)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((c) => DropdownMenuItem(
                  value: c['key'] as String,
                  child: Row(
                    children: [
                      Icon(c['icon'] as IconData, size: 20, color: AppTheme.deepGreen),
                      const SizedBox(width: 8),
                      Text(c['label'] as String),
                    ],
                  ),
                )).toList(),
                onChanged: (v) => setModalState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || targetCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  final api = ApiService(Provider.of<AuthService>(context, listen: false));
                  await api.addSavingsGoal(
                    name: nameCtrl.text.trim(),
                    targetAmount: double.tryParse(targetCtrl.text) ?? 0,
                    category: selectedCategory,
                    description: descCtrl.text.trim(),
                  );
                  _loadGoals();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create Goal', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContributeDialog(Map<String, dynamic> goal) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Contribute to ${goal['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remaining: \$${NumberFormat('#,##0.00').format((goal['remaining'] as num?)?.toDouble() ?? 0)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (\$)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              Navigator.pop(ctx);
              final api = ApiService(Provider.of<AuthService>(context, listen: false));
              await api.contributeSavingsGoal(goal['id'] as int, amount);
              // Show savings milestone notification
              final currentAmount = (goal['currentAmount'] as num?)?.toDouble() ?? 0;
              final targetAmount = (goal['targetAmount'] as num?)?.toDouble() ?? 1;
              final newProgress = ((currentAmount + amount) / targetAmount * 100);
              NotificationService().showSavingsGoalProgress(
                goal['name'] as String? ?? 'Savings Goal',
                newProgress.clamp(0, 100),
              );
              _loadGoals();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white),
            child: const Text('Contribute'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGoals,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.deepGreen, Color(0xFF2E7D32)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text('Total Progress', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          '\$${fmt.format(_totalSaved)} / \$${fmt.format(_totalTarget)}',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _totalTarget > 0 ? (_totalSaved / _totalTarget).clamp(0, 1) : 0,
                            minHeight: 10,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _totalTarget > 0
                              ? '${((_totalSaved / _totalTarget) * 100).toStringAsFixed(1)}% saved'
                              : 'No goals yet',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_goals.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.flag, size: 64, color: theme.dividerColor),
                          const SizedBox(height: 16),
                          Text('No savings goals yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Tap + to create your first goal', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                        ],
                      ),
                    )
                  else
                    ..._goals.map((goal) => _buildGoalCard(goal, fmt)),
                ],
              ),
            ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, NumberFormat fmt) {
    final theme = Theme.of(context);
    final progress = ((goal['progress'] as num?)?.toDouble() ?? 0) / 100;
    final currentAmount = (goal['currentAmount'] as num?)?.toDouble() ?? 0;
    final targetAmount = (goal['targetAmount'] as num?)?.toDouble() ?? 0;
    final completed = goal['completed'] == true;
    final category = goal['category'] as String? ?? 'other';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showContributeDialog(goal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: completed ? AppTheme.gold.withAlpha(30) : AppTheme.deepGreen.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_categoryIcon(category), color: completed ? AppTheme.gold : AppTheme.deepGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_categoryLabel(category), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (completed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Done!', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'delete') {
                        final api = ApiService(Provider.of<AuthService>(context, listen: false));
                        await api.deleteSavingsGoal(goal['id'] as int);
                        _loadGoals();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${fmt.format(currentAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.deepGreen)),
                  Text('\$${fmt.format(targetAmount)}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1).toDouble(),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(completed ? AppTheme.gold : AppTheme.deepGreen),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% complete',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
