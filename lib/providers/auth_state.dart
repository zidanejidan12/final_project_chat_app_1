// auth_state.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../screens/chat.dart';

class AuthState extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;

  AuthState() {
    _firebaseAuth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _firebaseAuth.currentUser;

  bool _isAuthenticating = false;
  File? _selectedImage;

  bool get isAuthenticating => _isAuthenticating;
  File? get selectedImage => _selectedImage;

  set isAuthenticating(bool value) {
    _isAuthenticating = value;
    notifyListeners();
  }

  set selectedImage(File? image) {
    _selectedImage = image;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_googleSignIn.currentUser != null) {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER', message: 'Sign in aborted by user');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    if (userCredential.user == null) {
      throw FirebaseAuthException(
          code: 'ERROR_INVALID_CREDENTIAL',
          message: 'The credential data is malformed or has expired.');
    }

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    if (!userData.exists) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'username': userCredential.user!.displayName,
        'email': userCredential.user!.email,
        'image_url': userCredential.user!.photoURL,
      });
    }

    return userCredential;
  }

  Future<void> signIn(
      String email, String password, BuildContext context) async {
    try {
      _isAuthenticating = true;
      notifyListeners();

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userData.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'image_url': userCredential.user!.photoURL,
        });
      }

      _isAuthenticating = false;
      notifyListeners();

      // Navigate to the ChatScreen
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ChatScreen()));
    } catch (e) {
      _isAuthenticating = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String username,
      File? image, BuildContext context) async {
    try {
      _isAuthenticating = true;
      notifyListeners();

      final userCredentials = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${userCredentials.user!.uid}.jpg');

      await storageRef.putFile(image!);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredentials.user!.uid)
          .set({
        'username': username,
        'email': email,
        'image_url': imageUrl,
      });

      _isAuthenticating = false;
      notifyListeners();
    } catch (e) {
      _isAuthenticating = false;
      notifyListeners();
      rethrow;
    }
  }
}
