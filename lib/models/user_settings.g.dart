// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 1;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      multiDevice: fields[0] as bool?,
      biometrics: fields[1] as bool?,
      preferredContactMethod: fields[2] as String?,
      topics: (fields[3] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.multiDevice)
      ..writeByte(1)
      ..write(obj.biometrics)
      ..writeByte(2)
      ..write(obj.preferredContactMethod)
      ..writeByte(3)
      ..write(obj.topics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return UserSettings(
    multiDevice: json['multiDevice'] as bool?,
    biometrics: json['biometrics'] as bool?,
    preferredContactMethod: json['preferredContactMethod'] as String?,
    topics:
        (json['topics'] as List<dynamic>?)?.map((e) => e as String).toList(),
  );
}

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'multiDevice': instance.multiDevice,
      'biometrics': instance.biometrics,
      'preferredContactMethod': instance.preferredContactMethod,
      'topics': instance.topics,
    };
