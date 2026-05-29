import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/services/app_shell_navigation.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/core/widgets/hub_page_layout.dart';
import 'package:souma_parfumerie/features/sales/data/sale_returns_repository.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/catalog/screens/catalog_screen.dart';
import 'package:souma_parfumerie/features/categories/screens/categories_screen.dart';
import 'package:souma_parfumerie/features/clients/screens/clients_screen.dart';
import 'package:souma_parfumerie/features/expenses/screens/expenses_screen.dart';
import 'package:souma_parfumerie/features/sales/screens/sale_returns_history_screen.dart';
import 'package:souma_parfumerie/features/sales/screens/sales_history_screen.dart';
import 'package:souma_parfumerie/features/settings/screens/settings_screen.dart';
import 'package:souma_parfumerie/features/suppliers/screens/suppliers_screen.dart';
import 'package:souma_parfumerie/features/users/screens/users_screen.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Gestion des produits (CRUD catalogue).
class ProductsHubScreen extends StatelessWidget {
  const ProductsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);

    final tabs = <HubTab>[];
    final children = <Widget>[];

    if (perms.canViewCatalog) {
      tabs.add(HubTab(label: l10n.products, icon: Icons.inventory_2_outlined));
      children.add(const CatalogScreen());
    }
    if (perms.canManageCategories) {
      tabs.add(HubTab(label: l10n.categories, icon: Icons.category_outlined));
      children.add(const CategoriesScreen());
    }

    if (tabs.isEmpty) {
      return HubPageLayout(
        title: l10n.menuBoutique,
        subtitle: l10n.productsHubSubtitle,
        icon: Icons.inventory_2_rounded,
        body: Center(child: Text(l10n.managerOnly)),
      );
    }

    if (tabs.length == 1) {
      return HubPageLayout(
        title: l10n.menuBoutique,
        subtitle: l10n.productsHubSubtitle,
        icon: Icons.inventory_2_rounded,
        body: children.first,
      );
    }

    return HubTabbedLayout(
      title: l10n.menuBoutique,
      subtitle: l10n.productsHubSubtitle,
      icon: Icons.inventory_2_rounded,
      tabs: tabs,
      children: children,
    );
  }
}

/// Historique ventes + Retours + Clients + Dépenses (selon droits).
class CommerceHubScreen extends StatefulWidget {
  const CommerceHubScreen({super.key});

  @override
  State<CommerceHubScreen> createState() => _CommerceHubScreenState();
}

class _CommerceHubScreenState extends State<CommerceHubScreen>
    with SingleTickerProviderStateMixin, AutoRefreshMixin {
  final _returnsRepo = SaleReturnsRepository();
  TabController? _tabController;
  int _tabCount = 0;
  int _pendingReturns = 0;
  AppShellNavigation? _shellNav;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPendingCount());
  }

  @override
  void dispose() {
    _shellNav?.removeListener(_onShellNavigation);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<AppShellNavigation>();
    if (_shellNav != nav) {
      _shellNav?.removeListener(_onShellNavigation);
      _shellNav = nav;
      _shellNav!.addListener(_onShellNavigation);
    }
  }

  void _onShellNavigation() => _applyShellNavigation(animate: true);

  void _applyShellNavigation({required bool animate}) {
    final tabId = context.read<AppShellNavigation>().takePendingCommerceTabId();
    if (tabId == null || _tabController == null) return;
    final l10n = AppLocalizations.of(context)!;
    final user = context.read<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final tabs = _buildTabs(l10n, perms);
    final idx = tabs.indexWhere((t) => t.id == tabId);
    if (idx < 0) return;
    if (animate) {
      _tabController!.animateTo(idx);
    } else {
      _tabController!.index = idx;
    }
  }

  @override
  void onAutoRefresh() => _loadPendingCount();

  Future<void> _loadPendingCount() async {
    final user = context.read<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    if (!perms.canApproveSaleReturn) return;
    final n = await _returnsRepo.countPendingReturns();
    if (mounted) setState(() => _pendingReturns = n);
  }

  List<HubTab> _buildTabs(AppLocalizations l10n, AppPermissions perms) {
    final tabs = <HubTab>[];
    if (perms.canViewSalesHistory) {
      tabs.add(HubTab(label: l10n.salesHistory, icon: Icons.history_outlined));
      tabs.add(
        HubTab(
          id: AppShellNavigation.commerceTabReturns,
          label: l10n.saleReturnsHistory,
          icon: Icons.assignment_return_outlined,
          badgeCount: perms.canApproveSaleReturn ? _pendingReturns : 0,
        ),
      );
    }
    if (perms.canManageClients) {
      tabs.add(HubTab(label: l10n.clients, icon: Icons.people_outline));
    }
    if (perms.canViewExpenses || perms.canManageExpenses) {
      tabs.add(HubTab(label: l10n.expenses, icon: Icons.payments_outlined));
    }
    return tabs;
  }

  List<Widget> _buildChildren(AppPermissions perms) {
    final children = <Widget>[];
    if (perms.canViewSalesHistory) {
      children.add(const SalesHistoryScreen());
      children.add(const SaleReturnsHistoryScreen());
    }
    if (perms.canManageClients) {
      children.add(const ClientsScreen());
    }
    if (perms.canViewExpenses || perms.canManageExpenses) {
      children.add(const ExpensesScreen());
    }
    return children;
  }

  void _syncTabController(int count) {
    if (_tabController != null && _tabController!.length == count) return;
    _tabController?.dispose();
    _tabController = TabController(length: count, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);

    final tabs = _buildTabs(l10n, perms);
    final children = _buildChildren(perms);

    if (tabs.isEmpty) {
      return HubPageLayout(
        title: l10n.menuCommerce,
        subtitle: l10n.commerceHubSubtitle,
        icon: Icons.receipt_long_rounded,
        body: Center(child: Text(l10n.managerOnly)),
      );
    }

    if (tabs.length != _tabCount) {
      _tabCount = tabs.length;
      _syncTabController(tabs.length);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadPendingCount();
        _applyShellNavigation(animate: false);
      });
    }

    if (tabs.length == 1) {
      return HubPageLayout(
        title: l10n.menuCommerce,
        subtitle: l10n.commerceHubSubtitle,
        icon: Icons.receipt_long_rounded,
        body: children.first,
      );
    }

    final controller = _tabController!;
    return HubTabbedLayout(
      title: l10n.menuCommerce,
      subtitle: l10n.commerceHubSubtitle,
      icon: Icons.receipt_long_rounded,
      tabs: tabs,
      tabController: controller,
      children: children,
    );
  }
}

/// Catégories + Utilisateurs + Paramètres (Manager).
class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HubTabbedLayout(
      title: l10n.menuAdministration,
      subtitle: l10n.adminHubSubtitle,
      icon: Icons.admin_panel_settings_rounded,
      tabs: [
        HubTab(label: l10n.suppliers, icon: Icons.local_shipping_outlined),
        HubTab(label: l10n.users, icon: Icons.manage_accounts_outlined),
        HubTab(label: l10n.settings, icon: Icons.settings_outlined),
      ],
      children: const [
        SuppliersScreen(),
        UsersScreen(),
        SettingsScreen(),
      ],
    );
  }
}
