import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mullr_components/services/toast_service.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'navigation_service.dart';

class AuthService {
  bool connectedToNetwork = false;
  String message = 'Something went wrong';

  FirebaseAuth auth() {
    return FirebaseAuth.instance;
  }

  User? user() {
    return auth().currentUser;
  }

  String? get uid {
    return auth().currentUser?.uid;
  }

  Future<String?> get token async {
    return auth().currentUser?.getIdToken();
  }

  Future<void> setup({bool development = false}) async {
    ConnectivityResult connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      connectedToNetwork = true;
      await Firebase.initializeApp();
      //await GetIt.instance.get<RemoteConfigService>().initializeRemoteConfig();
      //await GetIt.instance.get<CrashlyticsService>().initializeCrashlytics();
      //if (development) firebaseService.setUpEmulator();
    } else if (connectivityResult == ConnectivityResult.none) {
      print('Not connected to network');
      connectedToNetwork = false;
    }
  }

  Future<void> rememberMe() async {
    await auth().setPersistence(Persistence.SESSION);
  }

  Future<void> forgetMe() async {
    await auth().setPersistence(Persistence.NONE);
  }

  Future<void> signOut() async {
    await auth().signOut();
  }

  Future<bool> createUserWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    // Try to create the user with an Email and Password in Firebase
    try {
      await auth()
          .createUserWithEmailAndPassword(email: email, password: password);

      return true;
    }
    // If it fails, return false
    on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        GetIt.instance.get<ToastService>()
            .showSnackbar(context, 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        GetIt.instance.get<ToastService>().showSnackbar(
            context, 'The account already exists for that email.');
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    try {
      await auth().signInAnonymously();

      return true;
    } on FirebaseAuthException catch (e) {
      GetIt.instance.get<ToastService>().showToast(
          'Sorry, we are temporarily not allowing anonymous accounts');

      return false;
    }
  }

  Future<bool> signInWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      await auth().signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Signed in successfully');
      // Successfully signed in
      return true;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ' + e.toString());
      if (e.code == 'user-not-found') {
        GetIt.instance.get<ToastService>().showSnackbar(context, 'No user found for that email.');
      } else if (e.code == 'wrong-password') {
        GetIt.instance.get<ToastService>()
            .showSnackbar(context, 'Wrong password provided for that user.');
      }
      return false;
    } catch (e) {
      print('Sign in error: ' + e.toString());
      return false;
    }
  }

  /// This method is used for phone sign up and sign in
  Future<void> signUpWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    TextEditingController verificationController = TextEditingController();

    await auth().verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // ANDROID ONLY!
        // Sign the user in (or link) with the auto-generated credential
        try {
          await auth().signInWithCredential(credential);

          signInNavigation(context, true);
        } catch (e) {
          print('Phone error: ' + e.toString());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Phone auth error: ' + (e.message ?? 'none'));
      },
      codeSent: (String verificationId, int? resendToken) async {
        await showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Center(child: Text('Enter Verification Code')),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: verificationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: 'SMS Code'),
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Update the UI - wait for the user to enter the SMS code

                      // Create a PhoneAuthCredential with the code
                      PhoneAuthCredential credential =
                          PhoneAuthProvider.credential(
                        verificationId: verificationId,
                        smsCode: verificationController.text,
                      );

                      // Sign the user in (or link) with the credential
                      bool signedIn = await signInWithPhoneNumber(credential);

                      signInNavigation(context, signedIn);
                    },
                    child: Text('Submit'),
                  ),
                )
              ],
            );
          },
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('Auto retrieval timeout: ' + verificationId);
      },
    );
  }

  Future<bool> signInWithPhoneNumber(PhoneAuthCredential credential) async {
    try {
      await auth().signInWithCredential(credential);

      return true;
    } catch (e) {
      print('Phone sign in error: ' + e.toString());

      return false;
    }
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    // Trigger the authentication flow
    final googleUser = await GoogleSignIn().signIn();

    try {
      // Obtain the auth details from the request
      final googleAuth = await googleUser?.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      await auth().signInWithCredential(credential);

      return true;
    } catch (e) {
      GetIt.instance.get<ToastService>().showSnackbar(context, e.toString());
      return false;
    }
  }

  Future<bool> signInWithFacebook(BuildContext context) async {
    // Trigger the sign-in flow
    final result = await FacebookAuth.instance.login();

    try {
      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.token);
      await auth().signInWithCredential(facebookAuthCredential);
      return true;
    } catch (e) {
      GetIt.instance.get<ToastService>().showSnackbar(context, e.toString());
      return false;
    }

    return true;
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> signInWithApple() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    try {
      await auth().signInWithCredential(oauthCredential);

      return true;
    } catch (e) {
      print('error: ' + e.toString());

      return false;
    }
  }

  /// Returns true if sign in was successful
  /*Future<bool> signInWithMicrosoft() async {
    User? user = await signInWithOAuth(provider: 'microsoft.com', scopes: [
      "email"
    ], parameters: {
      "locale": "en",
      'tenant': microsoftTenant,
    });

    /// Successfully authenticated with Microsoft
    return (user != null) ? true : false;
  }*/

  /// Generic method for signing in with an OAuth provider
  Future<User?> signInWithOAuth({
    required String provider,
    List<String>? scopes,
    Map<String, String>? parameters,
  }) async {
   /* try {
      User? user = await FirebaseAuthOAuth()
          .openSignInFlow(provider, scopes!, parameters);
      return user;
    } on PlatformException catch (error) {
      *//**
       * The plugin has the following error codes:
       * 1. FirebaseAuthError: FirebaseAuth related error
       * 2. PlatformError: An platform related error
       * 3. PluginError: An error from this plugin
       *//*
      debugPrint("$provider error - ${error.code}: ${error.message}");
      return null;
    }*/
  }

  Future<void> signInNavigation(BuildContext context, bool signedIn) async {
    if (signedIn) {
      await GetIt.instance.get<NavigationServiceInterface>().backToDecisionView();
      //Get.toAndPopUntil(DecisionViewRoute(), predicate: (route) => false);
    } else {
      GetIt.instance.get<ToastService>().showToast('That didn\'t work, try again later');
    }
  }

  Future<void> resetPassword(String email) async {
    await auth().sendPasswordResetEmail(email: email);
  }
}
