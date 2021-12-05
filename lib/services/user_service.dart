// Class to hold the user's workout related information
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:mullr_components/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:stacked/stacked.dart';

class UserService with ReactiveServiceMixin {
  /// ID used for video calling with Agora, set by SDK
  int? agoraUid;

  User? tempUser;

  String? get uid {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  User? get user {
    if (uid != null) return Hive.box<User>('users').get(uid);
  }

  /// Default structure for a new user
  /// Used to add a user with a Firebase account to Hive after successful Firebase login
  Future<void> createNewUser() async {

    String? currentDeviceId;

    // Get the current device ID
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();

    if (Platform.isAndroid) {
      var build = await deviceInfoPlugin.androidInfo;
      currentDeviceId = build.androidId; //UUID for Android
    } else if (Platform.isIOS) {
      var data = await deviceInfoPlugin.iosInfo;
      currentDeviceId = data.identifierForVendor; //UUID for iOS
    }

    // Updates user in hive
    if (tempUser != null) {
      tempUser?.firebaseId = uid;
    } else {
      tempUser = User(
          firebaseId: uid,
          firstName: 'Test',
          lastName: 'Test',
          email: 'test@test.com',
          dob: DateTime.now().subtract(Duration(days: 365 * 20)),
          groupNumber: '1234',
          insuranceCarrier: 'carrier',
          phoneNumber: '111-222-3333',
          memberId: '1234',
          onboardingComplete: false);
    }

    tempUser!.creation = DateTime.now();
    tempUser!.lastDeviceId = currentDeviceId;
    await updateUser(tempUser!);

    // Save's encrypted user data to Firestore
    await saveUserToFirestore(tempUser!);
    await updateLastDevice(userId: FirebaseAuth.instance.currentUser!.uid);
  }

  /// Create a temporary user that will be updated during onboarding
  /// The values from this user will be used to update Firestore when an account is eventually created
  void createTempUser({bool dev = true}) {
    if (!dev) {
      tempUser = User(onboardingComplete: false);
    } else {
      tempUser = User(
          firstName: 'Test',
          lastName: 'Test',
          email: 'test@test.com',
          dob: DateTime.now().subtract(Duration(days: 365 * 20)),
          groupNumber: '1234',
          insuranceCarrier: 'carrier',
          phoneNumber: '111-222-3333',
          memberId: '1234',
          onboardingComplete: false);
    }
  }

  /// Load user from Firestore
  /// Compare the current device ID to the last device ID this user used
  /// If last device == this device, no syncing
  /// If last device != this device, perform any larger syncing operations
  Future<void> loadUser(
      {required String userId,
      required BuildContext context,
      required Widget recoveryRoute}) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists && userSnapshot.data() != null) {
      // TODO double check this doesn't break (fromJson)
      User? thisUser =
          User.fromJsonAbbrev(userSnapshot.data() as Map<String, dynamic>);
      await updateUser(thisUser);

      print('Initial last device: ' + (thisUser.lastDeviceId ?? 'Dev'));
      bool? sameDevice =
          await sameDeviceAsLastLogin(lastDeviceId: thisUser.lastDeviceId);

      // User hasn't logged in before
      if (sameDevice == null) {
        print('No previous device, updating Firestore');
        // No syncing, update last ID the first time they log in
        await updateLastDevice(userId: FirebaseAuth.instance.currentUser!.uid);
      } else {
        // No syncing
        if (sameDevice) {
          // Load full user
          print('Detected same device, loading full user');
          User? thisUser =
              User.fromJson(userSnapshot.data() as Map<String, dynamic>);
          thisUser.lastLogin = DateTime.now();
          await saveUserToFirestore(thisUser);
          await updateUser(thisUser);
        }
        // Perform user check (request recovery password)
       /* else {
          // The user has encrypted data stored on Firestore
          if (thisUser.hashedPassword != null) {
            print('Multi-device was enabled, check for passphrase');
            // recoveryRoute.copyWith(params: {'enabled': true});
            await GetIt.instance.get<NavigationServiceInterface>().goToRecovery();
          }
          // No encrypted data stored, multi-device was not enabled
          else {
            // recoveryRoute.copyWith(params: {'enabled': false});
            print('Multi-device was not enabled, inform user');
            await GetIt.instance.get<NavigationServiceInterface>().goToRecovery();
          }
        }*/
      }
    } else {
      print('No user exists');
      //await updateLastDevice(userId: FirebaseAuth.instance.currentUser!.uid);
      //await GetIt.instance.get<AuthService>().signOut();
      //await GetIt.instance.get<NavigationServiceInterface>().backToDecisionView();
    }
  }

  /// Add the newest device ID to this users Firestore document
  Future<void> updateLastDevice({required String userId, bool firestore = true}) async {
    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId);

    String? currentDeviceId;

    // Get the current device ID
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();

    if (Platform.isAndroid) {
      var build = await deviceInfoPlugin.androidInfo;
      currentDeviceId = build.androidId; //UUID for Android
    } else if (Platform.isIOS) {
      var data = await deviceInfoPlugin.iosInfo;
      currentDeviceId = data.identifierForVendor; //UUID for iOS
    }

    if(firestore) await userDoc.update({'lastDeviceId': currentDeviceId});
  }

  /// Utility function to check device equality
  /// Comparing device ID stored in Firestore to device ID of current device
  /// Mainly would be used if there are bulky syncing functions we need to run on a new device
  Future<bool?> sameDeviceAsLastLogin({required String? lastDeviceId}) async {
    String? currentDeviceId;

    // Get the current device ID
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();

    if (Platform.isAndroid) {
      var build = await deviceInfoPlugin.androidInfo;
      currentDeviceId = build.androidId; //UUID for Android
    } else if (Platform.isIOS) {
      var data = await deviceInfoPlugin.iosInfo;
      currentDeviceId = data.identifierForVendor; //UUID for iOS
    }

    // Get the last device ID
    if (lastDeviceId != null) {
      if (lastDeviceId == currentDeviceId) {
        print('Same device as last');
        return true;
      } else {
        print('Different device than last');
        return false;
      }
    } else {
      print('No last device');
      return null;
    }
  }

  Future<void> updateUser(User user) async {
    print('Updating user: ' + (user.firstName ?? 'None'));
    await Hive.box<User>('users').put(uid, user);
  }

  Future<void> saveUserToFirestore(User user) async {
    // User values are encrypted in toJson method
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(user.toJson());
  }

  /// Get the encrypted user object from Firestore
  Future<User?> getUserFromFirebase({required String uid}) async {
    DocumentSnapshot userDocSnap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDocSnap.exists) {
      User decryptedUser =
          User.fromJson(userDocSnap.data()! as Map<String, dynamic>);

      return decryptedUser;
    }
  }

  void updateLastSignIn() {
    FirebaseFirestore.instance.collection('users').doc(uid).update(
      {
        'lastSignIn': FieldValue.serverTimestamp(),
      },
    );
  }

  void setAgoraUid(int? id) {
    agoraUid = id;
  }

  /// Get all accounts linked to this user
  List<String> getLinkedAccounts() {
    List<UserInfo>? userInfo = FirebaseAuth.instance.currentUser?.providerData;

    userInfo?.forEach((info) {
      print('Provider ID: ' + info.providerId);
      print('UID: ' + (info.uid ?? ''));
      print('Display Name: ' + (info.displayName ?? ''));
      print('Photo URL: ' + (info.photoURL ?? ''));
      print('Email: ' + (info.email ?? ''));
      print('Phone Number: ' + (info.phoneNumber ?? ''));
    });

    return userInfo?.map((e) => e.providerId).toList() ?? [];
  }
}
