import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/visit.dart';
import '../repositories/visit_repository.dart';

class GetAllVisits implements UseCase<List<Visit>, NoParams> {
  final VisitRepository repository;

  GetAllVisits(this.repository);

  @override
  Future<Either<Failure, List<Visit>>> call(NoParams params) async {
    return await repository.getAllVisits();
  }
}