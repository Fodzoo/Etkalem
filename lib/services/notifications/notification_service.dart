import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etkalem/firebase_options.dart';
import 'package:etkalem/screens/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static StreamSubscription<String>? _tokenRefreshSubscription;

  static Map<String, dynamic>? _pendingNotificationData;
  static bool _isOpeningChat = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'Notifications for new chat messages',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;

        if (payload != null && payload.isNotEmpty) {
          unawaited(_handleLocalNotificationTap(payload));
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Receive notifications while the app is open.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      if (notification == null) return;

      await _localNotifications.show(
        message.hashCode,
        notification.title ?? 'New Message',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_messages',
            'Chat Messages',
            channelDescription: 'Notifications for new chat messages',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // Handle notification taps while the app is in the background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      unawaited(_handleNotificationTap(message.data));
    });

    // Handle FCM notification taps that launch a terminated app.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _pendingNotificationData = Map<String, dynamic>.from(initialMessage.data);
    }

    // Handle local notification taps that launch a terminated app.
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();

    final localPayload = launchDetails?.notificationResponse?.payload;

    if (launchDetails?.didNotificationLaunchApp == true &&
        localPayload != null &&
        localPayload.isNotEmpty) {
      _pendingNotificationData = _decodeNotificationPayload(localPayload);
    }
  }

  static Map<String, dynamic>? _decodeNotificationPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      debugPrint('Notification Payload Error: $e');
    }

    return null;
  }

  static Future<void> _handleLocalNotificationTap(String payload) async {
    final data = _decodeNotificationPayload(payload);

    if (data == null) return;

    await _handleNotificationTap(data);
  }

  static Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _pendingNotificationData = Map<String, dynamic>.from(data);
      return;
    }

    await _openChatFromNotification(data, user.uid);
  }

  // Called after AuthGate confirms that the user is logged in.
  static Future<void> onUserAuthenticated(String uid) async {
    final data = _pendingNotificationData;

    if (data == null) return;

    await _openChatFromNotification(data, uid);
  }

  static Future<void> _openChatFromNotification(
    Map<String, dynamic> data,
    String currentUserID,
  ) async {
    if (_isOpeningChat) return;

    final senderID = data['senderID']?.toString() ?? '';
    final receiverID = data['receiverID']?.toString() ?? '';
    final chatRoomID = data['chatRoomID']?.toString() ?? '';

    if (senderID.isEmpty || receiverID.isEmpty || chatRoomID.isEmpty) {
      _pendingNotificationData = null;
      debugPrint('Invalid notification data');
      return;
    }

    // The logged-in user must be the notification recipient.
    if (receiverID != currentUserID || senderID == currentUserID) {
      _pendingNotificationData = null;
      debugPrint('Notification recipient does not match current user');
      return;
    }

    // Verify the chat room ID.
    final ids = [senderID, receiverID]..sort();
    final expectedChatRoomID = ids.join('_');

    if (chatRoomID != expectedChatRoomID) {
      _pendingNotificationData = null;
      debugPrint('Invalid chat room ID in notification');
      return;
    }

    if (navigatorKey.currentState == null) {
      _pendingNotificationData = Map<String, dynamic>.from(data);
      return;
    }

    _isOpeningChat = true;

    try {
      String senderName = 'New Message';

      try {
        final senderSnapshot = await FirebaseFirestore.instance
            .collection('PublicUsers')
            .where('uid', isEqualTo: senderID)
            .limit(1)
            .get();

        if (senderSnapshot.docs.isNotEmpty) {
          senderName =
              senderSnapshot.docs.first.data()['displayName'] ?? senderName;
        }
      } catch (e) {
        debugPrint('Error fetching sender name: $e');
      }

      // Make sure the user is still logged in as the recipient.
      if (FirebaseAuth.instance.currentUser?.uid != currentUserID) {
        _pendingNotificationData = Map<String, dynamic>.from(data);
        return;
      }

      final navigator = navigatorKey.currentState;

      if (navigator == null) {
        _pendingNotificationData = Map<String, dynamic>.from(data);
        return;
      }

      _pendingNotificationData = null;

      navigator.push(
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(receiverName: senderName, receiverID: senderID),
        ),
      );
    } catch (e) {
      debugPrint('Open Chat From Notification Error: $e');
      _pendingNotificationData = Map<String, dynamic>.from(data);
    } finally {
      _isOpeningChat = false;
    }
  }

  static Future<void> registerToken(String uid) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null || currentUser.uid != uid) return;

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null) {
        debugPrint('FCM Token is null');
        return;
      }

      final userDoc = FirebaseFirestore.instance.collection('Users').doc(uid);

      await userDoc.set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM Token saved for user: $uid');

      await _tokenRefreshSubscription?.cancel();

      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen((newToken) async {
            try {
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) return;

              await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(user.uid)
                  .set({
                    'fcmToken': newToken,
                    'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

              debugPrint('FCM Token updated for user: ${user.uid}');
            } catch (e) {
              debugPrint('Error updating FCM Token: $e');
            }
          });
    } catch (e) {
      debugPrint('Error registering FCM Token: $e');
    }
  }

  static Future<void> stopTokenRefreshListener() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
