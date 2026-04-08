import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer';

class NetworkTimeUtils {
  /// Fetches a reliable time from a public server to prevent device-time cheating.
  /// Falls back to DateTime.now() if network request fails.
  static Future<DateTime> getNetworkTime() async {
    try {
      // We use a HEAD request to google.com to get the server time from headers
      // This is faster and more reliable than many custom time APIs.
      final response = await http.head(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 3),
      );

      if (response.headers.containsKey('date')) {
        final dateHeader = response.headers['date']!;
        // Http Date header is in RFC 1123 format (e.g., "Wed, 21 Oct 2015 07:28:00 GMT")
        // HttpDate.parse handles this format reliably.
        final networkDate = HttpDate.parse(dateHeader);
        log("🌐 [NetworkTime]: Successfully fetched from Google: $networkDate");
        return networkDate.toLocal();
      }
    } catch (e) {
      log("⚠️ [NetworkTime]: Failed to fetch network time: $e. Falling back to device time.");
    }

    return DateTime.now();
  }
}
