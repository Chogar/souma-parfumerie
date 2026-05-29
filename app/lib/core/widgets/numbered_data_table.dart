import 'package:flutter/material.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';

/// En-têtes et lignes pour tableaux numérotés (produits, clients, etc.).
class NumberedTableColumn {
  const NumberedTableColumn({
    required this.label,
    this.flex = 1,
    this.numeric = false,
  });

  final String label;
  final int flex;
  final bool numeric;
}

class NumberedDataTable extends StatelessWidget {
  const NumberedDataTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowBuilder,
    this.emptyMessage,
    this.totalLabel,
    this.minTableWidth = 900,
  });

  final List<NumberedTableColumn> columns;
  final int rowCount;
  final List<DataCell> Function(BuildContext context, int index, int number)
      rowBuilder;
  final String? emptyMessage;
  final String? totalLabel;
  final double minTableWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight;
        final height =
            boundedHeight ? constraints.maxHeight : null;
        final tableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(minTableWidth, double.infinity)
            : minTableWidth;

        if (rowCount == 0 && emptyMessage != null) {
          return SizedBox(
            height: height,
            width: constraints.maxWidth,
            child: _tableCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    emptyMessage!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ),
          );
        }

        final theme = Theme.of(context);
        final border = BorderSide(color: Colors.grey.shade300);

        return SizedBox(
          height: height,
          width: constraints.maxWidth,
          child: _tableCard(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (totalLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    color: AppTheme.surface,
                    child: Text(
                      totalLabel!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Scrollbar(
                        thumbVisibility: true,
                        notificationPredicate: (n) =>
                            n.depth == 2 && n.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: tableWidth),
                            child: DataTable(
                              headingRowHeight: 44,
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 72,
                              columnSpacing: 20,
                              horizontalMargin: 16,
                              headingRowColor: WidgetStateProperty.all(
                                AppTheme.primary.withValues(alpha: 0.92),
                              ),
                              headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              dataTextStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade900,
                              ),
                              border: TableBorder(
                                horizontalInside: border,
                                verticalInside: border,
                              ),
                              columns: [
                                DataColumn(
                                  label: Text(
                                    columns.first.label,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                ...columns.skip(1).map(
                                      (c) => DataColumn(
                                        label: Align(
                                          alignment: c.numeric
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Text(c.label),
                                        ),
                                      ),
                                    ),
                              ],
                              rows: List.generate(rowCount, (i) {
                                final n = i + 1;
                                final cells = rowBuilder(context, i, n);
                                return DataRow(
                                  color: WidgetStateProperty.resolveWith(
                                    (states) {
                                      if (states
                                          .contains(WidgetState.hovered)) {
                                        return AppTheme.accent
                                            .withValues(alpha: 0.08);
                                      }
                                      return i.isEven
                                          ? Colors.white
                                          : Colors.grey.shade50;
                                    },
                                  ),
                                  cells: cells,
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tableCard({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

DataCell numberedCell(
  Widget child, {
  Alignment alignment = Alignment.centerLeft,
}) {
  return DataCell(Align(alignment: alignment, child: child));
}

DataCell numberedIndexCell(int number) {
  return DataCell(
    Center(
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppTheme.primary,
          ),
        ),
      ),
    ),
  );
}
