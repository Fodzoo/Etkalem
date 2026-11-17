import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  DatabaseReference? _statusRef;

  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://etkalem-app-default-rtdb.europe-west1.firebasedatabase.app/',
  );

  Future<void> startPresence(String uid) async {
    await _connectionSubscription?.cancel();

    final connectedRef = _database.ref('.info/connected');
    _statusRef = _database.ref('status/$uid');

    _connectionSubscription = connectedRef.onValue.listen((event) async {
      if (event.snapshot.value == true) {
        try {
          await _statusRef!.onDisconnect().set({
            'state': 'offline',
            'last_changed': ServerValue.timestamp,
          });

          await _statusRef!.set({
            'state': 'online',
            'last_changed': ServerValue.timestamp,
          });
        } catch (e) {
          print('Presence Error: $e');
        }
      }
    });
  }

  Future<void> setUserOffline(String uid) async {
    try {
      await _database.ref('status/$uid').set({
        'state': 'offline',
        'last_changed': ServerValue.timestamp,
      });
    } catch (e) {
      print('Presence Error: $e');
    }
  }

  Future<void> setOffline() async {
    if (_statusRef == null) return;

    await setUserOffline(_statusRef!.key!);
  }

  Future<void> stopPresence() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    await setOffline();
    _statusRef = null;
  }

  // Set currently opened chat
  Future<void> setActiveChat(String uid, String otherUserID) async {
    final ids = [uid, otherUserID];
    ids.sort();

    final chatRoomID = ids.join('_');
    final activeChatRef = _database.ref('activeChats/$uid');

    await activeChatRef.onDisconnect().remove();
    await activeChatRef.set(chatRoomID);
  }

  // Clear currently opened chat
  Future<void> clearActiveChat(String uid) async {
    await _database.ref('activeChats/$uid').remove();
  }
}
