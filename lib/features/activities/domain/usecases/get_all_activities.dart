import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/activity.dart';
import '../repositories/activity_repository.dart';

class GetAllActivities implements UseCase<List<Activity>, NoParams> {
  final ActivityRepository repository;

  GetAllActivities(this.repository);

  @override
  Future<Either<Failure, List<Activity>>> call(NoParams params) async {
    return await repository.getAllActivities();
  }
}