import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/services/session_service.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';

/// Déconnexion après inactivité + remise à zéro du timer sur interaction.
class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key, required this.child});

  final Widget child;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkSession());
  }

  Future<void> _checkSession() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    if (await SessionService.isExpired()) {
      auth.logout(sessionExpired: true);
    }
  }

  void _onActivity() {
    SessionService.recordActivity();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onActivity(),
      onPointerSignal: (_) => _onActivity(),
      child: widget.child,
    );
  }
}
