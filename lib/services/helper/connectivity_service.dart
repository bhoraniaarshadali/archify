import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity Service
///
/// Manages real-time internet connection status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;
  
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  
  // Real online status notifier
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  ConnectivityService._internal() {
    _init();
  }

  factory ConnectivityService() => _instance;

  Future<void> _init() async {
    // Initial check
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // connectivity_plus 6.x returns a list of results
    // We are online if any result is NOT 'none'
    final bool online = results.any((result) => result != ConnectivityResult.none);
    if (isOnline.value != online) {
      isOnline.value = online;
      debugPrint('🌐 Connectivity Changed: ${online ? "Online" : "Offline"}');
    }
  }

  // Simple getter for current status
  bool get currentStatus => isOnline.value;

  // Manual dispose if needed
  void dispose() {
    _subscription.cancel();
  }
}
