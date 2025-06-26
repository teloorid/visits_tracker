// lib/features/visits/data/datasources/visit_local_data_source.dart
import 'package:hive/hive.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/visit_model.dart';

abstract class VisitLocalDataSource {
  Future<List<VisitModel>> getAllVisits();
  Future<void> cacheVisits(List<VisitModel> visits);
  Future<void> addPendingVisit(VisitModel visit);
  Future<List<VisitModel>> getPendingVisits();
  Future<void> clearPendingVisits();
}

class VisitLocalDataSourceImpl implements VisitLocalDataSource {
  final Box<VisitModel> visitsBox;
  final Box<VisitModel> pendingVisitsBox;

  VisitLocalDataSourceImpl({
    required this.visitsBox,
    required this.pendingVisitsBox,
  });

  @override
  Future<void> cacheVisits(List<VisitModel> visits) async {
    await visitsBox.clear(); // Clear existing cache
    await visitsBox.addAll(visits);
  }

  @override
  Future<List<VisitModel>> getAllVisits() {
    if (visitsBox.isNotEmpty) {
      return Future.value(visitsBox.values.toList());
    }
    throw CacheException(message: 'No cached visits found.');
  }

  @override
  Future<void> addPendingVisit(VisitModel visit) async {
    await pendingVisitsBox.add(visit);
  }

  @override
  Future<List<VisitModel>> getPendingVisits() async {
    return Future.value(pendingVisitsBox.values.toList());
  }

  @override
  Future<void> clearPendingVisits() async {
    await pendingVisitsBox.clear();
  }
}

// In di/injection_container.dart, initialize Hive and register:
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:visits_tracker_app/features/visits/data/models/visit_model.dart';
//
// Future<void> init() async {
//   ...
//   await Hive.initFlutter();
//   Hive.registerAdapter(VisitModelAdapter()); // You'd need to generate this
//   final visitsBox = await Hive.openBox<VisitModel>('visitsBox');
//   final pendingVisitsBox = await Hive.openBox<VisitModel>('pendingVisitsBox');
//
//   sl.registerLazySingleton<VisitLocalDataSource>(
//     () => VisitLocalDataSourceImpl(visitsBox: visitsBox, pendingVisitsBox: pendingVisitsBox),
//   );
//
//   sl.registerLazySingleton<VisitRepository>(
//     () => VisitRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
//   );
// }

// To use Hive, VisitModel would need a TypeAdapter:
// @HiveType(typeId: 0)
// class VisitModel extends Visit {
//   @HiveField(0)
//   final int id;
//   @HiveField(1)
//   final int customerId;
//   // ... rest of the fields with @HiveField annotations
// }
// Run `flutter packages pub run build_runner build` to generate adapter.