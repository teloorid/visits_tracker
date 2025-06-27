import '../models/visit_model.dart';
import '../../../../core/errors/exceptions.dart';

abstract class VisitLocalDataSource {
  /// Gets the cached [VisitModel] list from Hive.
  /// Throws [CacheException] if no cached data is present.
  Future<List<VisitModel>> getAllVisitsFromCache(); // Renamed for clarity

  /// Caches the given [VisitModel] list in Hive.
  Future<void> cacheVisits(List<VisitModel> visits);

  /// Saves a visit that needs to be synced later (e.g., created offline).
  Future<void> addPendingVisit(VisitModel visit);

  /// Retrieves a list of visits that are pending synchronization.
  Future<List<VisitModel>> getPendingVisits();

  /// Removes a specific pending visit after successful synchronization.
  Future<void> removePendingVisit(VisitModel visit);

  /// Clears all pending visits after successful synchronization.
  Future<void> clearPendingVisits();

  /// Clears all cached visits (main cache).
  Future<void> clearAllVisitsCache(); // Added for complete cache management
}