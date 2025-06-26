import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/activity.dart';

abstract class ActivityRepository {
  Future<Either<Failure, List<Activity>>> getAllActivities();
}