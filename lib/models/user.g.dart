// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      firstName: fields[0] as String?,
      lastName: fields[1] as String?,
      email: fields[2] as String?,
      phoneNumber: fields[3] as String?,
      dob: fields[4] as DateTime?,
      agreedToTC: fields[5] as bool?,
      memberId: fields[6] as String?,
      creation: fields[12] as DateTime?,
      insuranceCarrier: fields[7] as String?,
      groupNumber: fields[8] as String?,
      firebaseId: fields[9] as String?,
      onboardingComplete: fields[10] as bool?,
      lastDeviceId: fields[13] as String?,
      salt: fields[14] as String?,
      hashedPassword: fields[17] as String?,
      encryptedPrivateKeyPem: fields[16] as String?,
      encryptedPublicKeyPem: fields[15] as String?,
      lastLogin: fields[23] as DateTime?,
    )
      ..sex = fields[18] as String?
      ..nickname = fields[19] as String?
      ..weight = fields[20] as double?
      ..height = fields[21] as double?;
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.firstName)
      ..writeByte(1)
      ..write(obj.lastName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(4)
      ..write(obj.dob)
      ..writeByte(5)
      ..write(obj.agreedToTC)
      ..writeByte(6)
      ..write(obj.memberId)
      ..writeByte(7)
      ..write(obj.insuranceCarrier)
      ..writeByte(8)
      ..write(obj.groupNumber)
      ..writeByte(9)
      ..write(obj.firebaseId)
      ..writeByte(10)
      ..write(obj.onboardingComplete)
      ..writeByte(12)
      ..write(obj.creation)
      ..writeByte(13)
      ..write(obj.lastDeviceId)
      ..writeByte(14)
      ..write(obj.salt)
      ..writeByte(15)
      ..write(obj.encryptedPublicKeyPem)
      ..writeByte(16)
      ..write(obj.encryptedPrivateKeyPem)
      ..writeByte(17)
      ..write(obj.hashedPassword)
      ..writeByte(18)
      ..write(obj.sex)
      ..writeByte(19)
      ..write(obj.nickname)
      ..writeByte(20)
      ..write(obj.weight)
      ..writeByte(21)
      ..write(obj.height)
      ..writeByte(23)
      ..write(obj.lastLogin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
    firstName: decryptString(json['firstName'] as String?),
    lastName: decryptString(json['lastName'] as String?),
    email: decryptString(json['email'] as String?),
    phoneNumber: decryptString(json['phoneNumber'] as String?),
    dob: decryptDateTime(json['dob'] as String?),
    agreedToTC: json['agreedToTC'] as bool?,
    memberId: decryptString(json['memberId'] as String?),
    creation: getDateFromTimestamp(json['creation'] as Timestamp?),
    insuranceCarrier: decryptString(json['insuranceCarrier'] as String?),
    groupNumber: decryptString(json['groupNumber'] as String?),
    firebaseId: json['firebaseId'] as String?,
    onboardingComplete: json['onboardingComplete'] as bool?,
    lastDeviceId: json['lastDeviceId'] as String?,
    salt: json['salt'] as String?,
    hashedPassword: json['hashedPassword'] as String?,
    encryptedPrivateKeyPem: json['encryptedPrivateKeyPem'] as String?,
    encryptedPublicKeyPem: json['encryptedPublicKeyPem'] as String?,
    lastLogin: getDateFromTimestamp(json['lastLogin'] as Timestamp?),
  )
    ..sex = json['sex'] as String?
    ..nickname = decryptString(json['nickname'] as String?)
    ..weight = decryptDouble(json['weight'] as String?)
    ..height = decryptDouble(json['height'] as String?);
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'firstName': encryptString(instance.firstName),
      'lastName': encryptString(instance.lastName),
      'email': encryptString(instance.email),
      'phoneNumber': encryptString(instance.phoneNumber),
      'dob': encryptDateTime(instance.dob),
      'agreedToTC': instance.agreedToTC,
      'memberId': encryptString(instance.memberId),
      'insuranceCarrier': encryptString(instance.insuranceCarrier),
      'groupNumber': encryptString(instance.groupNumber),
      'firebaseId': instance.firebaseId,
      'onboardingComplete': instance.onboardingComplete,
      'creation': getTimestampFromDate(instance.creation),
      'lastDeviceId': instance.lastDeviceId,
      'salt': instance.salt,
      'encryptedPublicKeyPem': instance.encryptedPublicKeyPem,
      'encryptedPrivateKeyPem': instance.encryptedPrivateKeyPem,
      'hashedPassword': instance.hashedPassword,
      'sex': instance.sex,
      'nickname': encryptString(instance.nickname),
      'weight': encryptDouble(instance.weight),
      'height': encryptDouble(instance.height),
      'lastLogin': getTimestampFromDate(instance.lastLogin),
    };
