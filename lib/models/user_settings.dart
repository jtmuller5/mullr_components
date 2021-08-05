import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_settings.g.dart';

@JsonSerializable()
@HiveType(typeId: 1)
class UserSettings {
  @HiveField(0)
  bool? multiDevice;

  @HiveField(1)
  bool? biometrics;

  @HiveField(2)
  String? preferredContactMethod;

  /// List of FCM topics the user is subscribed to
  @HiveField(3)
  List<String>? topics;

  UserSettings({
    this.multiDevice,
    this.biometrics,
    this.preferredContactMethod,
    this.topics,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => _$UserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);
}
