import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/visit.dart';
import '../../domain/repositories/visit_repository.dart';
import '../datasources/visit_remote_data_source.dart';
import '../datasources/visit_local_data_source.dart';
import '../models/visit_model.dart';

class VisitRepositoryImpl implements VisitRepository {
  final VisitRemoteDataSource remoteDataSource;
  final VisitLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  VisitRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Visit>>> getAllVisits() async {
    // Enhanced offline-first strategy with network awareness:
    // 1. Always try to get cached data first for immediate response
    // 2. If online and cache is stale/empty, fetch from remote and update cache
    // 3. If offline, return cached data or appropriate error

    try {
      // First, try to get cached data
      final localVisits = await localDataSource.getAllVisitsFromCache();

      // If we have cached data and we're online, try to refresh it in background
      if (await networkInfo.isConnected) {
        try {
          final remoteVisits = await remoteDataSource.getAllVisits();
          await localDataSource.cacheVisits(remoteVisits);
          return Right(remoteVisits); // Return fresh data
        } on ServerException {
          // Remote failed but we have cached data, return cached data
          return Right(localVisits);
        } on NetworkException {
          // Network issues but we have cached data, return cached data
          return Right(localVisits);
        } catch (e) {
          // Unexpected error with remote, but we have cached data
          return Right(localVisits);
        }
      } else {
        // Offline but we have cached data
        return Right(localVisits);
      }

    } on CacheException {
      // No cached data available, try remote if online
      if (await networkInfo.isConnected) {
        try {
          final remoteVisits = await remoteDataSource.getAllVisits();
          await localDataSource.cacheVisits(remoteVisits);
          return Right(remoteVisits);
        } on ServerException catch (e) {
          return Left(ServerFailure(message: e.message));
        } on NetworkException catch (e) {
          return Left(NetworkFailure(message: e.message));
        } catch (e) {
          return Left(UnexpectedFailure(message: 'An unexpected error occurred while fetching visits: $e'));
        }
      } else {
        // Offline and no cached data
        return Left(NetworkFailure(message: 'No internet connection and no cached data available'));
      }
    } catch (e) {
      return Left(UnexpectedFailure(message: 'An unknown error occurred in getAllVisits: $e'));
    }
  }

  @override
  Future<Either<Failure, Visit>> addVisit(Visit visit) async {
    final visitModel = VisitModel.fromEntity(visit);

    // Check network connectivity before attempting remote operations
    if (await networkInfo.isConnected) {
      try {
        // Online: Try to add to remote first
        final newVisitModel = await remoteDataSource.addVisit(visitModel);

        // On successful remote add, update local cache
        try {
          final updatedRemoteVisits = await remoteDataSource.getAllVisits();
          await localDataSource.cacheVisits(updatedRemoteVisits);
        } catch (e) {
          // If cache update fails, log it but don't fail the whole operation
          // The visit was successfully added remotely
          print('Warning: Failed to update local cache after adding visit: $e');
        }

        return Right(newVisitModel);

      } on ServerException catch (e) {
        // Server error while online - save locally as pending
        try {
          await localDataSource.addPendingVisit(visitModel);
          return Left(ServerFailure(message: '${e.message}. Visit saved locally and will sync when server is available.'));
        } on CacheException catch (cacheE) {
          return Left(ServerFailure(message: '${e.message}. Also failed to save locally: ${cacheE.message}'));
        }

      } on NetworkException catch (e) {
        // Network error while supposedly online - save as pending
        try {
          await localDataSource.addPendingVisit(visitModel);
          return Left(NetworkFailure(message: '${e.message}. Visit saved locally and will sync when connection is stable.'));
        } on CacheException catch (cacheE) {
          return Left(NetworkFailure(message: '${e.message}. Also failed to save locally: ${cacheE.message}'));
        }

      } catch (e) {
        // Unexpected error - try to save locally
        try {
          await localDataSource.addPendingVisit(visitModel);
          return Left(UnexpectedFailure(message: 'Unexpected error: $e. Visit saved locally and will sync later.'));
        } on CacheException catch (cacheE) {
          return Left(UnexpectedFailure(message: 'Unexpected error: $e. Also failed to save locally: ${cacheE.message}'));
        }
      }
    } else {
      // Offline: Save to pending visits for later sync
      try {
        await localDataSource.addPendingVisit(visitModel);
        return Left(NetworkFailure(message: 'No internet connection. Visit saved locally and will sync when online.'));
      } on CacheException catch (cacheE) {
        return Left(CacheFailure(message: 'No internet connection and failed to save visit locally: ${cacheE.message}'));
      } catch (e) {
        return Left(UnexpectedFailure(message: 'No internet connection and unexpected error saving locally: $e'));
      }
    }
  }

  /// Optional: Method to sync pending visits when connection is restored
  Future<Either<Failure, int>> syncPendingVisits() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection for syncing'));
    }

    try {
      final pendingVisits = await localDataSource.getPendingVisits();
      int syncedCount = 0;

      for (final visit in pendingVisits) {
        try {
          await remoteDataSource.addVisit(visit);
          await localDataSource.removePendingVisit(visit);
          syncedCount++;
        } catch (e) {
          // Continue with other visits if one fails
          print('Failed to sync visit ${visit.id}: $e');
        }
      }

      // Refresh cache after syncing
      if (syncedCount > 0) {
        try {
          final updatedRemoteVisits = await remoteDataSource.getAllVisits();
          await localDataSource.cacheVisits(updatedRemoteVisits);
        } catch (e) {
          print('Warning: Failed to refresh cache after syncing: $e');
        }
      }

      return Right(syncedCount);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Error during sync: $e'));
    }
  }
}