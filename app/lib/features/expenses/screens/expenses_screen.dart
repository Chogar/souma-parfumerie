import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/core/widgets/crud_icon_actions.dart';
import 'package:souma_parfumerie/core/widgets/numbered_data_table.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/expenses/data/expenses_repository.dart';
import 'package:souma_parfumerie/features/suppliers/data/suppliers_repository.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> with AutoRefreshMixin {
  final _repo = ExpensesRepository();
  final _suppliersRepo = SuppliersRepository();
  final _fmt = NumberFormat('#,##0', 'fr_FR');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _tableMissing = false;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onAutoRefresh() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    _tableMissing = !await _repo.tableExists();
    if (_tableMissing) {
      _items = [];
    } else {
      _items = await _repo.list(category: _filterCategory);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _notifyAndReload() async {
    await _load();
    if (mounted) bumpAppRefresh(context);
  }

  String _categoryLabel(AppLocalizations l10n, String code) => switch (code) {
        'cash_send' => l10n.expenseCategoryCashSend,
        'purchase' => l10n.expenseCategoryPurchase,
        'exit' => l10n.expenseCategoryExit,
        'supply' => l10n.expenseCategorySupply,
        _ => l10n.expenseCategoryOther,
      };

  Future<void> _showExpenseForm([Map<String, dynamic>? expense]) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final perms = AppPermissions(auth.user!, auth.user!.permissions);
    if (!perms.canManageExpenses) {
      AppNotifier.warning(l10n.managerOnly);
      return;
    }
    if (_tableMissing) {
      AppNotifier.error(l10n.expensesMigrationRequired);
      return;
    }

    final isEdit = expense != null;
    final suppliers = await _suppliersRepo.list();
    if (!mounted) return;

    final amountCtrl = TextEditingController(
      text: expense != null ? '${expense['amount']}' : '',
    );
    final descCtrl = TextEditingController(
      text: expense?['description']?.toString() ?? '',
    );
    final benCtrl = TextEditingController(
      text: expense?['beneficiary']?.toString() ?? '',
    );
    var category =
        expense?['category']?.toString() ?? ExpensesRepository.categories.first;
    String? supplierId = expense?['supplier_id'] as String?;
    var expenseDate = expense?['expense_date'] is DateTime
        ? expense!['expense_date'] as DateTime
        : DateTime.now();
    if (expense?['expense_date'] != null && expense!['expense_date'] is! DateTime) {
      expenseDate =
          DateTime.tryParse(expense['expense_date'].toString()) ?? expenseDate;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: AppTheme.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEdit ? l10n.editExpense : l10n.addExpense,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(labelText: l10n.expenseCategory),
                    items: [
                      for (final c in ExpensesRepository.categories)
                        DropdownMenuItem(
                          value: c,
                          child: Text(_categoryLabel(l10n, c)),
                        ),
                    ],
                    onChanged: (v) => setDlg(() {
                      category = v ?? category;
                      if (category != 'supply') supplierId = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: expenseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setDlg(() => expenseDate = d);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: l10n.expenseDate),
                      child: Text(_dateFmt.format(expenseDate)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.expenseAmount,
                      suffixText: AppConfig.currencySymbol,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: benCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.expenseBeneficiary,
                    ),
                  ),
                  if (category == 'supply' && suppliers.isNotEmpty)
                    DropdownButtonFormField<String?>(
                      key: ValueKey(supplierId),
                      initialValue: supplierId,
                      decoration: InputDecoration(labelText: l10n.suppliers),
                      items: [
                        DropdownMenuItem(value: null, child: Text('—')),
                        for (final s in suppliers)
                          DropdownMenuItem(
                            value: s['id'] as String,
                            child: Text(s['name']?.toString() ?? ''),
                          ),
                      ],
                      onChanged: (v) => setDlg(() => supplierId = v),
                    ),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: l10n.expenseDescription),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final amount = double.tryParse(amountCtrl.text.replaceAll(' ', ''));
    final description = descCtrl.text.trim();
    final beneficiary = benCtrl.text.trim();
    amountCtrl.dispose();
    descCtrl.dispose();
    benCtrl.dispose();

    if (ok != true) return;

    if (amount == null || amount <= 0) {
      AppNotifier.error(l10n.expenseAmount);
      return;
    }

    try {
      if (isEdit) {
        await _repo.update(
          id: expense['id'] as String,
          expenseDate: expenseDate,
          amount: amount,
          category: category,
          description: description.isEmpty ? null : description,
          beneficiary: beneficiary.isEmpty ? null : beneficiary,
          supplierId: category == 'supply' ? supplierId : null,
        );
      } else {
        await _repo.create(
          userId: auth.user!.id,
          expenseDate: expenseDate,
          amount: amount,
          category: category,
          description: description.isEmpty ? null : description,
          beneficiary: beneficiary.isEmpty ? null : beneficiary,
          supplierId: category == 'supply' ? supplierId : null,
          paymentMethod: 'cash',
        );
      }
      AppNotifier.success(l10n.save);
      await _notifyAndReload();
    } catch (e) {
      AppNotifier.error('$e');
    }
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteExpense),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _repo.delete(expense['id'] as String);
        AppNotifier.success(l10n.delete);
        await _notifyAndReload();
      } catch (e) {
        AppNotifier.error('$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    if (!perms.canViewExpenses && !perms.canManageExpenses) {
      return Center(child: Text(l10n.managerOnly));
    }

    final canWrite = perms.canManageExpenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_tableMissing)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.expensesMigrationRequired,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _filterCategory,
                      decoration: InputDecoration(
                        labelText: l10n.expenseCategory,
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(l10n.search),
                        ),
                        for (final c in ExpensesRepository.categories)
                          DropdownMenuItem(
                            value: c,
                            child: Text(_categoryLabel(l10n, c)),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() => _filterCategory = v);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
                  if (canWrite)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: l10n.addExpense,
                      onPressed: () => _showExpenseForm(),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : NumberedDataTable(
                    columns: [
                      NumberedTableColumn(label: l10n.columnNumber),
                      NumberedTableColumn(label: l10n.expenseDate),
                      NumberedTableColumn(label: l10n.expenseCategory),
                      NumberedTableColumn(label: l10n.expenseBeneficiary),
                      NumberedTableColumn(label: l10n.expenseDescription),
                      NumberedTableColumn(
                        label: l10n.expenseAmount,
                        numeric: true,
                      ),
                      if (canWrite)
                        NumberedTableColumn(label: l10n.columnActions),
                    ],
                    rowCount: _items.length,
                    emptyMessage: l10n.noData,
                    totalLabel: l10n.tableItemsCount(_items.length),
                    rowBuilder: (context, i, n) {
                      final e = _items[i];
                      final date = e['expense_date'];
                      final dateStr = date is DateTime
                          ? _dateFmt.format(date)
                          : date?.toString() ?? '';
                      final cells = <DataCell>[
                        numberedIndexCell(n),
                        numberedCell(Text(dateStr)),
                        numberedCell(
                          Text(
                            _categoryLabel(
                              l10n,
                              e['category']?.toString() ?? 'other',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        numberedCell(
                          Text(e['beneficiary']?.toString() ?? '—'),
                        ),
                        numberedCell(
                          Text(
                            e['description']?.toString() ?? '—',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        numberedCell(
                          Text(
                            '-${_fmt.format(_num(e['amount']))} ${AppConfig.currencySymbol}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB00020),
                            ),
                          ),
                          alignment: Alignment.centerRight,
                        ),
                      ];
                      if (canWrite) {
                        cells.add(
                          DataCell(
                            CrudIconActions(
                              editTooltip: l10n.edit,
                              deleteTooltip: l10n.delete,
                              onEdit: () => _showExpenseForm(e),
                              onDelete: () => _deleteExpense(e),
                            ),
                          ),
                        );
                      }
                      return cells;
                    },
                  ),
          ),
        ),
      ],
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
