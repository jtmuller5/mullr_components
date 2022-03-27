import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

DateTime? getDateFromTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp != null ? timestamp.toDate() : null;
  } else if (timestamp is int) {
    return DateTime.fromMicrosecondsSinceEpoch(timestamp);
  } else if (timestamp.runtimeType == String) {
    return DateTime.parse(timestamp);
  } else {
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

String? getIdFromRef(dynamic ref) {
  if (ref != null && ref != '') {
    print('Ref: ' + ref.toString());
    print('Ref id: ' + ref.id.toString());
    return ref.id;
  }
}

/// TODO add collection parameter
DocumentReference? getRefFromId(String? id) {
  if (id != null && id != '') {
    return FirebaseFirestore.instance.collection('fl_content').doc(id);
  }
}
