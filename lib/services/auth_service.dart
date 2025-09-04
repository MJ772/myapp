
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> createUserWithEmailAndPassword(
      String email, String password, String role) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'role': role,
          'vendorApproved': role == 'garage' ? kAutoApproveNonCustomer : false,
          'chauffeurApproved':
              role == 'chauffeur' ? kAutoApproveNonCustomer : false,
          'courierApproved': role == 'courier' ? kAutoApproveNonCustomer : false,
          'displayName': '',
          'photoUrl': '',
          'stripeConnected': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.get('role');
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<DocumentSnapshot?> getUserDoc(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      print('Error getting user document: $e');
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
