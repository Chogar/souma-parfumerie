import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Modale compacte pour choisir la période des rapports.
class ReportPeriodDialog extends StatefulWidget {
  const ReportPeriodDialog({
    super.key,
    required this.from,
    required this.to,
  });

  final DateTime from;
  final DateTime to;

  static Future<DateTimeRange?> show(
    BuildContext context, {
    required DateTime from,
    required DateTime to,
  }) {
    return showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => ReportPeriodDialog(from: from, to: to),
    );
  }

  @override
  State<ReportPeriodDialog> createState() => _ReportPeriodDialogState();
}

class _ReportPeriodDialogState extends State<ReportPeriodDialog> {
  late DateTime _from;
  late DateTime _to;
  final _fmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _from = widget.from;
    _to = widget.to;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? _from : _to;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: isFrom
          ? AppLocalizations.of(context)!.reportDateRange
          : null,
    );
    if (d == null) return;
    setState(() {
      final day = DateTime(d.year, d.month, d.day);
      if (isFrom) {
        _from = day;
        if (_from.isAfter(_to)) _to = _from;
      } else {
        _to = day;
        if (_to.isBefore(_from)) _from = _to;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.date_range, size: 20, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.reportDateRange,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _dateRow(
                label: 'Du',
                value: _fmt.format(_from),
                onTap: () => _pickDate(isFrom: true),
              ),
              const SizedBox(height: 8),
              _dateRow(
                label: 'Au',
                value: _fmt.format(_to),
                onTap: () => _pickDate(isFrom: false),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      DateTimeRange(start: _from, end: _to),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Icon(Icons.edit_calendar, size: 16, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
