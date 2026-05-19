import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/features/reports/data/reports_repository.dart';
import 'package:souma_parfumerie/features/reports/services/export_service.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = ReportsRepository();
  final _fmt = NumberFormat('#,##0', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    return FutureBuilder(
      future: Future.wait([
        _repo.dailySummary(),
        _repo.topProducts(),
        _repo.monthlyRevenue(months: 6),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final daily = snap.data![0] as Map<String, dynamic>;
        final top = snap.data![1] as List<Map<String, dynamic>>;
        final monthly = snap.data![2] as List<Map<String, dynamic>>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpiCard(
                    l10n.dailySales,
                    '${_fmt.format(_num(daily['revenue']))} ${AppConfig.currencySymbol}',
                  ),
                  _kpiCard(l10n.transactions, '${daily['transactions'] ?? 0}'),
                  _kpiCard(
                    l10n.averageBasket,
                    '${_fmt.format(_num(daily['avg_basket']))} ${AppConfig.currencySymbol}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => ExportService.exportDailyPdf(daily, top),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(l10n.exportPdf),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => ExportService.exportDailyExcel(daily, top),
                    icon: const Icon(Icons.table_chart),
                    label: Text(l10n.exportExcel),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(l10n.topProducts, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...top.map((r) {
                final name = locale.startsWith('ar') ? r['name_ar'] : r['name_fr'];
                return ListTile(
                  title: Text(name?.toString() ?? ''),
                  trailing: Text('${r['qty_sold']}'),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: monthly.isEmpty
                    ? Center(child: Text(l10n.noData))
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: const FlTitlesData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < monthly.length; i++)
                                  FlSpot(
                                    i.toDouble(),
                                    _num(monthly[i]['revenue']),
                                  ),
                              ],
                              isCurved: true,
                              color: const Color(0xFFC9A227),
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
