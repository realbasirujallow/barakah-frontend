import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class SadaqahScreen extends StatefulWidget {
  const SadaqahScreen({super.key});

  @override
  State<SadaqahScreen> createState() => _SadaqahScreenState();
}

class _SadaqahScreenState extends State<SadaqahScreen> {
  List<dynamic> _donations = [];
  double _totalGiven = 0;
  Map<String, dynamic> _byCategory = {};
  bool _isLoading = true;

  final _categories = ['food', 'clothing', 'education', 'medical', 'shelter', 'water', 'general', 'orphan', 'mosque'];
  final _categoryIcons = {
    'food': Icons.restaurant,
    'clothing': Icons.checkroom,
    'education': Icons.school,
    'medical': Icons.local_hospital,
    'shelter': Icons.home,
    'water': Icons.water_drop,
    'general': Icons.volunteer_activism,
    'orphan': Icons.child_care,
    'mosque': Icons.mosque,
  };
  final _categoryColors = {
    'food': Colors.orange,
    'clothing': Colors.purple,
    'education': Colors.blue,
    'medical': Colors.red,
    'shelter': Colors.brown,
    'water': Colors.cyan,
    'general': Colors.green,
    'orphan': Colors.pink,
    'mosque': Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService(context.read<AuthService>());
      final data = await api.getSadaqahList();
      setState(() {
        _donations = data['donations'] as List<dynamic>? ?? [];
        _totalGiven = (data['totalGiven'] as num?)?.toDouble() ?? 0;
        _byCategory = data['byCategory'] as Map<String, dynamic>? ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddSadaqah() {
    final theme = Theme.of(context);
    String selectedCategory = 'general';
    final amountCtrl = TextEditingController();
    final recipientCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isAnonymous = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Record Sadaqah', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('"Charity does not decrease wealth." — Prophet Muhammad (PBUH)',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money))),
                const SizedBox(height: 12),
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
                TextField(controller: recipientCtrl,
                    decoration: const InputDecoration(labelText: 'Recipient (optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: isAnonymous,
                  onChanged: (v) => setSheetState(() => isAnonymous = v),
                  title: const Text('Anonymous Donation'),
                  subtitle: const Text('Hide your name from the record'),
                  activeThumbColor: AppTheme.deepGreen,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (amountCtrl.text.isEmpty) return;
                      try {
                        final api = ApiService(context.read<AuthService>());
                        final result = await api.addSadaqah(
                          amount: double.parse(amountCtrl.text),
                          category: selectedCategory,
                          recipientName: recipientCtrl.text.isNotEmpty ? recipientCtrl.text : null,
                          description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                          anonymous: isAnonymous,
                        );
                        if (mounted) Navigator.pop(ctx);
                        _loadDonations();
                        if (mounted && result['message'] != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'] as String), backgroundColor: AppTheme.deepGreen, duration: const Duration(seconds: 4)),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Record Sadaqah'),
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
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFmt = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Sadaqah Tracker'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : RefreshIndicator(
              onRefresh: _loadDonations,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Total given
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.deepGreen, Colors.green.shade700]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.volunteer_activism, color: Colors.white, size: 36),
                        const SizedBox(height: 8),
                        const Text('Total Sadaqah Given', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(fmt.format(_totalGiven),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('${_donations.length} donations recorded',
                            style: TextStyle(color: Colors.green.shade100, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category breakdown
                  if (_byCategory.isNotEmpty) ...[
                    const Text('By Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _byCategory.entries.map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (_categoryColors[e.key] ?? Colors.grey).withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: (_categoryColors[e.key] ?? Colors.grey).withAlpha(50)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_categoryIcons[e.key] ?? Icons.category, size: 16, color: _categoryColors[e.key]),
                            const SizedBox(width: 4),
                            Text('${e.key}: ${fmt.format(e.value)}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _categoryColors[e.key])),
                          ],
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Donation history
                  const Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_donations.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.volunteer_activism, size: 64, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No sadaqah recorded yet', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  else
                    ...(_donations.map((d) {
                      final donation = d as Map<String, dynamic>;
                      final category = donation['category'] as String? ?? 'general';
                      final date = donation['date'] as int? ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: (_categoryColors[category] ?? Colors.grey).withAlpha(30),
                              child: Icon(_categoryIcons[category] ?? Icons.category,
                                  color: _categoryColors[category] ?? Colors.grey, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category[0].toUpperCase() + category.substring(1),
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (donation['recipientName'] != null)
                                    Text('To: ${donation['recipientName']}',
                                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                  Text(dateFmt.format(DateTime.fromMillisecondsSinceEpoch(date)),
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(fmt.format(donation['amount']),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepGreen, fontSize: 16)),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'delete') {
                                  final api = ApiService(context.read<AuthService>());
                                  await api.deleteSadaqah(donation['id'] as int);
                                  _loadDonations();
                                }
                              },
                              itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Text('Delete'))],
                            ),
                          ],
                        ),
                      );
                    })),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSadaqah,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
