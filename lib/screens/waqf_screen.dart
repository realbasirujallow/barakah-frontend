import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class WaqfScreen extends StatefulWidget {
  const WaqfScreen({super.key});

  @override
  State<WaqfScreen> createState() => _WaqfScreenState();
}

class _WaqfScreenState extends State<WaqfScreen> {
  List<dynamic> _contributions = [];
  double _totalContributed = 0;
  Map<String, dynamic> _byPurpose = {};
  bool _isLoading = true;

  final _types = ['cash', 'property', 'equipment', 'books', 'other'];
  final _purposes = ['education', 'healthcare', 'mosque', 'water', 'orphanage', 'general'];
  final _purposeIcons = {
    'education': Icons.school,
    'healthcare': Icons.local_hospital,
    'mosque': Icons.mosque,
    'water': Icons.water_drop,
    'orphanage': Icons.child_care,
    'general': Icons.volunteer_activism,
  };
  final _purposeColors = {
    'education': Colors.blue,
    'healthcare': Colors.red,
    'mosque': Colors.teal,
    'water': Colors.cyan,
    'orphanage': Colors.pink,
    'general': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService(context.read<AuthService>());
      final data = await api.getWaqfList();
      setState(() {
        _contributions = data['contributions'] as List<dynamic>? ?? [];
        _totalContributed = (data['totalContributed'] as num?)?.toDouble() ?? 0;
        _byPurpose = data['byPurpose'] as Map<String, dynamic>? ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddWaqf() {
    final theme = Theme.of(context);
    String selectedType = 'cash';
    String selectedPurpose = 'general';
    final orgCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

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
                const Text('Add Waqf Contribution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('"When a person dies, their deeds end except for three: Sadaqah Jariyah..." — Prophet Muhammad (PBUH)',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                TextField(controller: orgCtrl,
                    decoration: const InputDecoration(labelText: 'Organization Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business))),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                      items: _types.map((t) => DropdownMenuItem(value: t,
                          child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                      onChanged: (v) => setSheetState(() => selectedType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPurpose,
                      decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder()),
                      items: _purposes.map((p) => DropdownMenuItem(
                        value: p,
                        child: Row(children: [
                          Icon(_purposeIcons[p], size: 18, color: _purposeColors[p]),
                          const SizedBox(width: 6),
                          Text(p[0].toUpperCase() + p.substring(1)),
                        ]),
                      )).toList(),
                      onChanged: (v) => setSheetState(() => selectedPurpose = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (orgCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                      try {
                        final api = ApiService(context.read<AuthService>());
                        final result = await api.addWaqf(
                          organizationName: orgCtrl.text,
                          amount: double.parse(amountCtrl.text),
                          type: selectedType,
                          purpose: selectedPurpose,
                          description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                        );
                        if (mounted) Navigator.pop(ctx);
                        _loadContributions();
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
                    child: const Text('Record Waqf'),
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
        title: const Text('Waqf (Endowment)'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : RefreshIndicator(
              onRefresh: _loadContributions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Total contributed
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.teal.shade700, Colors.teal.shade500]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance, color: Colors.white, size: 36),
                        const SizedBox(height: 8),
                        const Text('Total Waqf Contributions', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(fmt.format(_totalContributed),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('${_contributions.length} contributions • Sadaqah Jariyah',
                            style: TextStyle(color: Colors.teal.shade100, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Purpose breakdown
                  if (_byPurpose.isNotEmpty) ...[
                    const Text('By Purpose', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _byPurpose.entries.map((e) {
                        final color = _purposeColors[e.key] ?? Colors.grey;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withAlpha(50)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_purposeIcons[e.key] ?? Icons.category, size: 16, color: color),
                              const SizedBox(width: 4),
                              Text('${e.key}: ${fmt.format(e.value)}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Contribution list
                  const Text('Contributions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_contributions.isEmpty)
                    Center(
                      child: Column(children: [
                        const SizedBox(height: 40),
                        Icon(Icons.account_balance_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No waqf contributions yet', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Start your Sadaqah Jariyah', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                      ]),
                    )
                  else
                    ...(_contributions.map((c) {
                      final contrib = c as Map<String, dynamic>;
                      final purpose = contrib['purpose'] as String? ?? 'general';
                      final date = contrib['date'] as int? ?? 0;
                      final color = _purposeColors[purpose] ?? Colors.grey;

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
                              backgroundColor: color.withAlpha(30),
                              child: Icon(_purposeIcons[purpose] ?? Icons.category, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(contrib['organizationName'] as String? ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(20),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(purpose.toUpperCase(),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(contrib['type'] as String? ?? '',
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                  ]),
                                  Text(dateFmt.format(DateTime.fromMillisecondsSinceEpoch(date)),
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(fmt.format(contrib['amount']),
                                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'delete') {
                                  final api = ApiService(context.read<AuthService>());
                                  await api.deleteWaqf(contrib['id'] as int);
                                  _loadContributions();
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
        onPressed: _showAddWaqf,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
