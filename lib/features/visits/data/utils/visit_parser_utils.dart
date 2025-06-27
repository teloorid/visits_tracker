import '../models/visit_model.dart'; // Import VisitModel

/// A top-level function to parse a list of JSON maps into a list of VisitModel objects.
/// This function is designed to be run in an Isolate using Flutter's `compute` function.
List<VisitModel> parseVisitsList(List<dynamic> jsonData) {
  return jsonData.map((item) {
    if (item is Map) {
      // Safely convert Map<dynamic, dynamic> (or Map<String, dynamic>) to Map<String, dynamic>
      // by explicitly creating a new map with String keys.
      final Map<String, dynamic> stringKeyedMap = item.map(
            (key, value) => MapEntry(key.toString(), value),
      );
      return VisitModel.fromJson(stringKeyedMap);
    } else {
      // This case indicates malformed data where an item in the list is not a map.
      // You might want to log this or throw a more specific exception.
      throw FormatException('Expected a map object in the visits list, but got ${item.runtimeType}');
    }
  }).toList();
}

/// A top-level function to parse a single JSON map into a VisitModel object.
/// This function is designed to be run in an Isolate using Flutter's `compute` function.
VisitModel parseSingleVisit(Map<String, dynamic> jsonData) {
  // Assuming jsonData passed here is already Map<String, dynamic> due to earlier cast
  // in VisitRemoteDataSourceImpl.addVisit. If you encounter the same error
  // with addVisit, you might need a similar conversion here:
  // final Map<String, dynamic> stringKeyedMap = jsonData.map(
  //   (key, value) => MapEntry(key.toString(), value),
  // );
  // return VisitModel.fromJson(stringKeyedMap);
  return VisitModel.fromJson(jsonData);
}