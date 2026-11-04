import 'dart:async';

import 'package:flutter/foundation.dart';

/// Retarde une action tant que l'utilisateur continue de taper.
class Debouncer {
  final Duration delai;
  Timer? _timer;

  Debouncer([this.delai = const Duration(milliseconds: 350)]);

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delai, action);
  }

  void dispose() => _timer?.cancel();
}
