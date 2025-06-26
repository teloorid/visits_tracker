import '../../domain/entities/visit.dart';

class VisitModel extends Visit {
  const VisitModel({
    required super.id,
    required super.customerId,
    required super.visitDate,
    required super.status,
    required super.location,
    required super.notes,
    required super.activitiesDoneIds, // Still IDs here
    required super.createdAt,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      visitDate: DateTime.parse(json['visit_date'] as String),
      status: json['status'] as String,
      location: json['location'] as String,
      notes: json['notes'] as String,
      // Parse activities_done as a list of integers
      activitiesDoneIds: List<int>.from(json['activities_done'].map((x) => int.parse(x.toString()))),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'visit_date': visitDate.toIso8601String(),
      'status': status,
      'location': location,
      'notes': notes,
      'activities_done': activitiesDoneIds.map((e) => e.toString()).toList(), // Convert to list of strings for API
    };
  }

  // Factory method to convert a domain Entity to a data Model
  factory VisitModel.fromEntity(Visit visit) {
    return VisitModel(
      id: visit.id,
      customerId: visit.customerId,
      visitDate: visit.visitDate,
      status: visit.status,
      location: visit.location,
      notes: visit.notes,
      activitiesDoneIds: visit.activitiesDoneIds,
      createdAt: visit.createdAt,
    );
  }

  // Helper for adding new visits (without ID and createdAt)
  Map<String, dynamic> toNewVisitJson() {
    return {
      'customer_id': customerId,
      'visit_date': visitDate.toIso8601String(),
      'status': status,
      'location': location,
      'notes': notes,
      'activities_done': activitiesDoneIds.map((e) => e.toString()).toList(),
    };
  }
}