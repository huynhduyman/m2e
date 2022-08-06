import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/services/firebase_service.dart';
// import '../models/user.dart';

enum AuthState { empty, loading, loaded, success, error }
class AuthProvider with ChangeNotifier {
  final FirebaseService _firebase;
  final googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );
  // final FirebaseAuth _firebaseAuth;
  //FirebaseAuth instance
  AuthProvider(this._firebase);

  AuthState state = AuthState.loading ;
  String errMessage = '';

  GoogleSignInAccount? _user;
  GoogleSignInAccount get user => _user!;

  bool get isSignedIn => _firebase.isSignedIn;
  User? get getUser => _firebase.getUser;

  ///VARAIBLES
  // late User user;

  // bool get isAnonymous {
  //   return _firebase.isAnonymous;
  // }

  // bool get isAuthenticated {
  //   return _firebase.isAuthenticated;
  // }

  initialize() async {
    if (isSignedIn == true) {
      state = AuthState.loaded;
      _handleLoaded();
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {

    try {
      // Trigger the authentication flow
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("googleUser = null");
      }
      _user = googleUser;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      await _firebase.signInWithCredential(credential);
      debugPrint("AuthProvider Provider signInWithGoogle!");


      _handleLoaded();
      notifyListeners();
      debugPrint("firebaseAuth Signed in signInWithGoogle!");
    } catch (e) {
      debugPrint('Error at AuthProvider Provider -> signInWithGoogle: $e');
      _handleError(e);
    }
    // // Once signed in, return the UserCredential
    // return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signInAnonymously() async {
    try {
      await _firebase.signInAnonymously();
      _handleLoaded();
      notifyListeners();
      debugPrint("firebaseAuth Signed in signInAnonymously!");
    } catch (e) {
      debugPrint('Error at AuthProvider Provider -> signInAnonymously: $e');
      _handleError(e);
    }
  }

  //SIGN UP METHOD
  Future<String?> signUp({required String email, required String password}) async {
    _handleLoading();
    try {
    final userEmail = await _firebase.signUp(email: email, password: password);
      if (userEmail == email) {
        _handleSuccess();
        notifyListeners();
        return userEmail;
      } else {
        _handleError(userEmail);
        return userEmail;
      }
    } catch (e) {
      debugPrint('Error at AuthProvider Provider -> signUp: $e');
      _handleError(e);
    }
    return null;
  }

  //SIGN IN METHOD
  Future<String?> signIn({required String email, required String password}) async {
    try {
      final userEmail = await _firebase.signIn(
          email: email, password: password);
      if (userEmail == email) {
        _handleLoaded();
        notifyListeners();
        return userEmail;
      } else {
        return userEmail;
      }

    } catch (e) {
      debugPrint('Error at AuthProvider Provider -> signIn: $e');
      _handleError(e);
    }
    return null;
  }

  //SIGN IN METHOD
  signInWithCredential({required credential}) async {
    try {
      await _firebase.signInWithCredential(credential);
      _handleLoaded();
      notifyListeners();
      return "firebaseAuth Signed in!";
    } catch (e) {
      debugPrint('Error at AuthProvider Provider -> signInWithCredential: $e');
      _handleError(e);
    }
  }

  // SEND EMAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    try {
    final status = await _firebase.sendEmailVerification();
    // _handleLoading();
    // notifyListeners();
    return status;
    } catch (e) {
      debugPrint('Error at AuthProvider Provider -> sendEmailVerification: $e');
      _handleError(e);
    }
  }

  // SEND EMAIL VERIFICATION
  Future<bool> isEmailVerified() async {
    try {
      final status = await _firebase.isEmailVerified();
      if (status == true) {
        // _handleLoaded();
        // notifyListeners();
      }
      return status;
    } catch (e) {
      debugPrint('Error at AuthProvider Provider -> sendEmailVerification: $e');
      _handleError(e);
    }
    return false;
  }

  // FORGOT PASSWORD
  Future<String?> resetPassword({required String email}) async {
    try {
      final status = await _firebase.sendPasswordResetEmail(email: email);
      // _handleSuccess();
      // notifyListeners();
      return status;
    } catch (e) {
      debugPrint('Error at AuthProvider Provider -> resetPassword: $e');
      _handleError(e);
    }
    return null;
  }

  //SIGN OUT METHOD
  Future<void> signOut() async {
    try {
      await _firebase.signOut();
      _handleEmpty();
      notifyListeners();
      debugPrint("firebaseAuth signOut");
    } catch (e) {
      debugPrint('Error at AuthProvider Provider -> signOut: $e');
      _handleError(e);
    }
  }

  void _handleEmpty() {
    state = AuthState.empty;
    errMessage = '';
    notifyListeners();
  }

  void _handleLoading() {
    state = AuthState.loading;
    errMessage = '';
    notifyListeners();
  }

  void _handleLoaded() {
    state = AuthState.loaded;
    errMessage = '';
    notifyListeners();
  }

  void _handleSuccess() {
    state = AuthState.success;
    errMessage = '';
    notifyListeners();
    Timer(const Duration(milliseconds: 450), _handleEmpty);
  }

  void _handleError(e) {
    state = AuthState.error;
    errMessage = e.toString();
    notifyListeners();
  }
}
