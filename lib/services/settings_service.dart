import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mullr_components/models/user_settings.dart';
import 'package:mullr_components/services/user_service.dart';

class SettingsService {

  UserSettings? userSettings() {
    final userService = GetIt.instance.get<UserService>();
    return userService.uid != null
        ? Hive.box<UserSettings>('userSettings').get(userService.uid)
        : null;
  }

  static UserSettings defaultSettings = UserSettings(
    multiDevice: false,
    preferredContactMethod: 'phone',
    topics: [
      'new_entities',
    ],
    biometrics: false,
  );

  /// Default settings for a new user
  /// systems == imperial or metric
  void createNewUserSettings() {
    UserSettings userSettings = defaultSettings;

    updateSettings(userSettings);

    FirebaseFirestore.instance
        .collection('user-settings')
        .doc(GetIt.instance.get<UserService>().uid)
        .set(userSettings.toJson());
  }

  /// Update settings locally with the option of updating Firestore as well
  Future<void> updateSettings(UserSettings userSettings,
      {bool sync = false}) async {
    await Hive.box<UserSettings>('userSettings')
        .put(GetIt.instance.get<UserService>().uid, userSettings);

    if (sync) await updateSettingsInFirestore(userSettings);
  }

  /// Update exisitng settings document
  Future<void> updateSettingsInFirestore(UserSettings userSettings) async {
    await FirebaseFirestore.instance
        .collection('user-settings')
        .doc(GetIt.instance.get<UserService>().uid)
        .update(userSettings.toJson());
  }

  Future<void> loadSettings({required String userId}) async {
    DocumentSnapshot settingsSnap = await FirebaseFirestore.instance
        .collection('user-settings')
        .doc(userId)
        .get();

    if (settingsSnap.exists && settingsSnap.data() != null) {
      UserSettings userSettings =
          UserSettings.fromJson(settingsSnap.data() as Map<String, dynamic>);

      updateSettings(userSettings);
    }
  }
}
