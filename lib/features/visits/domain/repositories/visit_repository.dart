import 'package:dartz/dartz.dart'; // For functional error handling (Either)
import '../../../../core/errors/failures.dart';
import '../entities/visit.dart';

abstract class VisitRepository {
  Future<Either<Failure, List<Visit>>> getAllVisits();
  Future<Either<Failure, Visit>> addVisit(Visit visit);
// Future<Either<Failure, Visit>> updateVisit(Visit visit);
// Future<Either<Failure, void>> deleteVisit(int id);
}