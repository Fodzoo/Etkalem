import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etkalem/services/auth/presence_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PresenceService _presenceService = PresenceService();

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<UserCredential> signInWithEmailPassword(
      String email,
      String password,
      ) async {
    try {
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final userDoc = _firestore.collection("Users").doc(uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          "uid": uid,
          "email": email,
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  Future<UserCredential> signUpWithEmailPassword(
      String email,
      String password,
      String displayName,
      ) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      final uid = user.uid;

      await user.updateDisplayName(displayName);

      final batch = _firestore.batch();

      final privateUserDoc =
      _firestore.collection("Users").doc(uid);

      final publicUserDoc =
      _firestore.collection("PublicUsers").doc(uid);

      batch.set(privateUserDoc, {
        "uid": uid,
        "email": email,
      });

      batch.set(publicUserDoc, {
        "uid": uid,
        "displayName": displayName,
      });

      await batch.commit();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;

    if (user != null) {
      await _presenceService.setUserOffline(user.uid);
    }

    await _auth.signOut();
  }
}
