import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/visit.dart';
import '../../domain/repositories/visit_repository.dart';
import '../datasources/visit_remote_data_source.dart';
import '../datasources/visit_local_data_source.dart'; // Import local data source
import '../models/visit_model.dart'; // Import VisitModel

class VisitRepositoryImpl implements VisitRepository {
  final VisitRemoteDataSource remoteDataSource;
  final VisitLocalDataSource localDataSource;

  VisitRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Visit>>> getAllVisits() async {
    // Offline-first strategy for reads:
    // 1. Try to get data from local cache first.
    // 2. If cache is empty or fails, try to fetch from remote.
    // 3. If remote is successful, cache the data.
    // 4. If remote also fails (e.g., no internet), return NetworkFailure.
    try {
      final localVisits = await localDataSource.getAllVisitsFromCache();
      return Right(localVisits); // Return cached data immediately if available
    } on CacheException {
      // Cache is empty or failed, try fetching from remote
      try {
        final remoteVisits = await remoteDataSource.getAllVisits();
        await localDataSource.cacheVisits(remoteVisits); // Cache newly fetched data
        return Right(remoteVisits);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: 'An unexpected error occurred while fetching visits: $e'));
      }
    } on NetworkException catch (e) {
      // This catch is primarily for network issues detected during the initial remote fetch
      // if it somehow wasn't caught by the inner try-catch.
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'An unknown error occurred in getAllVisits: $e'));
    }
  }

  @override
  Future<Either<Failure, Visit>> addVisit(Visit visit) async {
    try {
      final visitModel = VisitModel.fromEntity(visit); // Convert entity to model
      final newVisitModel = await remoteDataSource.addVisit(visitModel);

      // On successful remote add, re-cache all visits to ensure local data is up-to-date
      // This is a simple approach. For complex apps, you might just add the newVisitModel to cache.
      final updatedRemoteVisits = await remoteDataSource.getAllVisits();
      await localDataSource.cacheVisits(updatedRemoteVisits);

      return Right(newVisitModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException {
      // For offline adding:
      // If the network fails, save the visit to a "pending" box and return success for the UI
      // (as it's "saved" locally, but not synced).
      final visitModel = VisitModel.fromEntity(visit);
      try {
        await localDataSource.addPendingVisit(visitModel);
        // You might want to return a different kind of "success" or
        // a specific OfflineSuccess state here for the UI.
        // For now, we'll return a NetworkFailure but with a note that it's saved locally.
        return Left(NetworkFailure(message: 'Visit saved locally, will sync when online.'));
      } on CacheException catch (cacheE) {
        // If even local saving fails
        return Left(CacheFailure(message: 'Failed to save visit locally: ${cacheE.message}'));
      }
    } catch (e) {
      return Left(UnexpectedFailure(message: 'An unexpected error occurred while adding visit: $e'));
    }
  }
}