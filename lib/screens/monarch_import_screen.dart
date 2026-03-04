import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';

/// Asset / Debt type options matching the web and backend.
const _assetTypes = [
  {'value': 'cash', 'label': 'Cash'},
  {'value': 'savings', 'label': 'Savings'},
  {'value': 'investment', 'label': 'Investment'},
  {'value': 'real_estate', 'label': 'Real Estate'},
  {'value': 'vehicle', 'label': 'Vehicle'},
  {'value': '401k', 'label': '401(k)'},
  {'value': 'roth_ira', 'label': 'Roth IRA'},
  {'value': 'ira', 'label': 'Traditional IRA'},
  {'value': 'hsa', 'label': 'HSA'},
  {'value': '529', 'label': '529 Education'},
  {'value': 'crypto', 'label': 'Crypto'},
  {'value': 'gold', 'label': 'Gold'},
  {'value': 'other', 'label': 'Other'},
];

const _debtTypes = [
  {'value': 'credit_card', 'label': 'Credit Card'},
  {'value': 'conventional_mortgage', 'label': 'Mortgage'},
  {'value': 'car_loan', 'label': 'Car Loan'},
  {'value': 'student_loan', 'label': 'Student Loan'},
  {'value': 'personal_loan', 'label': 'Personal Loan'},
  {'value': 'islamic_mortgage', 'label': 'Islamic Mortgage'},
  {'value': 'other', 'label': 'Other'},
];

class MonarchImportScreen extends StatefulWidget {
  const MonarchImportScreen({super.key});

  @override
  State<MonarchImportScreen> createState() => _MonarchImportScreenState();
}

enum _Step { upload, preview, done }

class _MonarchImportScreenState extends State<MonarchImportScreen> {
  _Step _step = _Step.upload;
  bool _uploading = false;
  bool _importing = false;
  String? _error;
  List<_Account> _accounts = [];
  List<_ExistingAccount> _existingAssets = [];
  List<_ExistingAccount> _existingDebts = [];
  int _totalRecords = 0;
  Map<String, dynamic>? _result;

