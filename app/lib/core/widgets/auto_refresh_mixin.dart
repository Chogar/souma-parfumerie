import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/services/app_refresh_notifier.dart';

/// Recharge les données quand [AppRefreshNotifier.notifyDataChanged] est appelé.
mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  AppRefreshNotifier? _refresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    if (!mounted) return;
    final n = context.read<AppRefreshNotifier>();
    if (_refresh == n) return;
    _refresh?.removeListener(_handle);
    _refresh = n;
    _refresh!.addListener(_handle);
  }

  void _handle() {
    if (mounted) onAutoRefresh();
  }

  /// À implémenter : recharger listes / KPI / rapports.
  void onAutoRefresh();

  @override
  void dispose() {
    _refresh?.removeListener(_handle);
    super.dispose();
  }
}

void bumpAppRefresh(BuildContext context) {
  context.read<AppRefreshNotifier>().notifyDataChanged();
}
