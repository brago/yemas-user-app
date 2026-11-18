import 'package:firebase_analytics/firebase_analytics.dart';

/// Records the actions advertising cares about (sign-ups and bookings), so that
/// Google Ads and Firebase can count them as conversions.
/// Tracking must never get in the user's way: any error is ignored.
class Analytics {
  static Future<void> signUp(String method) =>
      _safe(() => FirebaseAnalytics.instance.logSignUp(signUpMethod: method));

  static Future<void> bookingCreated(
      {String? category, String? service, num? amount}) {
    return _safe(() => FirebaseAnalytics.instance.logEvent(
          name: 'booking_created',
          parameters: <String, Object>{
            if (category != null && category.isNotEmpty) 'category': category,
            if (service != null && service.isNotEmpty) 'service': service,
            if (amount != null) 'value': amount,
            'currency': 'XOF',
          },
        ));
  }

  static Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}
