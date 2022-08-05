import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../models/user.dart';

// abstract class AuthService {
//   Future<UserData> currentUserSystem();
//   Future<UserData> signInWithGoogle();
//   Future<UserData> signInWithFacebook();
//
//   void dispose();
// }

class FirebaseService {

  // static final instance = FirebaseService._();
  // FirebaseService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //FirebaseAuth instance
  // FirebaseService(this._firebaseAuth);

  bool get isSignedIn => _firebaseAuth.currentUser != null;
  User? get getUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  //
  // Stream<User?> get authStateChanges => _firebaseAuth.idTokenChanges();
  // Stream<User?> get onAuthStateChanged => _firebaseAuth.authStateChanges();

  User? user;

  // // auth change user stream
  // Stream<User?> get onAuthStateChanged{
  //   return _firebaseAuth.authStateChanges()
  //   //.map((User? user) => _userModelFromFirebase(user));
  //       .map(_userModelFromFirebase);
  // }

  // //create an userModel object based on Firebase User object
  // User? _userModelFromFirebase(User? user){
  //   if (user != null) {
  //     return User(
  //         uid: user.uid,
  //         email: user.email,
  //         displayName: user.displayName,
  //         photoUrl: user.photoURL,
  //         isVerified: user.emailVerified);
  //   } else {
  //     return null;
  //   }
  // }

  // auth change user stream
  // Stream<User?> get onAuthStateChanged{
  //   return _firebaseAuth.authStateChanges()
  //   //.map((User? user) => _userModelFromFirebase(user));
  //       .map(_userModelFromFirebase);
  // }

  // User? user;




  // FirebaseAuth auth = FirebaseAuth.instance;
  // User? user;

  // late FirebaseUser user;
  // late StreamSubscription userAuthSub;

  // bool get isAnonymous {
  //   assert(user != null);
  //   bool isAnonymousUser = true;
  //   for (UserInfo info in user!.providerData) {
  //     if (info.providerId == "facebook.com" ||
  //         info.providerId == "google.com" ||
  //         info.providerId == "password") {
  //       isAnonymousUser = false;
  //       break;
  //     }
  //   }
  //   return isAnonymousUser;
  // }
  //
  // bool get isAuthenticated {
  //   debugPrint('get isAuthenticated');
  //   debugPrint(user?.uid.toString());
  //   if (user?.uid != null) {
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }

  //SIGN UP METHOD
  Future<String?> signUp({required String email, required String password}) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: password
      );

      User? user = _firebaseAuth.currentUser;
      await FirebaseFirestore.instance.collection("users").doc(user?.uid).set({
        'uid': user?.uid,
        'email': email,
        // 'password': password,
      })
      //     .then((value) {
      //   return user?.email.toString();
      // })
          .onError((error, _) {
        return error.toString();
      });
      debugPrint('Save user to FirebaseFirestore');
      debugPrint(user?.email.toString());
      return user?.email.toString();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        return e.code.toString();
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        return e.code.toString();
      }
    } catch (e) {
      print(e);
      return e.toString();
    }

    // try {
    //   await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password).then((value) async {
    //     User? user = _firebaseAuth.currentUser;
    //     await FirebaseFirestore.instance.collection("users").doc(user?.uid).set({
    //       'uid': user?.uid,
    //       'email': email,
    //       // 'password': password,
    //     });
    //   });
    //   // return _userModelFromFirebase(user);
    //   return "Signed Up";
    // } on FirebaseAuthException catch (e) {
    //   return e.message.toString();
    // }
  }

  Future<void> signInAnonymously() async {
    try {
      await _firebaseAuth.signInAnonymously();
      debugPrint("firebaseAuth Signed in signInAnonymously!");
    } on FirebaseAuthException catch (e) {
      debugPrint(e.message.toString());
    }
  }

  //SIGN IN METHOD
  Future<String?> signIn({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password
      );
      User? user = _firebaseAuth.currentUser;
      debugPrint(userCredential.user?.email.toString());
      return userCredential.user?.email.toString();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
      return e.code.toString();
    }

    // try {
    //   await _firebaseAuth.signInWithEmailAndPassword(
    //       email: email, password: password);
    //   return "firebaseAuth Signed in!";
    // } on FirebaseAuthException catch (e) {
    //   return e.message.toString();
    // }
  }

  //SIGN IN METHOD
  Future<String?> signInWithCredential(credential) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      debugPrint("firebaseAuth Signed in!");
      debugPrint(user?.uid);
      return user?.uid;
    } on FirebaseAuthException catch (e) {
      return e.message.toString();
    }
  }

  Future<User?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    return user;
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser!;
    user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser!;
    return user.emailVerified;
  }

  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
      return e.code.toString();
    }
  }

  //SIGN OUT METHOD
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    debugPrint("firebaseAuth signOut");
  }
}