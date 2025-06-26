import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart'; // Import compute function
import 'visit_local_data_source.dart';
import '../models/visit_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../utils/visit_parser_utils.dart'; // Import our new utility file

class VisitLocalDataSourceImpl implements VisitLocalDataSource {
  final Box<dynamic> visitsBox;
  final Box<dynamic> pendingVisitsBox;

  VisitLocalDataSourceImpl({
    required this.visitsBox,
    required this.pendingVisitsBox,
  });

  @override
  Future<void> cacheVisits(List<VisitModel> visits) async {
    try {
      await visitsBox.clear();
      // Serialization (toJson) is usually faster than parsing, but can also be offloaded if needed.
      // For now, we'll keep it synchronous here.
      for (var visit in visits) {
        await visitsBox.put(visit.id.toString(), visit.toJson());
      }
    } catch (e) {
      throw CacheException(message: 'Failed to cache visits: $e');
    }
  }

  @override
  Future<List<VisitModel>> getAllVisitsFromCache() {
    try {
      final List<dynamic> jsonList = visitsBox.values.toList();
      if (jsonList.isEmpty) {
        throw CacheException(message: 'No cached visits found.');
      }
      // Offload parsing to an Isolate
      return compute(parseVisitsList, jsonList);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: 'Failed to retrieve visits from cache: $e');
    }
  }

  @override
  Future<void> addPendingVisit(VisitModel visit) async {
    try {
      // Small serialization is likely fine on main thread
      await pendingVisitsBox.add(visit.toJson());
    } catch (e) {
      throw CacheException(message: 'Failed to save pending visit: $e');
    }
  }

  @override
  Future<List<VisitModel>> getPendingVisits() async {
    try {
      final List<dynamic> jsonList = pendingVisitsBox.values.toList();
      // Offload parsing to an Isolate
      return compute(parseVisitsList, jsonList);
    } catch (e) {
      throw CacheException(message: 'Failed to get pending visits: $e');
    }
  }

  @override
  Future<void> clearPendingVisits() async {
    try {
      await pendingVisitsBox.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear pending visits: $e');
    }
  }

  @override
  Future<void> clearAllVisitsCache() async {
    try {
      await visitsBox.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear all visits cache: $e');
    }
  }
}