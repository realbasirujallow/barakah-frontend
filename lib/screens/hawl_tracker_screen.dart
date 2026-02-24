import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/services/notification_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HawlTrackerScreen extends StatefulWidget {
  const HawlTrackerScreen({super.key});

  @override
  State<HawlTrackerScreen> createState() => _HawlTrackerScreenState();
}

class _HawlTrackerScreenState extends State<HawlTrackerScreen> {
  List<dynamic> _trackers = [];
  int _zakatDueCount = 0;
  double _totalZakatDue = 0;
  int _upcomingCount = 0;
  bool _isLoading = true;

  final _assetTypes = ['cash', 'gold', 'silver', 'stocks', 'crypto', 'business', 'other'];
  final _assetIcons = {
    'cash': Icons.attach_money,
    'gold': Icons.diamond,
    'silver': Icons.circle,
    'stocks': Icons.trending_up,
    'crypto': Icons.currency_bitcoin,
    'business': Icons.business,
    'other': Icons.category,
  };
  final _assetColors = {
    'cash': Colors.green,
    'gold': Colors.amber,
    'silver': Colors.blueGrey,
    'stocks': Colors.blue,
    'crypto': Colors.orange,
    'business': Colors.purple,
    'other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _loadTrackers();
  }

  Future<void> _loadTrackers() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService(context.read<AuthService>());
      final data = await api.getHawlTrackers();
      setState(() {
        _trackers = data['trackers'] as List<dynamic>? ?? [];
        _zakatDueCount = (data['zakatDueCount'] as num?)?.toInt() ?? 0;
        _totalZakatDue = (data['totalZakatDue'] as num?)?.toDouble() ?? 0;
        _upcomingCount = (data['upcomingIn30Days'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
      // Check hawl reminders
      for (final t in _trackers) {
        final name = t['assetName'] as String? ?? 'Asset';
        final days = (t['daysRemaining'] as num?)?.toInt() ?? 999;
        NotificationService().showHawlReminder(
          assetName: name,
          daysRemaining: days,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddHawl() {
    String selectedType = 'cash';
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

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
                const Text('Track Hawl', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Hawl is the lunar year (354 days) that must pass before Zakat is due.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Asset Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Asset Type', border: OutlineInputBorder()),
                  items: _assetTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Row(children: [
                      Icon(_assetIcons[t], size: 20, color: _assetColors[t]),
                      const SizedBox(width: 8),
                      Text(t[0].toUpperCase() + t.substring(1)),
                    ]),
                  )).toList(),
                  onChanged: (v) => setSheetState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Asset Value (\$)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money))),
                const SizedBox(height: 12),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                      try {
                        final api = ApiService(context.read<AuthService>());
                        await api.addHawlTracker(
                          assetName: nameCtrl.text,
                          amount: double.parse(amountCtrl.text),
                          assetType: selectedType,
                          notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                        );
                        if (mounted) Navigator.pop(ctx);
                        _loadTrackers();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Start Tracking'),
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
        title: const Text('Hawl Tracker'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : RefreshIndicator(
              onRefresh: _loadTrackers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.deepGreen, Colors.green.shade700]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.access_time_filled, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        const Text('Islamic Lunar Year = 354 Days',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Zakat becomes due after one Hawl passes',
                            style: TextStyle(color: Colors.green.shade100, fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(children: [
                              Text('$_zakatDueCount', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text('Zakat Due', style: TextStyle(color: Colors.green.shade100, fontSize: 12)),
                            ]),
                            Column(children: [
                              Text(fmt.format(_totalZakatDue), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text('Total Due', style: TextStyle(color: Colors.green.shade100, fontSize: 12)),
                            ]),
                            Column(children: [
                              Text('$_upcomingCount', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text('Due in 30d', style: TextStyle(color: Colors.green.shade100, fontSize: 12)),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_trackers.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.access_time, size: 64, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No assets being tracked', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          const Text('Add an asset to track its Hawl period'),
                        ],
                      ),
                    )
                  else
                    ...(_trackers.map((t) {
                      final tracker = t as Map<String, dynamic>;
                      final zakatDue = tracker['zakatDue'] as bool? ?? false;
                      final progress = (tracker['progress'] as num?)?.toDouble() ?? 0;
                      final daysRemaining = (tracker['daysRemaining'] as num?)?.toInt() ?? 0;
                      final assetType = tracker['assetType'] as String? ?? 'other';
                      final startDate = tracker['hawlStartDate'] as int? ?? 0;
                      final endDate = tracker['hawlEndDate'] as int? ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: zakatDue ? Border.all(color: AppTheme.gold, width: 2) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: (_assetColors[assetType] ?? Colors.grey).withAlpha(30),
                                  child: Icon(_assetIcons[assetType] ?? Icons.category,
                                      color: _assetColors[assetType] ?? Colors.grey, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tracker['assetName'] as String? ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(fmt.format(tracker['amount']),
                                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                if (zakatDue)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.gold.withAlpha(30),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, color: AppTheme.gold, size: 14),
                                        SizedBox(width: 4),
                                        Text('Zakat Due', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    final api = ApiService(context.read<AuthService>());
                                    if (v == 'paid') {
                                      await api.markHawlZakatPaid(tracker['id'] as int);
                                      _loadTrackers();
                                    } else if (v == 'delete') {
                                      await api.deleteHawlTracker(tracker['id'] as int);
                                      _loadTrackers();
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (zakatDue)
                                      const PopupMenuItem(value: 'paid', child: Text('Mark Zakat Paid')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Progress
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (progress / 100).clamp(0, 1),
                                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation(
                                        zakatDue ? AppTheme.gold : AppTheme.deepGreen,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('${progress.toStringAsFixed(0)}%',
                                    style: TextStyle(fontWeight: FontWeight.bold,
                                        color: zakatDue ? AppTheme.gold : AppTheme.deepGreen)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Start: ${dateFmt.format(DateTime.fromMillisecondsSinceEpoch(startDate))}',
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                Text(zakatDue ? 'Hawl Complete' : '$daysRemaining days left',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                                        color: zakatDue ? AppTheme.gold : theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                            if (zakatDue) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.gold.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: AppTheme.gold, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Zakat due: ${fmt.format(tracker['zakatAmount'])} (2.5%)',
                                        style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    })),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHawl,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
