import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import 'package:json_annotation/json_annotation.dart';
import 'package:mullr_components/utilities/json_utilities.dart';

part 'user.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: 0)
class User extends HiveObject {
  @JsonKey(fromJson: decryptString, toJson: encryptString)
  @HiveField(0)
  String? firstName;

  @JsonKey(fromJson: decryptString, toJson: encryptString)
  @HiveField(1)
  String? lastName;

  @JsonKey(fromJson: decryptString, toJson: encryptString)
  @HiveField(2)
  String? email;

  @JsonKey(fromJson: decryptString, toJson: encryptString)
  @HiveField(3)
  String? phoneNumber;

  /// Date of birth, stored in compact form MM/DD/YYYY (encrypted in Firestore)
  @JsonKey(fromJson: decryptDateTime, toJson: encryptDateTime)
  @HiveField(4)
  DateTime? dob;

  @HiveField(5)
  bool? agreedToTC;

  /// Insurance fields
  @JsonKey(fromJson: decryptString, toJson: encryptString)
  @HiveField(6)
  String? memberId;

  @JsonKey(fromJson: decryptString, toJson: encryptString)
  @HiveField(7)
  String? insuranceCarrier;

  @JsonKey(fromJson: decryptString, toJson: encryptString)
  @HiveField(8)
  String? groupNumber;

  @HiveField(9)
  String? firebaseId;

  @HiveField(10)
  bool? onboardingComplete;

  @HiveField(12)
  @JsonKey(fromJson: getDateFromTimestamp, toJson: getTimestampFromDate)
  DateTime? creation;

  @HiveField(13)
  String? lastDeviceId;

  /// The random salt generated when the user enables multi-device
  @HiveField(14)
  String? salt;

  @HiveField(15)
  String? encryptedPublicKeyPem;

  @HiveField(16)
  String? encryptedPrivateKeyPem;

  @HiveField(17)
  String? hashedPassword;

  @HiveField(18)
  String? sex;

  @JsonKey(fromJson: decryptString, toJson: encryptString)
  @HiveField(19)
  String? nickname;

  /// Weight in metric (kg)
  @JsonKey(fromJson: decryptDouble, toJson: encryptDouble)
  @HiveField(20)
  double? weight;

  /// Height in metric (cm)
  @JsonKey(fromJson: decryptDouble, toJson: encryptDouble)
  @HiveField(21)
  double? height;

  @HiveField(23)
  @JsonKey(fromJson: getDateFromTimestamp, toJson: getTimestampFromDate)
  DateTime? lastLogin;

  User({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.dob,
    this.agreedToTC,
    this.memberId,
    this.creation,
    this.insuranceCarrier,
    this.groupNumber,
    this.firebaseId,
    this.onboardingComplete,
    this.lastDeviceId,
    this.salt,
    this.hashedPassword,
    this.encryptedPrivateKeyPem,
    this.encryptedPublicKeyPem,
    this.lastLogin,
  });

  User.fromJsonAbbrev(Map<String, dynamic> json) {
    this.lastDeviceId = json['lastDeviceId'];
    this.hashedPassword = json['hashedPassword'];
    this.salt = json['salt'];
    this.encryptedPublicKeyPem = json['encryptedPublicKeyPem'];
    this.encryptedPrivateKeyPem = json['encryptedPrivateKeyPem'];
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
