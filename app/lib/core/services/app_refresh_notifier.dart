import 'package:flutter/foundation.dart';

/// Signal global : après vente, retour, stock, etc. les écrans rechargent leurs données.
class AppRefreshNotifier extends ChangeNotifier {
  int _tick = 0;
  int get tick => _tick;

  void notifyDataChanged() {
    _tick++;
    notifyListeners();
  }
}