  late final ApiService _api;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
  }

  // ── Pick file & preview ─────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null) return;

    setState(() { _uploading = true; _error = null; });

    try {
      final data = await _api.monarchPreview(path);
      if (data.containsKey('error')) {
        setState(() { _error = data['error'] as String; _uploading = false; });
        return;
      }
      // Parse existing assets & debts for reconciliation
      final existingAssets = ((data['existingAssets'] as List?) ?? []).map((a) {
        final m = a as Map<String, dynamic>;
        return _ExistingAccount(
          id: (m['id'] as num).toInt(),
          name: m['name'] as String,
          type: m['type'] as String? ?? 'other',
          value: (m['value'] as num?)?.toDouble() ?? (m['remainingAmount'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
      final existingDebts = ((data['existingDebts'] as List?) ?? []).map((a) {
        final m = a as Map<String, dynamic>;
        return _ExistingAccount(
          id: (m['id'] as num).toInt(),
          name: m['name'] as String,
          type: m['type'] as String? ?? 'other',
          value: (m['remainingAmount'] as num?)?.toDouble() ?? (m['value'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      final accounts = (data['accounts'] as List).map((a) {
        final m = a as Map<String, dynamic>;
        final suggestedMatch = m['suggestedMatch'] as Map<String, dynamic>?;
        return _Account(
          name: m['accountName'] as String,
          latestBalance: (m['latestBalance'] as num).toDouble(),
          latestDate: m['latestDate'] as String,
          suggestedType: m['suggestedType'] as String,
          isDebt: m['isDebt'] as bool,
          skip: m['skip'] as bool,
          action: suggestedMatch != null ? 'update' : 'create',
          existingId: suggestedMatch != null ? (suggestedMatch['id'] as num).toInt() : null,
        );
      }).toList();

      setState(() {
        _accounts = accounts;
        _existingAssets = existingAssets;
        _existingDebts = existingDebts;
        _totalRecords = (data['totalRecords'] as num).toInt();
        _step = _Step.preview;
        _uploading = false;
      });
    } catch (e) {
      setState(() { _error = ApiService.errorMessage(e); _uploading = false; });
    }
  }

  // ── Execute import ──────────────────────────────────────────────────────

  Future<void> _executeImport() async {
    setState(() { _importing = true; _error = null; });
    try {
      final payload = _accounts.map((a) => {
        'accountName': a.name,
        'type': a.type,
        'isDebt': a.isDebt,
        'latestBalance': a.latestBalance,
        'skip': a.skip,
        'action': a.action,
        'existingId': a.existingId,
      }).toList();
      final data = await _api.monarchExecute(payload);
      if (data.containsKey('error') && data['success'] != true) {
        setState(() { _error = data['error'] as String; _importing = false; });
        return;
      }
      setState(() { _result = data; _step = _Step.done; _importing = false; });
    } catch (e) {
      setState(() { _error = ApiService.errorMessage(e); _importing = false; });
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  int get _activeCount => _accounts.where((a) => !a.skip).length;
  int get _assetCount => _accounts.where((a) => !a.skip && !a.isDebt).length;
  int get _debtCount => _accounts.where((a) => !a.skip && a.isDebt).length;
  int get _updateCount => _accounts.where((a) => !a.skip && a.action == 'update').length;

  String _fmt(double v) => v < 0
      ? '-\$${v.abs().toStringAsFixed(0)}'
      : '\$${v.toStringAsFixed(0)}';

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Data'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_error != null) _errorBanner(),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.upload:
        return _uploadView();
      case _Step.preview:
        return _previewView();
      case _Step.done:
        return _doneView();
    }
  }

  // ── Upload view ─────────────────────────────────────────────────────────

  Widget _uploadView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.upload_file, size: 72, color: AppTheme.deepGreen),
          const SizedBox(height: 16),
          const Text(
            'Import Balances CSV',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a Balances CSV export (Monarch, Chase,\nWells Fargo, Bank of America, etc.).',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _uploading ? null : _pickFile,
            icon: _uploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.folder_open),
            label: Text(_uploading ? 'Parsing CSV…' : 'Choose CSV File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview view ────────────────────────────────────────────────────────

  Widget _previewView() {
    return Column(
      children: [
        // Summary row
        Row(
          children: [
            _statChip('Records', _totalRecords.toString(), Colors.grey[700]!),
            _statChip('Assets', '$_assetCount', AppTheme.deepGreen),
            _statChip('Debts', '$_debtCount', Colors.red),
            if (_updateCount > 0)
              _statChip('Updates', '$_updateCount', Colors.blue),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('$_activeCount of ${_accounts.length} selected', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const Spacer(),
            TextButton(onPressed: () => setState(() { for (var a in _accounts) a.skip = false; }), child: const Text('Select all')),
            TextButton(onPressed: () => setState(() { for (var a in _accounts) a.skip = true; }), child: const Text('Deselect all', style: TextStyle(color: Colors.red))),
          ],
        ),
        const SizedBox(height: 4),

        // Account list
        Expanded(
          child: ListView.builder(
            itemCount: _accounts.length,
            itemBuilder: (ctx, i) => _accountTile(i),
          ),
        ),

        // Action buttons
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() { _step = _Step.upload; _accounts = []; _error = null; }),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_importing || _activeCount == 0) ? null : _executeImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _importing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Import $_activeCount Account${_activeCount != 1 ? 's' : ''}'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _accountTile(int index) {
    final a = _accounts[index];
    final types = a.isDebt ? _debtTypes : _assetTypes;
    final existingList = a.isDebt ? _existingDebts : _existingAssets;
    final matchedExisting = a.action == 'update' && a.existingId != null
        ? existingList.where((e) => e.id == a.existingId).firstOrNull
        : null;

    return Opacity(
      opacity: a.skip ? 0.4 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: !a.skip,
                    activeColor: AppTheme.deepGreen,
                    onChanged: (_) => setState(() => a.skip = !a.skip),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (matchedExisting != null)
                          Text(
                            '↳ Merging with: ${matchedExisting.name} (${_fmt(matchedExisting.value)})',
                            style: const TextStyle(fontSize: 11, color: Colors.blue),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _fmt(a.latestBalance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: a.isDebt ? Colors.red : AppTheme.deepGreen,
                    ),
                  ),
                ],
              ),
              if (!a.skip) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 48), // align with text above
                    // Category toggle
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Asset', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: true, label: Text('Debt', style: TextStyle(fontSize: 12))),
                      ],
                      selected: {a.isDebt},
                      onSelectionChanged: (s) => setState(() {
                        a.isDebt = s.first;
                        a.type = 'other';
                        a.action = 'create';
                        a.existingId = null;
                      }),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Type dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: types.any((t) => t['value'] == a.type) ? a.type : 'other',
                        isDense: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: types.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() => a.type = v ?? 'other'),
                      ),
                    ),
                  ],
                ),
                // ── Action row: Create New vs Update Existing ──
                if (existingList.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: DropdownButtonFormField<String>(
                      value: a.action == 'update' && a.existingId != null
                          ? 'update-${a.existingId}'
                          : 'create',
                      isDense: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        labelText: 'Action',
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: a.action == 'update' ? Colors.blue : Colors.grey,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: a.action == 'update' ? Colors.blue : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'create',
                          child: Text('+ Create New', style: TextStyle(fontSize: 13)),
                        ),
                        ...existingList.map((ex) => DropdownMenuItem(
                          value: 'update-${ex.id}',
                          child: Text(
                            '↳ ${ex.name} (${_fmt(ex.value)})',
                            style: const TextStyle(fontSize: 12, color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                      onChanged: (v) => setState(() {
                        if (v == 'create' || v == null) {
                          a.action = 'create';
                          a.existingId = null;
                        } else {
                          a.action = 'update';
                          a.existingId = int.parse(v.replaceFirst('update-', ''));
                        }
                      }),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Done view ───────────────────────────────────────────────────────────

  Widget _doneView() {
    final assetsCreated = (_result?['assetsCreated'] as num?)?.toInt() ?? 0;
    final assetsUpdated = (_result?['assetsUpdated'] as num?)?.toInt() ?? 0;
    final debtsCreated = (_result?['debtsCreated'] as num?)?.toInt() ?? 0;
    final debtsUpdated = (_result?['debtsUpdated'] as num?)?.toInt() ?? 0;
    final errors = (_result?['errors'] as List?)?.cast<String>() ?? [];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 72, color: AppTheme.deepGreen),
          const SizedBox(height: 16),
          const Text('Import Complete!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (assetsCreated > 0)
                _resultBadge('$assetsCreated created', AppTheme.deepGreen),
              if (assetsUpdated > 0)
                _resultBadge('$assetsUpdated updated', Colors.blue),
              if (debtsCreated > 0)
                _resultBadge('$debtsCreated debt${debtsCreated != 1 ? 's' : ''}', Colors.red),
              if (debtsUpdated > 0)
                _resultBadge('$debtsUpdated debt${debtsUpdated != 1 ? 's' : ''} updated', Colors.orange),
              if (assetsCreated == 0 && assetsUpdated == 0 && debtsCreated == 0 && debtsUpdated == 0)
                _resultBadge('No changes', Colors.grey),
            ],
          ),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Some accounts failed:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  ...errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 13, color: Colors.red))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/assets'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white),
                child: const Text('View Assets'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/debts'),
                child: const Text('View Debts'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Small widgets ───────────────────────────────────────────────────────

  Widget _errorBanner() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
        GestureDetector(onTap: () => setState(() => _error = null), child: const Icon(Icons.close, color: Colors.red, size: 18)),
      ],
    ),
  );

  Widget _statChip(String label, String value, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ]),
    ),
  );

  Widget _resultBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
  );
}

/// Mutable account data for the preview.
class _Account {
  final String name;
  final double latestBalance;
  final String latestDate;
  String type;
  bool isDebt;
  bool skip;
  String action;   // 'create' or 'update'
  int? existingId; // ID of existing asset/debt when action='update'

  _Account({
    required this.name,
    required this.latestBalance,
    required this.latestDate,
    required String suggestedType,
    required this.isDebt,
    required this.skip,
    this.action = 'create',
    this.existingId,
  }) : type = suggestedType;
}

/// Existing user asset or debt returned from the backend for reconciliation.
class _ExistingAccount {
  final int id;
  final String name;
  final String type;
  final double value;

  _ExistingAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
  });
}
