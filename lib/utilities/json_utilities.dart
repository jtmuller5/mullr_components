import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:mullr_components/services/security_service.dart';

DateTime? getDateFromTimestamp(dynamic timestamp) {
  if(timestamp.runtimeType == Timestamp) {
    return timestamp != null ? timestamp.toDate() : null;
  } else if(timestamp.runtimeType == int){
    return DateTime.fromMicrosecondsSinceEpoch(timestamp);
  } else{
    return null;
  }
}

Timestamp? getTimestampFromDate(DateTime? dateTime) {
  return dateTime != null ? Timestamp.fromDate(dateTime) : null;
}

List<DateTime>? getDateListFromTimestampList(List<Timestamp>? timestamps) {
  return timestamps != null ? timestamps.map((e) => e.toDate()).toList() : null;
}

List<Timestamp>? getTimestampListFromDateList(List<DateTime>? dates) {
  return dates != null ? dates.map((e) => Timestamp.fromDate(e)).toList() : null;
}

String? getIdFromRef(dynamic ref){
  if(ref != null && ref != '') {
    print('Ref: ' +ref.toString());
    print('Ref id: ' +ref.id.toString());
    return ref.id;
  }
}

/// TODO add collection parameter
DocumentReference? getRefFromId(String? id){
  if(id != null && id != '') {
    return FirebaseFirestore.instance.collection('fl_content').doc(id);
  }
}

/// All data that needs to be encrypted should be stored in string format and
/// then decrypted into it's original format
/// TODO encrypt server data with app's public key
String? encryptString(String? string) {
  if (string != null) {
    return GetIt.instance.get<SecurityService>().encrypter?.encrypt(string).base64 ?? 'No encrypter';
  }
}

String? decryptString(String? string) {
  if (string != null) {
    return GetIt.instance.get<SecurityService>().encrypter?.decrypt64(string) ?? 'No encrypter';
  }
}

String? encryptDouble(double? dub){
  if (dub != null) {
    return GetIt.instance.get<SecurityService>().encrypter?.encrypt(dub.toStringAsFixed(2)).base64 ?? 'No encrypter';
  }
}

double? decryptDouble(String? dub){
  if (dub != null) {
    String? decrypted = GetIt.instance.get<SecurityService>().encrypter?.decrypt64(dub);
    if(decrypted != null){
      return double.tryParse(decrypted);
    } else{
      return null;
    }
  }
}

String? encryptDateTime(DateTime? dateTime){
  if (dateTime != null) {
    return GetIt.instance.get<SecurityService>().encrypter?.encrypt(dateTime.toString()).base64 ?? 'No encrypter';
  }
}

DateTime? decryptDateTime(String? dateTime){
  if (dateTime != null) {
    try {
      DateTime? dob = DateTime.tryParse(GetIt.instance.get<SecurityService>().encrypter?.decrypt64(dateTime.toString()) ?? 'No encrypter');
      return dob;
    } catch(e){
      print('Error decrypting DOB: ' + e.toString());
    }
  }
}
