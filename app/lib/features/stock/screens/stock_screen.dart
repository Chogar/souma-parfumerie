import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/features/stock/data/stock_repository.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _repo = StockRepository();
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            onTap: (i) => setState(() => _tab = i),
            tabs: [
              Tab(text: l10n.lowStock),
              Tab(text: l10n.stock),
            ],
          ),
          Expanded(
            child: _tab == 0 ? _buildAlerts(locale) : _buildMovements(locale),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts(String locale) {
    return FutureBuilder(
      future: _repo.lowStockProducts(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.noData));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final p = items[i];
            return ListTile(
              leading: Icon(
                p.isOutOfStock ? Icons.error : Icons.warning,
                color: p.isOutOfStock ? Colors.red : Colors.orange,
              ),
              title: Text(p.displayName(locale)),
              subtitle: Text(p.barcode),
              trailing: Text('${p.stockQuantity}'),
            );
          },
        );
      },
    );
  }

  Widget _buildMovements(String locale) {
    return FutureBuilder(
      future: _repo.recentMovements(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data!;
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final r = rows[i];
            final name = locale.startsWith('ar')
                ? r['name_ar']
                : r['name_fr'];
            return ListTile(
              title: Text(name?.toString() ?? ''),
              subtitle: Text('${r['movement_type']} • ${r['created_at']}'),
              trailing: Text('${r['quantity_delta']}'),
            );
          },
        );
      },
    );
  }
}
