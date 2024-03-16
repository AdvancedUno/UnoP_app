import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unop/models/user.dart' as model;
import 'package:unop/resources/storage_methods.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:unop/utils/utils.dart';

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // get user details
  Future<model.User> getUserDetails() async {
    User? currentUser = _auth.currentUser!;

    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

    return model.User.fromSnap(documentSnapshot);
  }

  // Signing Up User

  Future<String> signUpUser(
      {required String email,
      required String password,
      required String username,
      required String bio,
      required Uint8List file,
      required String userSearchId}) async {
    String res = "Some error Occurred";

    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (await checkIfUserExists(userSearchId)) {
        res = "User Id already exist";
      } else if (email.isNotEmpty &&
          password.isNotEmpty &&
          username.isNotEmpty &&
          bio.isNotEmpty &&
          userSearchId.isNotEmpty) {
        // registering user in auth with email and password

        cred.user!.sendEmailVerification();

        //await cred.user?.sendEmailVerification();
        String photoUrl = await StorageMethods()
            .uploadImageToStorage('profilePics', file, false);
        model.User user = model.User(
          username: username,
          usernameLowerCase: username.toLowerCase(),
          uid: cred.user!.uid,
          userSearchId: userSearchId,
          photoUrl: photoUrl,
          email: email,
          bio: bio,
          followers: [],
          following: [],
          group: [],
          likeGroup: [],
        );

        // adding user in our database
        await _firestore
            .collection("users")
            .doc(cred.user!.uid)
            .set(user.toJson());

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // logging in user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error Occurred";
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        // logging in user with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // logging in user
  Future<String> loginUserWithGoogle() async {
    String res = "Some error Occurred";
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      if (!await checkIfEmailExists(googleSignInAccount!.email)) {
        ByteData bytes = await rootBundle.load('assets/UnoP_logo.png');

        signInWithGoogle(
          username: generateRandomString(10),
          userSearchId: generateRandomString(10),
          bio: "none",
          file: bytes.buffer.asUint8List(),
          userInfo: userCredential.user,
          finishedAuth: true,
        );
        res = "first_time";
      } else {
        res = "success";
      }
    } catch (err) {
      return err.toString();
    }
    print(res);
    return res;
  }

  String generateRandomString(int len) {
    var r = Random();
    return String.fromCharCodes(
        List.generate(len, (index) => r.nextInt(33) + 89));
  }

  // logging in user
  Future<String> loginUserWithApple() async {
    String res = "Some error Occurred";
    try {
      final credential =
          AppleAuthProvider(); // Ensure this is obtained correctly

      final UserCredential userCredential =
          await _auth.signInWithProvider(credential);
      if (await checkIfUidExists(userCredential.user?.uid)) {
        ByteData bytes = await rootBundle.load('assets/UnoP_logo.png');

        signInWithApple(
            username: generateRandomString(10),
            userSearchId: generateRandomString(10),
            bio: "none",
            file: bytes.buffer.asUint8List(),
            finishedAuth: true,
            userInfo: userCredential.user!);
        res = "first_time";
      } else {
        res = "success";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> checkIfUserExists(String userSearchId) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('users') // Replace with your collection name
          .where('userSearchId', isEqualTo: userSearchId)
          .limit(1) // Limit to 1 for efficiency
          .get();

      return result
          .docs.isNotEmpty; // Returns true if the user exists, false otherwise
    } catch (e) {
      print('Error checking if user exists: $e');
      return false; // Handle the error or rethrow it as per your app's error handling strategy
    }
  }

  Future<bool> checkIfEmailExists(String? userEmail) async {
    if (userEmail == null || userEmail.trim().isEmpty) {
      // Handle null or empty userEmail appropriately
      return false;
    }

    try {
      userEmail = userEmail.trim().toLowerCase();
      print(userEmail);
      final QuerySnapshot result = await _firestore
          .collection('users') // Replace with your collection name
          .where('email', isEqualTo: userEmail)
          //.limit(1) // Limit to 1 for efficiency
          .get();

      return result
          .docs.isNotEmpty; // Returns true if the user exists, false otherwise
    } catch (e) {
      // Log the error and/or handle it appropriately
      print('Error checking if user Email exists: $e');
      return false; // Consider how you want to handle errors
    }
  }

  Future<bool> checkIfUidExists(String? uid) async {
    if (uid == null || uid.isEmpty) {
      // Handle null or empty userEmail appropriately
      return false;
    }

    try {
      print(uid);
      final QuerySnapshot result = await _firestore
          .collection('users') // Replace with your collection name
          .where('uid', isEqualTo: uid)
          //.limit(1) // Limit to 1 for efficiency
          .get();

      print(result.docs.isEmpty);

      return result
          .docs.isEmpty; // Returns true if the user exists, false otherwise
    } catch (e) {
      // Log the error and/or handle it appropriately
      print('Error checking if user Email exists: $e');
      return false; // Consider how you want to handle errors
    }
  }

  Future<String> signInWithApple({
    required String username,
    required String bio,
    required Uint8List file,
    required String userSearchId,
    required bool finishedAuth,
    User? userInfo,
  }) async {
    String res = "Some error Occurred";

    // 1. perform the sign-in request
    try {
      User? appleUser;

      if (userSearchId.isNotEmpty && await checkIfUserExists(userSearchId)) {
        res = "User Id already exist";
      } else if (username.isNotEmpty &&
          bio.isNotEmpty &&
          userSearchId.isNotEmpty) {
        if (!finishedAuth) {
          final credential =
              AppleAuthProvider(); // Ensure this is obtained correctly

          try {
            final UserCredential userCredential =
                await _auth.signInWithProvider(credential);
            appleUser = userCredential.user;
            res = "success";
          } on FirebaseAuthException catch (e) {
            if (e.code == 'account-exists-with-different-credential') {
              res = 'account-exists-with-different-credential';
            } else if (e.code == 'invalid-credential') {
              res = 'invalid-credential';
            }
          } catch (e) {
            res = "something is wrong, try again";
          }
        } else {
          appleUser = userInfo;
          res = "success";
        }

        ByteData bytes = await rootBundle.load('assets/UnoP_logo.png');
        Uint8List image = bytes.buffer.asUint8List();

        String photoUrl = await StorageMethods()
            .uploadImageToStorage('profilePics', image, false);
        model.User user = model.User(
          username: username, // Provide a default value
          usernameLowerCase: username.toLowerCase(),
          uid: appleUser?.uid ?? 'No uid',
          userSearchId:
              userSearchId, // Assuming you meant to use googleUser.id here
          photoUrl: photoUrl,
          email: "apple@apple.email" ?? 'No Email', // Provide a default value
          bio: bio, // Make sure 'bio' is not null
          followers: [],
          following: [],
          group: [],
          likeGroup: [],
        );
        // adding user in our database
        await _firestore
            .collection("users")
            .doc(appleUser?.uid ?? 'No Name')
            .set(user.toJson());
      } else {
        res = "Please enter all the fields";
      }
    } catch (error) {
      print('error = $error');
    }
    print(res);
    return res;
  }

  Future<String> signInWithGoogle({
    required String username,
    required String bio,
    required Uint8List file,
    required String userSearchId,
    required bool finishedAuth,
    User? userInfo,
  }) async {
    User? googleUser;
    String res = "Some error Occurred";
    if (userSearchId.isNotEmpty && await checkIfUserExists(userSearchId)) {
      res = "User Id already exist";
    } else if (username.isNotEmpty &&
        bio.isNotEmpty &&
        userSearchId.isNotEmpty) {
      if (!finishedAuth) {
        final GoogleSignInAccount? googleSignInAccount =
            await _googleSignIn.signIn();

        if (googleSignInAccount != null) {
          final GoogleSignInAuthentication googleSignInAuthentication =
              await googleSignInAccount.authentication;

          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleSignInAuthentication.accessToken,
            idToken: googleSignInAuthentication.idToken,
          );

          try {
            final UserCredential userCredential =
                await _auth.signInWithCredential(credential);
            googleUser = userCredential.user;
            res = "success";
          } on FirebaseAuthException catch (e) {
            if (e.code == 'account-exists-with-different-credential') {
              res = 'account-exists-with-different-credential';
            } else if (e.code == 'invalid-credential') {
              res = 'invalid-credential';
            }
          } catch (e) {
            res = "something is wrong, try again";
          }
        } else {
          googleUser = userInfo;
        }

        ByteData bytes = await rootBundle.load('assets/UnoP_logo.png');
        Uint8List image = bytes.buffer.asUint8List();

        String photoUrl = await StorageMethods()
            .uploadImageToStorage('profilePics', image, false);
        model.User user = model.User(
          username: username, // Provide a default value
          usernameLowerCase: username.toLowerCase(),
          uid: googleUser?.uid ?? 'No uid',
          userSearchId:
              userSearchId, // Assuming you meant to use googleUser.id here
          photoUrl: photoUrl,
          email: googleUser?.email ?? 'No Email', // Provide a default value
          bio: bio, // Make sure 'bio' is not null
          followers: [],
          following: [],
          group: [],
          likeGroup: [],
        );
        // adding user in our database
        await _firestore
            .collection("users")
            .doc(googleUser?.uid ?? 'No Name')
            .set(user.toJson());
      }
    } else {
      res = "Please enter all the fields";
    }

    return res;
  }

// Check if the user's email has been verified
  Future<bool> checkUserEmailVerification() async {
    // Get the current user
    User? currentInitialUser = _auth.currentUser;

    // Check if the current user is not null
    if (currentInitialUser != null) {
      // Reload the user to get the latest data
      await currentInitialUser.reload();

      // Return the email verified status
      return currentInitialUser.emailVerified;
    }
    // If the current user is null, return false
    return false;
  }

  Future<void> _reauthenticateAndDelete() async {
    try {
      final providerData = _auth.currentUser?.providerData.first;
      print("Aaaa");
      print(providerData);

      if (AppleAuthProvider().providerId == providerData!.providerId) {
        await _auth.currentUser!
            .reauthenticateWithProvider(AppleAuthProvider());
      } else if (GoogleAuthProvider().providerId == providerData.providerId) {
        await _auth.currentUser!
            .reauthenticateWithProvider(GoogleAuthProvider());
      }

      await _auth.currentUser?.delete();
    } catch (e) {
      print("error occered while delte");
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      print("delete account");
      await _auth.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == "requires-recent-login") {
        await _reauthenticateAndDelete();
      } else {
        print("deleteUserAccount error");
      }
    } catch (e) {
      print("deleteUserAccount error");
    }
  }
}
