import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required int id,
    required String name,
    required DateTime createdAt,
  }) : super(
    id: id,
    name: name,
    createdAt: createdAt,
  );

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}