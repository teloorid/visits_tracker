import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/visit.dart';
import '../repositories/visit_repository.dart';

class AddVisit implements UseCase<Visit, AddVisitParams> {
  final VisitRepository repository;

  AddVisit(this.repository);

  @override
  Future<Either<Failure, Visit>> call(AddVisitParams params) async {
    final newVisit = Visit(
      id: 0, // ID will be assigned by backend
      customerId: params.customerId,
      visitDate: params.visitDate,
      status: params.status,
      location: params.location,
      notes: params.notes,
      activitiesDoneIds: params.activitiesDoneIds,
      createdAt: DateTime.now().toUtc(), // Will be updated by backend
    );
    return await repository.addVisit(newVisit);
  }
}

class AddVisitParams extends Equatable {
  final int customerId;
  final DateTime visitDate;
  final String status;
  final String location;
  final String notes;
  final List<int> activitiesDoneIds;

  const AddVisitParams({
    required this.customerId,
    required this.visitDate,
    required this.status,
    required this.location,
    required this.notes,
    required this.activitiesDoneIds,
  });

  @override
  List<Object?> get props => [
    customerId,
    visitDate,
    status,
    location,
    notes,
    activitiesDoneIds,
  ];
}