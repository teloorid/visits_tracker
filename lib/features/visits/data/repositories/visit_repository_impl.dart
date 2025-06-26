import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/visit.dart';
import '../../domain/repositories/visit_repository.dart';
import '../datasources/visit_remote_data_source.dart';
import '../models/visit_model.dart';
import '../datasources/visit_local_data_source.dart';

class VisitRepositoryImpl implements VisitRepository {
  final VisitRemoteDataSource remoteDataSource;
  final VisitLocalDataSource localDataSource;

  VisitRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Visit>>> getAllVisits() async {
    try {
      final remoteVisits = await remoteDataSource.getAllVisits();
      // Optionally, cache remote visits here
      localDataSource.cacheVisits(remoteVisits);
      return Right(remoteVisits);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      // If network fails, try to get from local cache (if implemented)
      try {
        final localVisits = await localDataSource.getAllVisits();
        return Right(localVisits);
      } on CacheException {
        return Left(NetworkFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Visit>> addVisit(Visit visit) async {
    try {
      final newVisit = await remoteDataSource.addVisit(visit as VisitModel);
      return Right(newVisit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      // For offline, save to local and mark as pending sync
      return Left(NetworkFailure(message: e.message));
    }
  }
}