import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // Request permissions (primarily for iOS, but good practice globally)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('PushNotificationService: User granted permission.');
      } else {
        debugPrint('PushNotificationService: User declined or has not accepted permission.');
      }
    } catch (e) {
      debugPrint('PushNotificationService: Failed to initialize. $e');
    }
  }

  static Future<void> updatePremiumSubscription(UserSavingsProfile? profile) async {
    if (kIsWeb) {
      return; // Topic subscription is not supported on Flutter Web
    }

    const topic = 'premium_quick_deals';

    if (profile == null) {
      await _messaging.unsubscribeFromTopic(topic).catchError((e) {
        debugPrint('PushNotificationService: Error unsubscribing: $e');
      });
      return;
    }

    if (profile.planActivated) {
      await _messaging.subscribeToTopic(topic).then((_) {
        debugPrint('PushNotificationService: Subscribed to $topic');
      }).catchError((e) {
        debugPrint('PushNotificationService: Error subscribing: $e');
      });
    } else {
      await _messaging.unsubscribeFromTopic(topic).then((_) {
        debugPrint('PushNotificationService: Unsubscribed from $topic');
      }).catchError((e) {
        debugPrint('PushNotificationService: Error unsubscribing: $e');
      });
    }
  }
}
