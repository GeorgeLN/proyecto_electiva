import 'dart:async';

import 'package:flutter/foundation.dart';

/// Convierte un Stream en un Listenable para que GoRouter pueda
/// re-evaluar sus redirects cuando cambia el estado de autenticación.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
