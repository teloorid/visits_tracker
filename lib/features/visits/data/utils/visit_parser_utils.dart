import '../models/visit_model.dart'; // Import VisitModel

/// A top-level function to parse a list of JSON maps into a list of VisitModel objects.
/// This function is designed to be run in an Isolate using Flutter's `compute` function.
List<VisitModel> parseVisitsList(List<dynamic> jsonData) {
  return jsonData.map((json) => VisitModel.fromJson(json as Map<String, dynamic>)).toList();
}

/// A top-level function to parse a single JSON map into a VisitModel object.
/// This function is designed to be run in an Isolate using Flutter's `compute` function.
VisitModel parseSingleVisit(Map<String, dynamic> jsonData) {
  return VisitModel.fromJson(jsonData);
}