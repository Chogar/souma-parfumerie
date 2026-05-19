import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/services/sync_service.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/catalog/screens/catalog_screen.dart';
import 'package:souma_parfumerie/features/pos/screens/pos_screen.dart';
import 'package:souma_parfumerie/features/reports/screens/reports_screen.dart';
import 'package:souma_parfumerie/features/settings/screens/settings_screen.dart';
import 'package:souma_parfumerie/features/stock/screens/stock_screen.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;
    final isManager = user.isManager;

    final destinations = <NavigationDestination>[
      NavigationDestination(icon: const Icon(Icons.point_of_sale), label: l10n.pos),
      NavigationDestination(icon: const Icon(Icons.inventory_2), label: l10n.catalog),
      NavigationDestination(icon: const Icon(Icons.warehouse), label: l10n.stock),
      if (isManager)
        NavigationDestination(icon: const Icon(Icons.bar_chart), label: l10n.reports),
      if (isManager)
        NavigationDestination(icon: const Icon(Icons.settings), label: l10n.settings),
    ];

    final screens = <Widget>[
      const PosScreen(),
      const CatalogScreen(),
      const StockScreen(),
      if (isManager) const ReportsScreen(),
      if (isManager) const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: l10n.syncNow,
            onPressed: () => context.read<SyncService>().sync(),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') auth.logout();
              if (v == 'fr' || v == 'ar') {
                context.read<LocaleProvider>().setLocale(v);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text('${user.fullName} (${user.role})'),
              ),
              PopupMenuItem(value: 'fr', child: Text(l10n.french)),
              PopupMenuItem(value: 'ar', child: Text(l10n.arabic)),
              PopupMenuItem(value: 'logout', child: Text(l10n.signOut)),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
