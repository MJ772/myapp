// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// role: 'customer' | 'garage' | 'admin' | 'chauffeur' | 'courier'
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;

    // Only customers are auto-approved by default
    final bool vendorApproved    = role == 'garage'    ? false : role == 'customer';
    final bool chauffeurApproved = role == 'chauffeur' ? false : role == 'customer';
    final bool courierApproved   = role == 'courier'   ? false : role == 'customer';

    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'role': role,
      'displayName': cred.user!.displayName ?? '',
      'photoUrl': cred.user!.photoURL ?? '',
      'isVendor': role == 'garage',
      'vendorApproved': vendorApproved,
      'chauffeurApproved': chauffeurApproved,
      'courierApproved': courierApproved,
      'stripeConnected': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return cred;
  }

  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data();
  }

  Future<String?> getUserRole(String uid) async {
    final data = await getUserDoc(uid);
    return data?['role'] as String?;
  }

  Future<void> signOut() => _auth.signOut();
}
