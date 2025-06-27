import 'package:equatable/equatable.dart';

class Visit extends Equatable {
  final int id;
  final int customerId;
  final DateTime visitDate;
  final String status;
  final String location;
  final String notes;
  final List<int>? activitiesDoneIds; // Store IDs here
  final DateTime? createdAt;

  const Visit({
    required this.id,
    required this.customerId,
    required this.visitDate,
    required this.status,
    required this.location,
    required this.notes,
    this.activitiesDoneIds,
    this.createdAt,
  });

  // Factory constructor to create a Visit object from a JSON Map
  factory Visit.fromJson(Map<String, dynamic> json) {
    // Helper function to parse DateTime from various formats or return a default
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          // Log or handle parsing error if necessary
          print('Error parsing date: $value - $e');
          return null; // Return null or a default date on error
        }
      }
      // If it's already a DateTime object, return it (unlikely from JSON directly)
      if (value is DateTime) return value;
      return null;
    }

    // Robust parsing for activitiesDoneIds
    List<int> parsedActivitiesDoneIds = [];
    final dynamic rawActivitiesDone = json['activities_done'];

    if (rawActivitiesDone != null) {
      if (rawActivitiesDone is List) {
        for (final item in rawActivitiesDone) {
          if (item is int) {
            parsedActivitiesDoneIds.add(item);
          } else if (item is List) {
            // Handle nested lists of integers
            for (final nestedItem in item) {
              if (nestedItem is int) {
                parsedActivitiesDoneIds.add(nestedItem);
              }
            }
          }
          // If it's neither an int nor a list, ignore or log a warning
        }
      }
      // If rawActivitiesDone is a String that contains IDs, you might need
      // more complex regex parsing here, but based on logs, it's mostly list.
      // Example for string parsing (if needed, based on the partial log line):
      // if (rawActivitiesDone is String) {
      //   final regex = RegExp(r'\[(\d+(?:,\s*\d+)*)\]');
      //   final match = regex.firstMatch(rawActivitiesDone);
      //   if (match != null) {
      //     final idsString = match.group(1);
      //     if (idsString != null && idsString.isNotEmpty) {
      //       parsedActivitiesDoneIds.addAll(idsString.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((id) => id != 0));
      //     }
      //   }
      // }
    }


    return Visit(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      visitDate: parseDateTime(json['visit_date']) ?? DateTime.now(), // Provide a default if parsing fails
      status: json['status'] as String,
      location: json['location'] as String,
      notes: json['notes'] as String,
      activitiesDoneIds: parsedActivitiesDoneIds,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(), // Provide a default if parsing fails
    );
  }

  // Method to convert a Visit object to a JSON Map (useful for sending data back to API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'visit_date': visitDate.toIso8601String(),
      'status': status,
      'location': location,
      'notes': notes,
      'activities_done': activitiesDoneIds, // Send as List<int>
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    visitDate,
    status,
    location,
    notes,
    activitiesDoneIds,
    createdAt,
  ];
}