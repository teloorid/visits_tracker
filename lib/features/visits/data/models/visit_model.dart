import '../../domain/entities/visit.dart';

class VisitModel extends Visit {
  const VisitModel({
    required super.id,
    required super.customerId,
    required super.visitDate,
    required super.status,
    required super.location,
    required super.notes,
    super.activitiesDoneIds, // <--- Make this nullable in the constructor call
    super.createdAt, // <--- Make this nullable in the constructor call
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    // Handle potential null for 'created_at' as well
    final createdAtString = json['created_at'] as String?;
    final createdAt = createdAtString != null ? DateTime.parse(createdAtString) : null;

    // Handle potential null for 'activities_done'
    List<int>? parsedActivitiesDoneIds;
    final dynamic rawActivitiesDone = json['activities_done']; // It could be null, List<dynamic>, or even a String if malformed

    if (rawActivitiesDone != null) {
      if (rawActivitiesDone is List) {
        // Now, this is the tricky part where we need to be very robust
        final List<int> tempIds = [];
        for (final item in rawActivitiesDone) {
          try {
            // Attempt to parse directly if it's already an int (less likely from JSON)
            if (item is int) {
              tempIds.add(item);
            } else if (item is String) {
              // This handles "7" or "9"
              tempIds.add(int.parse(item));
            }
          } catch (e) {
            // This catches the error for malformed strings like "[9" or "26]"
            print('Error parsing activities_done item: "$item" Error: $e');
            // Attempt to extract numbers from the malformed string
            final String cleanString = item.toString().replaceAll(RegExp(r'[\[\]"]'), ''); // Remove brackets and quotes
            try {
              final int? cleanedId = int.tryParse(cleanString);
              if (cleanedId != null) {
                tempIds.add(cleanedId);
              } else {
                print('Failed to parse cleaned activities_done item: "$cleanString"');
              }
            } catch (e2) {
              print('Critical error on second attempt to parse activities_done item: "$cleanString" Error: $e2');
            }
          }
        }
        if (tempIds.isNotEmpty) {
          parsedActivitiesDoneIds = tempIds;
        }
      } else {
        // Log if activities_done is not a list when it shouldn't be
        print('Warning: activities_done is not a list in JSON: ${rawActivitiesDone.runtimeType} - $rawActivitiesDone');
        // You might want to try parsing it as a single string containing comma-separated values
        // For example, if it comes as "1,2,3" or "[1,2,3]"
        if (rawActivitiesDone is String) {
          final String cleanString = rawActivitiesDone.replaceAll(RegExp(r'[\[\]"]'), '');
          final parts = cleanString.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();
          if (parts.isNotEmpty) {
            parsedActivitiesDoneIds = parts;
          } else {
            print('Warning: activities_done string could not be parsed: $rawActivitiesDone');
          }
        }
      }
    }


    return VisitModel(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      visitDate: DateTime.parse(json['visit_date'] as String),
      status: json['status'] as String,
      location: json['location'] as String,
      notes: json['notes'] as String,
      activitiesDoneIds: parsedActivitiesDoneIds, // Use the potentially null list
      createdAt: createdAt, // Use the potentially null DateTime
    );
  }

  // toJson, fromEntity, and toNewVisitJson methods remain mostly the same,
  // but ensure they handle `activitiesDoneIds` and `createdAt` being nullable if needed.
  // The toJson still converts to string list, which is correct for Supabase array of text.

  @override // Add override for consistency as it extends Equatable
  List<Object?> get props => [
    super.id,
    super.customerId,
    super.visitDate,
    super.status,
    super.location,
    super.notes,
    super.activitiesDoneIds, // Use super. for consistency if you've done it elsewhere
    super.createdAt,
  ];


  // ... rest of your methods (toJson, fromEntity, toNewVisitJson)
  // Ensure toJson handles potentially null activitiesDoneIds for safety, though it should be a List<int>
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'visit_date': visitDate.toIso8601String(),
      'status': status,
      'location': location,
      'notes': notes,
      // Ensure this handles null if activitiesDoneIds could be null before sending
      'activities_done': activitiesDoneIds?.map((e) => e.toString()).toList(),
      'created_at': createdAt?.toIso8601String(), // Handle null createdAt
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
      'activities_done': activitiesDoneIds?.map((e) => e.toString()).toList(), // Handle null here too
    };
  }
}