import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';

class WasiyyahScreen extends StatefulWidget {
  const WasiyyahScreen({super.key});

  @override
  State<WasiyyahScreen> createState() => _WasiyyahScreenState();
}

class _WasiyyahScreenState extends State<WasiyyahScreen> {
  List<dynamic> _beneficiaries = [];
  double _fixedShareTotal = 0;
  double _voluntaryShareTotal = 0;
  double _voluntaryRemaining = 0;
  Map<String, dynamic> _islamicShares = {};
  bool _isLoading = true;

  final _relationships = ['spouse', 'son', 'daughter', 'father', 'mother', 'brother', 'sister', 'grandchild', 'uncle', 'aunt', 'other'];
  final _relationshipIcons = {
    'spouse': Icons.favorite,
    'son': Icons.boy,
    'daughter': Icons.girl,
    'father': Icons.man,
    'mother': Icons.woman,
    'brother': Icons.people,
    'sister': Icons.people_outline,
    'grandchild': Icons.child_care,
    'uncle': Icons.person,
    'aunt': Icons.person_outline,
    'other': Icons.person_add,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService(context.read<AuthService>());
      final results = await Future.wait([api.getWasiyyahList(), api.getIslamicShares()]);
      final data = results[0];
      setState(() {
        _beneficiaries = data['beneficiaries'] as List<dynamic>? ?? [];
        _fixedShareTotal = (data['fixedShareTotal'] as num?)?.toDouble() ?? 0;
        _voluntaryShareTotal = (data['voluntaryShareTotal'] as num?)?.toDouble() ?? 0;
        _voluntaryRemaining = (data['voluntaryRemaining'] as num?)?.toDouble() ?? 0;
        _islamicShares = results[1]['shares'] as Map<String, dynamic>? ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showIslamicSharesInfo() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.menu_book, color: AppTheme.deepGreen),
          const SizedBox(width: 8),
          const Text('Islamic Inheritance'),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quran 4:11-12 Guidance', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
              const SizedBox(height: 8),
              ..._islamicShares.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_relationshipIcons[e.key] ?? Icons.person, size: 18, color: AppTheme.deepGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key[0].toUpperCase() + e.key.substring(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(e.value.toString(), style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const Divider(),
              Text('Voluntary bequests (wasiyyah) are limited to 1/3 of your estate per Islamic law.',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showAddBeneficiary() {
    String selectedRelationship = 'spouse';
    String shareType = 'voluntary';
    final nameCtrl = TextEditingController();
    final shareCtrl = TextEditingController();
    final assetCtrl = TextEditingController();
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
                const Text('Add Beneficiary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Beneficiary Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRelationship,
                  decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
                  items: _relationships.map((r) => DropdownMenuItem(
                    value: r,
                    child: Row(children: [
                      Icon(_relationshipIcons[r], size: 20),
                      const SizedBox(width: 8),
                      Text(r[0].toUpperCase() + r.substring(1)),
                    ]),
                  )).toList(),
                  onChanged: (v) => setSheetState(() => selectedRelationship = v!),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(controller: shareCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Share %', border: OutlineInputBorder(), suffixText: '%')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: shareType,
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed (Fard)')),
                        DropdownMenuItem(value: 'voluntary', child: Text('Voluntary')),
                      ],
                      onChanged: (v) => setSheetState(() => shareType = v!),
                    ),
                  ),
                ]),
                if (shareType == 'voluntary') ...[
                  const SizedBox(height: 4),
                  Text('Remaining voluntary: ${_voluntaryRemaining.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                ],
                const SizedBox(height: 12),
                TextField(controller: assetCtrl,
                    decoration: const InputDecoration(labelText: 'Asset Description (optional)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || shareCtrl.text.isEmpty) return;
                      try {
                        final api = ApiService(context.read<AuthService>());
                        await api.addWasiyyahBeneficiary(
                          beneficiaryName: nameCtrl.text,
                          relationship: selectedRelationship,
                          sharePercentage: double.parse(shareCtrl.text),
                          shareType: shareType,
                          assetDescription: assetCtrl.text.isNotEmpty ? assetCtrl.text : null,
                        );
                        if (mounted) Navigator.pop(ctx);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Add Beneficiary'),
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
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Wasiyyah (Islamic Will)'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: _showIslamicSharesInfo,
            tooltip: 'Islamic Inheritance Guide',
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
                  // Share totals
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.deepGreen, Colors.teal.shade700]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.description, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        const Text('Estate Distribution', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statCol('Fixed (Fard)', '${_fixedShareTotal.toStringAsFixed(1)}%'),
                            Container(width: 1, height: 40, color: Colors.white30),
                            _statCol('Voluntary', '${_voluntaryShareTotal.toStringAsFixed(1)}%'),
                            Container(width: 1, height: 40, color: Colors.white30),
                            _statCol('Vol. Remaining', '${_voluntaryRemaining.toStringAsFixed(1)}%'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ((_fixedShareTotal + _voluntaryShareTotal) / 100).clamp(0, 1),
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${(_fixedShareTotal + _voluntaryShareTotal).toStringAsFixed(1)}% allocated',
                            style: TextStyle(color: Colors.green.shade100, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1/3 limit note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Voluntary bequests are limited to 1/3 (33.33%) of your estate per Islamic law.',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Beneficiaries
                  const Text('Beneficiaries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_beneficiaries.isEmpty)
                    Center(
                      child: Column(children: [
                        const SizedBox(height: 40),
                        Icon(Icons.description_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No beneficiaries added yet', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Create your Islamic will', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                      ]),
                    )
                  else
                    ...(_beneficiaries.map((b) {
                      final ben = b as Map<String, dynamic>;
                      final relationship = ben['relationship'] as String? ?? 'other';
                      final isFixed = ben['shareType'] == 'fixed';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: isFixed ? Border.all(color: AppTheme.deepGreen.withAlpha(50)) : null,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isFixed ? AppTheme.deepGreen.withAlpha(30) : Colors.orange.withAlpha(30),
                              child: Icon(_relationshipIcons[relationship] ?? Icons.person,
                                  color: isFixed ? AppTheme.deepGreen : Colors.orange, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ben['beneficiaryName'] as String? ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isFixed ? AppTheme.deepGreen.withAlpha(20) : Colors.orange.withAlpha(20),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(isFixed ? 'FARD' : 'VOLUNTARY',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                              color: isFixed ? AppTheme.deepGreen : Colors.orange)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(relationship[0].toUpperCase() + relationship.substring(1),
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                  ]),
                                  if (ben['assetDescription'] != null)
                                    Text(ben['assetDescription'] as String,
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Text('${(ben['sharePercentage'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                    color: isFixed ? AppTheme.deepGreen : Colors.orange)),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'delete') {
                                  final api = ApiService(context.read<AuthService>());
                                  await api.deleteWasiyyahBeneficiary(ben['id'] as int);
                                  _loadData();
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
        onPressed: _showAddBeneficiary,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}
