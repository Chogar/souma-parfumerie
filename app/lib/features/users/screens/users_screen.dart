import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/crud_icon_actions.dart';
import 'package:souma_parfumerie/core/widgets/numbered_data_table.dart';
import 'package:souma_parfumerie/core/security/permission_catalog.dart';
import 'package:souma_parfumerie/features/users/data/users_repository.dart';
import 'package:souma_parfumerie/features/users/widgets/gestionnaire_permissions_editor.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _repo = UsersRepository();
  final _search = TextEditingController();
  Future<List<Map<String, dynamic>>>? _usersFuture;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    _usersFuture = _repo.list();
    setState(() {});
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> users) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) {
      final name = '${u['full_name']}'.toLowerCase();
      final user = '${u['username']}'.toLowerCase();
      final role = '${u['label_fr']}'.toLowerCase();
      return name.contains(q) || user.contains(q) || role.contains(q);
    }).toList();
  }

  Future<void> _showUserForm([Map<String, dynamic>? user]) async {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = user != null;
    final fullName = TextEditingController(text: user?['full_name']?.toString());
    final username = TextEditingController(text: user?['username']?.toString());
    final password = TextEditingController();
    final confirmPassword = TextEditingController();
    var role = user?['role_code']?.toString() ?? 'gestionnaire';
    var obscurePassword = true;
    var obscureConfirm = true;
    var permValues = PermissionCatalog.mergeWithStored(
      user?['permissions'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(user!['permissions'] as Map)
          : null,
    ).map((k, v) => MapEntry(k, v == true));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final viewHeight = MediaQuery.sizeOf(ctx).height;
          final dialogMaxHeight = (viewHeight * 0.9).clamp(400.0, 720.0);

          void submit() {
            if (fullName.text.trim().isEmpty) {
              AppNotifier.warning(l10n.fullName);
              return;
            }
            if (!isEdit && username.text.trim().isEmpty) {
              AppNotifier.warning(l10n.username);
              return;
            }
            if (!isEdit &&
                (password.text.isEmpty || confirmPassword.text.isEmpty)) {
              AppNotifier.warning(l10n.password);
              return;
            }
            if (password.text.isNotEmpty &&
                password.text != confirmPassword.text) {
              AppNotifier.warning(l10n.passwordMismatch);
              return;
            }
            Navigator.pop(ctx, true);
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 640,
                maxHeight: dialogMaxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Row(
                      children: [
                        Icon(
                          isEdit
                              ? Icons.edit_outlined
                              : Icons.person_add_alt_1,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEdit ? l10n.editUser : l10n.addUser,
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
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: fullName,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  decoration: InputDecoration(
                                    labelText: l10n.fullName,
                                    prefixIcon:
                                        const Icon(Icons.person_outline),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: username,
                                  enabled: !isEdit,
                                  decoration: InputDecoration(
                                    labelText: l10n.username,
                                    prefixIcon:
                                        const Icon(Icons.badge_outlined),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: password,
                                  obscureText: obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: isEdit
                                        ? l10n.newPassword
                                        : l10n.password,
                                    helperText:
                                        isEdit ? l10n.passwordOptional : null,
                                    prefixIcon:
                                        const Icon(Icons.lock_outline),
                                    isDense: true,
                                    suffixIcon: IconButton(
                                      tooltip: obscurePassword
                                          ? l10n.showPassword
                                          : l10n.hidePassword,
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setS(
                                        () => obscurePassword =
                                            !obscurePassword,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: confirmPassword,
                                  obscureText: obscureConfirm,
                                  decoration: InputDecoration(
                                    labelText: l10n.confirmPassword,
                                    helperText:
                                        isEdit ? l10n.passwordOptional : null,
                                    prefixIcon:
                                        const Icon(Icons.lock_outline),
                                    isDense: true,
                                    suffixIcon: IconButton(
                                      tooltip: obscureConfirm
                                          ? l10n.showPassword
                                          : l10n.hidePassword,
                                      icon: Icon(
                                        obscureConfirm
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setS(
                                        () => obscureConfirm =
                                            !obscureConfirm,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            key: ValueKey(role),
                            initialValue: role,
                            decoration: InputDecoration(
                              labelText: l10n.role,
                              prefixIcon: const Icon(Icons.shield_outlined),
                              isDense: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'gestionnaire',
                                child: Text(l10n.roleGestionnaire),
                              ),
                              DropdownMenuItem(
                                value: 'manager',
                                child: Text(l10n.roleManager),
                              ),
                            ],
                            onChanged: (v) =>
                                setS(() => role = v ?? 'gestionnaire'),
                          ),
                          if (role == 'gestionnaire') ...[
                            const SizedBox(height: 14),
                            GestionnairePermissionsEditor(
                              values: permValues,
                              onChanged: (key, value) => setS(
                                () => permValues = {...permValues, key: value},
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: submit,
                          child: Text(l10n.save),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (ok != true) {
      fullName.dispose();
      username.dispose();
      password.dispose();
      confirmPassword.dispose();
      return;
    }

    try {
      final existing = user;
      if (isEdit && existing != null) {
        await _repo.updateUser(
          id: existing['id'] as String,
          fullName: fullName.text.trim(),
          roleCode: role,
          password: password.text.isEmpty ? null : password.text,
          permissions: role == 'gestionnaire'
              ? permValues.map((k, v) => MapEntry(k, v))
              : null,
        );
      } else {
        await _repo.createUser(
          username: username.text.trim(),
          password: password.text,
          fullName: fullName.text.trim(),
          roleCode: role,
          permissions: role == 'gestionnaire'
              ? permValues.map((k, v) => MapEntry(k, v))
              : null,
        );
      }
      _reload();
      if (mounted) AppNotifier.success(l10n.save);
    } catch (e) {
      if (mounted) AppNotifier.error('$e');
    }

    fullName.dispose();
    username.dispose();
    password.dispose();
    confirmPassword.dispose();
  }

  Future<void> _confirmDeleteUser(Map<String, dynamic> u) async {
    final l10n = AppLocalizations.of(context)!;
    final current = context.read<AuthProvider>().user!;
    if (u['id'] == current.id) {
      AppNotifier.warning(l10n.cannotDeleteSelf);
      return;
    }
    if (u['role_code'] == 'manager') {
      AppNotifier.warning(l10n.cannotDeleteManager);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(l10n.confirmDeleteUser(u['full_name']?.toString() ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteUser(u['id'] as String);
      _reload();
      if (mounted) AppNotifier.success(l10n.userDeleted);
    } catch (e) {
      if (mounted) {
        if ('$e'.contains('USER_HAS_SALES')) {
          AppNotifier.error(l10n.userDeleteHasSales);
        } else {
          AppNotifier.error('$e');
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);

    if (!perms.canManageUsers) {
      return Center(child: Text(l10n.managerOnly));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText: l10n.search,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _reload,
                tooltip: l10n.search,
                icon: const Icon(Icons.refresh),
              ),
              FilledButton.icon(
                onPressed: () => _showUserForm(),
                icon: const Icon(Icons.person_add_alt_1, size: 20),
                label: Text(l10n.addUser),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _usersFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = _filter(snap.data!);

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: NumberedDataTable(
                  columns: [
                    NumberedTableColumn(label: l10n.columnNumber),
                    NumberedTableColumn(label: l10n.fullName),
                    NumberedTableColumn(label: l10n.username),
                    NumberedTableColumn(label: l10n.role),
                    NumberedTableColumn(label: l10n.userActive),
                    NumberedTableColumn(label: l10n.columnActions),
                  ],
                  rowCount: users.length,
                  emptyMessage: l10n.noData,
                  totalLabel: l10n.usersCount(users.length),
                  rowBuilder: (context, i, n) {
                    final u = users[i];
                    final isManager = u['role_code'] == 'manager';
                    final active = u['is_active'] as bool? ?? true;
                    final roleLabel = isManager
                        ? l10n.roleManager
                        : (u['label_fr']?.toString() ??
                            l10n.roleGestionnaire);
                    final canDelete =
                        !isManager && u['id'] != user.id;

                    return [
                      numberedIndexCell(n),
                      numberedCell(
                        Text(
                          u['full_name']?.toString() ?? '—',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: active ? null : Colors.grey,
                          ),
                        ),
                      ),
                      numberedCell(
                        Text(
                          u['username']?.toString() ?? '—',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      numberedCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isManager
                                    ? AppTheme.primary
                                    : AppTheme.accent)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isManager
                                  ? AppTheme.primary
                                  : AppTheme.accent,
                            ),
                          ),
                        ),
                      ),
                      numberedCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: active,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) async {
                                await _repo.setActive(u['id'] as String, v);
                                _reload();
                              },
                            ),
                            const SizedBox(width: 6),
                            Text(
                              active
                                  ? l10n.userActive
                                  : l10n.userInactive,
                              style: TextStyle(
                                fontSize: 11,
                                color: active
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        CrudIconActions(
                          editTooltip: l10n.edit,
                          deleteTooltip: l10n.delete,
                          onEdit: () => _showUserForm(u),
                          onDelete: canDelete
                              ? () => _confirmDeleteUser(u)
                              : null,
                        ),
                      ),
                    ];
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
