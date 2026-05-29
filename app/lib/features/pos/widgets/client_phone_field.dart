import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/features/clients/data/clients_repository.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Champ téléphone client avec suggestions depuis la base (filtrage à chaque frappe).
class ClientPhoneField extends StatefulWidget {
  const ClientPhoneField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onPhoneChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String?> onPhoneChanged;

  @override
  State<ClientPhoneField> createState() => _ClientPhoneFieldState();
}

class _ClientPhoneFieldState extends State<ClientPhoneField> {
  final _repo = ClientsRepository();
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;
  Timer? _debounce;
  int _requestGen = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    widget.onPhoneChanged(text.trim().isEmpty ? null : text.trim());

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      _search(text);
    });
  }

  Future<void> _search(String raw) async {
    final q = raw.trim();
    final gen = ++_requestGen;

    if (q.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _loading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _loading = true);

    try {
      final rows = await _repo.searchByPhonePrefix(q);
      if (!mounted || gen != _requestGen) return;
      setState(() {
        _suggestions = rows;
        _loading = false;
      });
    } catch (_) {
      if (mounted && gen == _requestGen) {
        setState(() {
          _suggestions = [];
          _loading = false;
        });
      }
    }
  }

  void _selectClient(Map<String, dynamic> client) {
    final phone = client['phone']?.toString() ?? '';
    widget.controller.text = phone;
    widget.controller.selection = TextSelection.collapsed(offset: phone.length);
    widget.onPhoneChanged(phone.isEmpty ? null : phone);
    setState(() => _suggestions = []);
  }

  int _loyalty(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showList = widget.enabled && _suggestions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+\s\-]')),
          ],
          decoration: InputDecoration(
            labelText: l10n.clientPhone,
            hintText: l10n.clientPhoneSearchHint,
            isDense: true,
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: widget.enabled
                            ? () {
                                widget.controller.clear();
                                widget.onPhoneChanged(null);
                                setState(() => _suggestions = []);
                              }
                            : null,
                      )
                    : null,
          ),
        ),
        if (showList) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = _suggestions[i];
                  final phone = c['phone']?.toString() ?? '';
                  final name = c['name']?.toString();
                  final pts = _loyalty(c['loyalty_points']);
                  final threshold = LoyaltyConfig.giftThreshold;

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppTheme.accent.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.person,
                        size: 18,
                        color: AppTheme.accent,
                      ),
                    ),
                    title: Text(
                      phone,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        if (name != null && name.isNotEmpty) name,
                        l10n.loyaltyProgress(pts, threshold),
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectClient(c),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
