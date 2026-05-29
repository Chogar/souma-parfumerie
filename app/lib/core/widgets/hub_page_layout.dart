import 'package:flutter/material.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/core/widgets/hub_page_header.dart';

/// Onglet pour [HubTabbedLayout].
class HubTab {
  const HubTab({
    required this.label,
    required this.icon,
    this.id,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;

  /// Identifiant stable pour la navigation ([AppShellNavigation]).
  final String? id;

  /// Badge (ex. retours en attente).
  final int badgeCount;
}

/// Page avec en-tête dégradé + contenu (tableau de bord, caisse, catalogue…).
class HubPageLayout extends StatelessWidget {
  const HubPageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.body,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HubPageHeader(title: title, subtitle: subtitle, icon: icon),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Barre d’onglets dorée (administration, commerce, alertes).
class HubStyledTabBar extends StatelessWidget {
  const HubStyledTabBar({super.key, required this.tabs, this.controller});

  final List<Tab> tabs;
  final TabController? controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
          ),
          child: TabBar(
            controller: controller,
            tabs: tabs,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.primary.withValues(alpha: 0.5),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.accent.withValues(alpha: 0.2),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.all(6),
          ),
        ),
      ),
    );
  }
}

Tab hubTabWidget(HubTab tab) {
  Widget label = Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(tab.icon, size: 20),
      const SizedBox(width: 8),
      Text(tab.label),
    ],
  );
  if (tab.badgeCount > 0) {
    label = Badge(
      label: Text('${tab.badgeCount}'),
      child: label,
    );
  }
  return Tab(height: 44, child: label);
}

/// Page avec en-tête + onglets stylisés.
class HubTabbedLayout extends StatelessWidget {
  const HubTabbedLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tabs,
    required this.children,
    this.tabController,
    this.initialTabIndex = 0,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<HubTab> tabs;
  final List<Widget> children;
  final TabController? tabController;
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    assert(tabs.length == children.length);
    final tabWidgets = tabs.map(hubTabWidget).toList();

    if (tabController != null) {
      return ColoredBox(
        color: AppTheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HubPageHeader(title: title, subtitle: subtitle, icon: icon),
            HubStyledTabBar(tabs: tabWidgets, controller: tabController),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: children,
              ),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialTabIndex.clamp(0, tabs.length - 1),
      child: ColoredBox(
        color: AppTheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HubPageHeader(title: title, subtitle: subtitle, icon: icon),
            HubStyledTabBar(tabs: tabWidgets),
            const SizedBox(height: 12),
            Expanded(child: TabBarView(children: children)),
          ],
        ),
      ),
    );
  }
}
