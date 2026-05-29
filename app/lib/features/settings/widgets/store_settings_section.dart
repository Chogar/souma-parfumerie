import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/services/store_settings_service.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class StoreSettingsSection extends StatefulWidget {
  const StoreSettingsSection({super.key});

  @override
  State<StoreSettingsSection> createState() => _StoreSettingsSectionState();
}

class _StoreSettingsSectionState extends State<StoreSettingsSection> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameFr;
  late final TextEditingController _nameAr;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _currency;
  late final TextEditingController _currencyCode;
  late final TextEditingController _sloganFr;
  late final TextEditingController _sloganAr;
  late final TextEditingController _legal;
  late final TextEditingController _hours;
  bool _saving = false;
  bool _controllersReady = false;

  @override
  void initState() {
    super.initState();
    _nameFr = TextEditingController();
    _nameAr = TextEditingController();
    _address = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _currency = TextEditingController();
    _currencyCode = TextEditingController();
    _sloganFr = TextEditingController();
    _sloganAr = TextEditingController();
    _legal = TextEditingController();
    _hours = TextEditingController();
  }

  void _bindControllers(StoreSettings s) {
    _nameFr.text = s.nameFr;
    _nameAr.text = s.nameAr;
    _address.text = s.address;
    _phone.text = s.phone;
    _email.text = s.email;
    _currency.text = s.currencySymbol;
    _currencyCode.text = s.currencyCode;
    _sloganFr.text = s.sloganFr;
    _sloganAr.text = s.sloganAr;
    _legal.text = s.legalInfo;
    _hours.text = s.openingHours;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllersReady) {
      _bindControllers(context.read<StoreSettingsService>().settings);
      _controllersReady = true;
    }
  }

  @override
  void dispose() {
    _nameFr.dispose();
    _nameAr.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _currency.dispose();
    _currencyCode.dispose();
    _sloganFr.dispose();
    _sloganAr.dispose();
    _legal.dispose();
    _hours.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final settings = StoreSettings(
        nameFr: _nameFr.text.trim(),
        nameAr: _nameAr.text.trim().isEmpty
            ? _nameFr.text.trim()
            : _nameAr.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        currencySymbol: _currency.text.trim().isEmpty
            ? 'FCFA'
            : _currency.text.trim(),
        currencyCode: _currencyCode.text.trim().isEmpty
            ? 'XAF'
            : _currencyCode.text.trim(),
        sloganFr: _sloganFr.text.trim(),
        sloganAr: _sloganAr.text.trim(),
        legalInfo: _legal.text.trim(),
        openingHours: _hours.text.trim(),
      );
      await context.read<StoreSettingsService>().save(settings);
      if (mounted) AppNotifier.success(l10n.storeSettingsSaved);
    } catch (e) {
      if (mounted) AppNotifier.error('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final canEdit = AppPermissions(user, user.permissions).canAccessSettings;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.storeSettings,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.storeSettingsHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 16),
              if (!canEdit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.managerOnly,
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              AbsorbPointer(
                absorbing: !canEdit,
                child: Opacity(
                  opacity: canEdit ? 1 : 0.65,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameFr,
                              decoration: _dec(l10n.nameFr),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? l10n.nameFr : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: TextFormField(
                                controller: _nameAr,
                                decoration: _dec(l10n.nameAr),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _address,
                        decoration: _dec(l10n.storeAddress),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phone,
                              decoration: _dec(l10n.storePhone),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _email,
                              decoration: _dec(l10n.storeEmail),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _currency,
                              decoration: _dec(l10n.storeCurrency),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _currencyCode,
                              decoration: _dec(l10n.storeCurrencyCode),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _sloganFr,
                        decoration: _dec(l10n.storeSloganFr),
                      ),
                      const SizedBox(height: 10),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: TextFormField(
                          controller: _sloganAr,
                          decoration: _dec(l10n.storeSloganAr),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _legal,
                        decoration: _dec(l10n.storeLegalInfo),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _hours,
                        decoration: _dec(
                          l10n.storeOpeningHours,
                          hint: 'Lun–Sam 9h–20h',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              if (canEdit) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(l10n.save),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
