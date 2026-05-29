import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/services/store_settings_service.dart';
import 'package:souma_parfumerie/core/services/sync_service.dart';
import 'package:souma_parfumerie/core/widgets/app_footer.dart';
import 'package:souma_parfumerie/core/widgets/app_logo.dart';
import 'package:souma_parfumerie/core/services/app_shell_navigation.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/core/widgets/daily_kpi_strip.dart';
import 'package:souma_parfumerie/core/widgets/selectable_content.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/alerts/screens/alerts_screen.dart';
import 'package:souma_parfumerie/features/pos/screens/pos_screen.dart';
import 'package:souma_parfumerie/features/reports/screens/reports_screen.dart';
import 'package:souma_parfumerie/features/shell/hub_screens.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class _NavEntry {
  const _NavEntry({
    required this.icon,
    required this.label,
    required this.screen,
    required this.visible,
    this.navKey,
    this.showKpiStrip = false,
  });

  final IconData icon;
  final String label;
  final Widget screen;
  final bool Function(AppPermissions p) visible;
  final String? navKey;
  final bool showKpiStrip;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppShellNavigation>().addListener(_onShellNavigation);
    });
  }

  @override
  void dispose() {
    context.read<AppShellNavigation>().removeListener(_onShellNavigation);
    super.dispose();
  }

  void _onShellNavigation() {
    if (!mounted) return;
    final nav = context.read<AppShellNavigation>();
    final key = nav.takePendingMenuKey();
    if (key == null) return;
    final l10n = AppLocalizations.of(context)!;
    final user = context.read<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final menu = _entries(l10n).where((e) => e.visible(perms)).toList();
    final i = menu.indexWhere((e) => e.navKey == key);
    if (i >= 0) setState(() => _index = i);
  }

  List<_NavEntry> _entries(AppLocalizations l10n) => [
        _NavEntry(
          icon: Icons.point_of_sale,
          label: l10n.pos,
          screen: const PosScreen(),
          visible: (p) => p.canUsePos,
          showKpiStrip: true,
        ),
        _NavEntry(
          icon: Icons.inventory_2,
          label: l10n.menuBoutique,
          screen: const ProductsHubScreen(),
          visible: (p) => p.canViewCatalog || p.canManageCategories,
        ),
        _NavEntry(
          icon: Icons.notifications_active,
          label: l10n.alerts,
          navKey: AppShellNavigation.menuAlerts,
          screen: const AlertsScreen(),
          visible: (p) => p.canViewAlerts,
        ),
        _NavEntry(
          icon: Icons.receipt_long,
          label: l10n.menuCommerce,
          navKey: AppShellNavigation.menuCommerce,
          screen: const CommerceHubScreen(),
          visible: (p) =>
              p.canViewSalesHistory ||
              p.canManageClients ||
              p.canViewExpenses,
        ),
        _NavEntry(
          icon: Icons.bar_chart,
          label: l10n.reports,
          screen: const ReportsScreen(),
          visible: (p) => p.canViewOperationalReports,
        ),
        _NavEntry(
          icon: Icons.admin_panel_settings,
          label: l10n.menuAdministration,
          screen: const AdminHubScreen(),
          visible: (p) =>
              p.canManageUsers || p.canAccessSettings || p.canManageSuppliers,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final store = context.watch<StoreSettingsService>().settings;
    final user = auth.user!;
    final perms = AppPermissions(user, user.permissions);
    final menu = _entries(l10n).where((e) => e.visible(perms)).toList();

    if (menu.isNotEmpty && _index >= menu.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = 0);
      });
    }
    final idx = menu.isEmpty ? 0 : _index.clamp(0, menu.length - 1);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: AppLogo(size: 36, showBorder: true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.appWindowTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (menu.isNotEmpty)
              Text(
                menu[idx].label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: l10n.syncNow,
            onPressed: () async {
              await context.read<SyncService>().sync();
              if (context.mounted) bumpAppRefresh(context);
            },
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
      body: SelectableContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SideMenu(
                      items: menu,
                      selectedIndex: idx,
                      onSelect: (i) => setState(() => _index = i),
                      onLogout: auth.logout,
                      storeName: store.nameFr,
                      logoutTooltip: l10n.signOut,
                    ),
                    Expanded(
                      child: menu.isEmpty
                          ? Center(child: Text(l10n.errorGeneric))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (menu[idx].showKpiStrip)
                                  const DailyKpiStrip(),
                                Expanded(
                                  child: KeyedSubtree(
                                    key: ValueKey(menu[idx].label),
                                    child: menu[idx].screen,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    required this.storeName,
    required this.logoutTooltip,
  });

  final List<_NavEntry> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final String storeName;
  final String logoutTooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const AppLogo(size: 72, showBorder: true),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              storeName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (var i = 0; i < items.length; i++)
                  _MenuTile(
                    icon: items[i].icon,
                    label: items[i].label,
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: logoutTooltip,
            icon: Icon(Icons.logout, color: Colors.white.withValues(alpha: 0.7)),
            onPressed: onLogout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const Color(0xFFC9A227).withValues(alpha: 0.25)
        : Colors.transparent;
    final fg = selected ? const Color(0xFFC9A227) : Colors.white.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: fg, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
