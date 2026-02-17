import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class SharedFinancesScreen extends StatefulWidget {
  const SharedFinancesScreen({super.key});

  @override
  State<SharedFinancesScreen> createState() => _SharedFinancesScreenState();
}

class _SharedFinancesScreenState extends State<SharedFinancesScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final api = ApiService(Provider.of<AuthService>(context, listen: false));
      final data = await api.getSharedGroups();
      setState(() {
        _groups = List<Map<String, dynamic>>.from(data['groups'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load groups: $e')),
        );
      }
    }
  }

  void _showCreateGroupSheet() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'family';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Create Group', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g. Family Budget',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.group),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: InputDecoration(
                  labelText: 'Group Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'family', child: Text('Family')),
                  DropdownMenuItem(value: 'couple', child: Text('Couple')),
                  DropdownMenuItem(value: 'roommates', child: Text('Roommates')),
                  DropdownMenuItem(value: 'business', child: Text('Business')),
                ],
                onChanged: (v) => setSheetState(() => selectedType = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final api = ApiService(Provider.of<AuthService>(context, listen: false));
                      final result = await api.createSharedGroup({
                        'name': nameCtrl.text.trim(),
                        'type': selectedType,
                        'description': descCtrl.text.trim(),
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Group created! Invite code: ${result['inviteCode']}')),
                        );
                      }
                      _loadGroups();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinGroupDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Join Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the invite code shared by the group owner.'),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Invite Code',
                hintText: 'e.g. ABC12345',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final api = ApiService(Provider.of<AuthService>(context, listen: false));
                await api.joinSharedGroup(codeCtrl.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined group successfully!')),
                  );
                }
                _loadGroups();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _openGroupDetail(Map<String, dynamic> group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GroupDetailScreen(
          groupId: group['id'] as int,
          groupName: group['name'] as String,
          onChanged: _loadGroups,
        ),
      ),
    );
  }

  IconData _groupTypeIcon(String type) {
    switch (type) {
      case 'family': return Icons.family_restroom;
      case 'couple': return Icons.favorite;
      case 'roommates': return Icons.home;
      case 'business': return Icons.business;
      default: return Icons.group;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Finances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Join Group',
            onPressed: _showJoinGroupDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupSheet,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGroups,
              child: _groups.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Icon(Icons.group_add, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No shared groups yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Create a group or join one with an invite code',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _groups.length,
                      itemBuilder: (ctx, i) {
                        final g = _groups[i];
                        final monthlyExpense = (g['monthlyExpenses'] ?? 0).toDouble();
                        final monthlyIncome = (g['monthlyIncome'] ?? 0).toDouble();
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openGroupDetail(g),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      color: AppTheme.deepGreen.withAlpha(25),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(_groupTypeIcon(g['type'] ?? ''), color: AppTheme.deepGreen, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g['name'] ?? '',
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.people, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text('${g['memberCount'] ?? 0} members', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.deepGreen.withAlpha(20),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                (g['type'] ?? '').toString().toUpperCase(),
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.deepGreen),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              '↓ ${_currencyFormat.format(monthlyIncome)}',
                                              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '↑ ${_currencyFormat.format(monthlyExpense)}',
                                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// ─── Group Detail Screen ───────────────────────────────

class _GroupDetailScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  final VoidCallback onChanged;

  const _GroupDetailScreen({
    required this.groupId,
    required this.groupName,
    required this.onChanged,
  });

  @override
  State<_GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<_GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _details = {};
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic> _summary = {};
  bool _loading = true;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ApiService get _api => ApiService(Provider.of<AuthService>(context, listen: false));

  Future<void> _loadAll() async {
    try {
      final api = _api;
      final results = await Future.wait([
        api.getSharedGroupDetails(widget.groupId),
        api.getSharedTransactions(widget.groupId),
        api.getSharedGroupSummary(widget.groupId),
      ]);
      setState(() {
        _details = results[0];
        _transactions = List<Map<String, dynamic>>.from(results[1]['transactions'] ?? []);
        _summary = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAddTransactionSheet() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'expense';
    String category = 'General';
    String splitType = 'equal';

    final categories = [
      'General', 'Food', 'Groceries', 'Rent', 'Utilities', 'Transport',
      'Healthcare', 'Education', 'Entertainment', 'Shopping', 'Charity', 'Savings',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Add Shared Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // Type toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => type = 'expense'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'expense' ? Colors.red.withAlpha(25) : Colors.grey.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: type == 'expense' ? Colors.red : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text('Expense', style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: type == 'expense' ? Colors.red : Colors.grey,
                            )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => type = 'income'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'income' ? Colors.green.withAlpha(25) : Colors.grey.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: type == 'income' ? Colors.green : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text('Income', style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: type == 'income' ? Colors.green : Colors.grey,
                            )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setSheetState(() => category = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: splitType,
                  decoration: InputDecoration(
                    labelText: 'Split Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.call_split),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'equal', child: Text('Split Equally')),
                    DropdownMenuItem(value: 'none', child: Text('No Split')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (v) => setSheetState(() => splitType = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountCtrl.text);
                      if (amount == null || amount <= 0) return;
                      Navigator.pop(ctx);
                      try {
                        await _api.addSharedTransaction(widget.groupId, {
                          'type': type,
                          'category': category,
                          'amount': amount,
                          'description': descCtrl.text.trim(),
                          'splitType': splitType,
                          'note': noteCtrl.text.trim(),
                        });
                        _loadAll();
                        widget.onChanged();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteCodeDialog() {
    final inviteCode = _details['inviteCode'] ?? 'N/A';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Invite Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with others to invite them:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.deepGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.deepGreen),
              ),
              child: Text(
                inviteCode.toString(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppTheme.deepGreen),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteCode.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied!')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final result = await _api.regenerateInviteCode(widget.groupId);
                setState(() {
                  _details['inviteCode'] = result['inviteCode'];
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('New code: ${result['inviteCode']}')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Regenerate', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveOrDelete() {
    final role = _details['myRole'] ?? 'member';
    final isOwner = role == 'owner';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isOwner ? 'Delete Group' : 'Leave Group'),
        content: Text(isOwner
            ? 'This will permanently delete the group and all its data. Are you sure?'
            : 'Are you sure you want to leave this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (isOwner) {
                  await _api.deleteSharedGroup(widget.groupId);
                } else {
                  await _api.leaveSharedGroup(widget.groupId);
                }
                widget.onChanged();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(isOwner ? 'Delete' : 'Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(icon: const Icon(Icons.vpn_key), tooltip: 'Invite Code', onPressed: _loading ? null : _showInviteCodeDialog),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'leave') _confirmLeaveOrDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'leave',
                child: Text(
                  (_details['myRole'] == 'owner') ? 'Delete Group' : 'Leave Group',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.appBarTheme.foregroundColor ?? Colors.white,
          indicatorColor: AppTheme.gold,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Members'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsTab(theme),
                _buildMembersTab(theme),
                _buildSummaryTab(theme),
              ],
            ),
    );
  }

  // ─── Transactions Tab ─────────────────────────

  Widget _buildTransactionsTab(ThemeData theme) {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No transactions yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 4),
            Text('Tap + to add one', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (ctx, i) {
          final tx = _transactions[i];
          final isExpense = tx['type'] == 'expense';
          final amount = (tx['amount'] ?? 0).toDouble();
          final ts = tx['timestamp'] as int?;
          final date = ts != null ? DateFormat('MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(ts)) : '';
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isExpense ? Colors.red.withAlpha(25) : Colors.green.withAlpha(25),
                child: Icon(
                  isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              title: Text(tx['description'] ?? tx['category'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${tx['addedByName'] ?? 'Unknown'} · $date', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? "-" : "+"}${_currencyFormat.format(amount)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isExpense ? Colors.red : Colors.green),
                  ),
                  if (tx['splitType'] != null && tx['splitType'] != 'none')
                    Text(tx['splitType'] == 'equal' ? 'Split' : 'Custom', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Transaction?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await _api.deleteSharedTransaction(widget.groupId, tx['id'] as int);
                    _loadAll();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  // ─── Members Tab ──────────────────────────────

  Widget _buildMembersTab(ThemeData theme) {
    final members = List<Map<String, dynamic>>.from(_details['members'] ?? []);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Invite banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.deepGreen, Color(0xFF2E7D32)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_add, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invite Members', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Share the invite code to add people', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _showInviteCodeDialog,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.deepGreen),
                child: const Text('Invite'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('${members.length} Members', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...members.map((m) {
          final role = m['role'] ?? 'member';
          final isOwner = role == 'owner';
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isOwner ? AppTheme.gold.withAlpha(50) : AppTheme.deepGreen.withAlpha(25),
                child: Text(
                  (m['displayName'] ?? '?')[0].toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: isOwner ? Colors.orange : AppTheme.deepGreen),
                ),
              ),
              title: Text(m['displayName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(role.toString().toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              trailing: (_details['myRole'] == 'owner' && !isOwner)
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove Member?'),
                            content: Text('Remove ${m['displayName']}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Remove', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await _api.removeSharedGroupMember(widget.groupId, m['id'] as int);
                            _loadAll();
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  // ─── Summary Tab ──────────────────────────────

  Widget _buildSummaryTab(ThemeData theme) {
    final totalExpenses = (_summary['totalExpenses'] ?? 0).toDouble();
    final totalIncome = (_summary['totalIncome'] ?? 0).toDouble();
    final net = (_summary['net'] ?? 0).toDouble();
    final categoryBreakdown = List<Map<String, dynamic>>.from(_summary['categoryBreakdown'] ?? []);
    final memberBreakdown = List<Map<String, dynamic>>.from(_summary['memberBreakdown'] ?? []);
    final period = _summary['period'] ?? 'month';

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period selector
          Row(
            children: ['week', 'month', 'year'].map((p) {
              final selected = period == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(p[0].toUpperCase() + p.substring(1)),
                  selected: selected,
                  selectedColor: AppTheme.deepGreen.withAlpha(30),
                  onSelected: (_) async {
                    try {
                      final result = await _api.getSharedGroupSummary(widget.groupId, period: p);
                      setState(() => _summary = result);
                    } catch (_) {}
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Summary cards
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.deepGreen, Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn('Income', _currencyFormat.format(totalIncome), Colors.white),
                    Container(height: 40, width: 1, color: Colors.white.withAlpha(60)),
                    _statColumn('Expenses', _currencyFormat.format(totalExpenses), Colors.white),
                    Container(height: 40, width: 1, color: Colors.white.withAlpha(60)),
                    _statColumn('Net', _currencyFormat.format(net), net >= 0 ? AppTheme.gold : Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Category Breakdown
          if (categoryBreakdown.isNotEmpty) ...[
            Text('By Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...categoryBreakdown.map((cat) {
              final catAmount = (cat['totalAmount'] ?? 0).toDouble();
              final pct = totalExpenses > 0 ? (catAmount / totalExpenses) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat['category'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(_currencyFormat.format(catAmount), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey.withAlpha(40),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.deepGreen),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Member Breakdown
          if (memberBreakdown.isNotEmpty) ...[
            Text('By Member', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...memberBreakdown.map((mem) {
              final memExpense = (mem['expenses'] ?? 0).toDouble();
              final memIncome = (mem['income'] ?? 0).toDouble();
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.deepGreen.withAlpha(25),
                        child: Text(
                          (mem['memberName'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepGreen),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mem['memberName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${mem['transactionCount'] ?? 0} transactions', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('+${_currencyFormat.format(memIncome)}', style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('-${_currencyFormat.format(memExpense)}', style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
