import 'dart:async';

import 'package:flutter/material.dart';

enum AppNoticeKind { success, error, info, warning }

/// Toast compact en haut à droite de l'écran.
class AppNotifier {
  AppNotifier._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void success(String message, {BuildContext? context}) =>
      show(message, kind: AppNoticeKind.success, context: context);

  static void error(String message, {BuildContext? context}) =>
      show(message, kind: AppNoticeKind.error, context: context);

  static void info(String message, {BuildContext? context}) =>
      show(message, kind: AppNoticeKind.info, context: context);

  static void warning(String message, {BuildContext? context}) =>
      show(message, kind: AppNoticeKind.warning, context: context);

  static void show(
    String message, {
    AppNoticeKind kind = AppNoticeKind.info,
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    bool? autoDismiss,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _hide();

    final dismissAutomatically = autoDismiss ?? _autoDismissByDefault(kind);
    final color = _color(kind);

    _entry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.paddingOf(ctx).top + 10;
        return Positioned(
          top: top,
          right: 16,
          child: Material(
            elevation: 6,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(10),
            color: color,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_icon(kind), color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onPressed: _hide,
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);

    if (dismissAutomatically) {
      _timer = Timer(duration, _hide);
    }
  }

  static void _hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static bool _autoDismissByDefault(AppNoticeKind kind) =>
      kind != AppNoticeKind.error;

  static IconData _icon(AppNoticeKind kind) => switch (kind) {
        AppNoticeKind.success => Icons.check_circle_outline,
        AppNoticeKind.error => Icons.error_outline,
        AppNoticeKind.warning => Icons.warning_amber_outlined,
        AppNoticeKind.info => Icons.info_outline,
      };

  static Color _color(AppNoticeKind kind) => switch (kind) {
        AppNoticeKind.success => const Color(0xFF2E7D32),
        AppNoticeKind.error => const Color(0xFFB00020),
        AppNoticeKind.warning => const Color(0xFFE65100),
        AppNoticeKind.info => const Color(0xFF1A1A2E),
      };
}
