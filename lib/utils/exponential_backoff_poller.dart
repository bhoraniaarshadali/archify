import 'dart:async';
import 'package:flutter/foundation.dart';

/// Smart Exponential Backoff Polling Utility
///
/// Instead of fixed 5-second intervals, this uses exponential backoff:
/// - 1st poll: 2 seconds
/// - 2nd poll: 4 seconds
/// - 3rd poll: 8 seconds
/// - 4th+ poll: 10 seconds (max)
///
/// Benefits:
/// - Reduces server load
/// - Better for slow networks
/// - Fewer timeout issues
/// - More efficient resource usage
class ExponentialBackoffPoller {
  Timer? _timer;
  int _pollCount = 0;
  int _errorCount = 0;

  // Exponential backoff configuration
  static const int _initialDelaySeconds = 2; // Start fast
  static const int _maxDelaySeconds = 5; // Cap at 5s as requested
  static const int _maxErrors = 10000; // Practically no limit as requested

  /// Start polling with exponential backoff
  ///
  /// [onPoll] - Async function to execute on each poll
  /// [onMaxErrors] - Called when max errors reached
  void start({
    required Future<bool> Function() onPoll,
    required VoidCallback onMaxErrors,
  }) {
    _pollCount = 0;
    _errorCount = 0;
    _scheduleNextPoll(onPoll, onMaxErrors);
  }

  void _scheduleNextPoll(
    Future<bool> Function() onPoll,
    VoidCallback onMaxErrors,
  ) {
    // Calculate delay with exponential backoff
    int delaySeconds = _calculateDelay();

    debugPrint(
      '📊 [Polling] Attempt #${_pollCount + 1}, Next poll in ${delaySeconds}s',
    );

    _timer = Timer(Duration(seconds: delaySeconds), () async {
      _pollCount++;

      try {
        // Execute poll function
        bool shouldContinue = await onPoll();

        if (shouldContinue) {
          // Reset error count on success
          _errorCount = 0;
          // Schedule next poll
          _scheduleNextPoll(onPoll, onMaxErrors);
        } else {
          // Task completed or failed, stop polling
          debugPrint('✅ [Polling] Completed after $_pollCount attempts');
          cancel();
        }
      } catch (e) {
        _errorCount++;
        debugPrint('⚠️ [Polling] Error count: $_errorCount/$_maxErrors');

        if (_errorCount >= _maxErrors) {
          debugPrint('❌ [Polling] Max errors reached, stopping');
          cancel();
          onMaxErrors();
        } else {
          // Continue polling despite error
          _scheduleNextPoll(onPoll, onMaxErrors);
        }
      }
    });
  }

  /// Calculate delay using exponential backoff
  /// Formula: min(initialDelay * 2^pollCount, maxDelay)
  int _calculateDelay() {
    if (_pollCount == 0) {
      return _initialDelaySeconds;
    }

    // Exponential: 2, 4, 8, 10, 10, 10...
    int exponentialDelay = _initialDelaySeconds * (1 << _pollCount);
    return exponentialDelay > _maxDelaySeconds
        ? _maxDelaySeconds
        : exponentialDelay;
  }

  /// Cancel polling
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Get current poll count
  int get pollCount => _pollCount;

  /// Get current error count
  int get errorCount => _errorCount;
}
