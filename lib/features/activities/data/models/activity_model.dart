import '../../domain/entities/activity.dart';

class ActivityModel extends Activity {
  const ActivityModel({
    required int id,
    required String description,
    required DateTime createdAt,
  }) : super(
    id: id,
    description: description,
    createdAt: createdAt,
  );

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as int,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}