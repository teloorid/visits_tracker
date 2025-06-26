import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/visits/data/datasources/visit_remote_data_source.dart';
import '../features/visits/data/repositories/visit_repository_impl.dart';
import '../features/visits/domain/repositories/visit_repository.dart';
import '../features/visits/domain/usecases/add_visit.dart';
import '../features/visits/domain/usecases/get_all_visits.dart';
import '../features/visits/domain/usecases/get_visit_stats.dart'; // Ensure this import is correct
import '../features/visits/presentation/manager/visit_cubit.dart';
import '../features/customers/data/datasources/customer_remote_data_source.dart';
import '../features/customers/data/repositories/customer_repository_impl.dart';
import '../features/customers/domain/repositories/customer_repository.dart';
import '../features/customers/domain/usecases/get_all_customers.dart';
import '../features/activities/data/datasources/activity_remote_data_source.dart';
import '../features/activities/data/repositories/activity_repository_impl.dart';
import '../features/activities/domain/repositories/activity_repository.dart';
import '../features/activities/domain/usecases/get_all_activities.dart';
import '../core/constants/api_constants.dart';

final sl = GetIt.instance; // sl stands for Service Locator

Future<void> init() async {
  //! Features - Visits
  // Cubit
  sl.registerFactory(
        () => VisitCubit(
      addVisit: sl(),
      getAllVisits: sl(),
      getVisitStats: sl(),
      getAllCustomers: sl(),
      getAllActivities: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => AddVisit(sl()));
  sl.registerLazySingleton(() => GetAllVisits(sl()));
  // FIX HERE: Register GetVisitStats without an argument
  sl.registerLazySingleton(() => GetVisitStats());

  // Repository
  sl.registerLazySingleton<VisitRepository>(
        () => VisitRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()), // Assuming no localDataSource for now
  );

  // Data sources
  sl.registerLazySingleton<VisitRemoteDataSource>(
        () => VisitRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Customers
  // Use cases
  sl.registerLazySingleton(() => GetAllCustomers(sl()));

  // Repository
  sl.registerLazySingleton<CustomerRepository>(
        () => CustomerRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<CustomerRemoteDataSource>(
        () => CustomerRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Activities
  // Use cases
  sl.registerLazySingleton(() => GetAllActivities(sl()));

  // Repository
  sl.registerLazySingleton<ActivityRepository>(
        () => ActivityRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ActivityRemoteDataSource>(
        () => ActivityRemoteDataSourceImpl(client: sl()),
  );

  //! Core
  // Dio Client
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'apikey': ApiConstants.apiKey,
        'Content-Type': 'application/json',
      },
    ));
    return dio;
  });

  // Optional: For offline support (shared_preferences, hive)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  await Hive.initFlutter();
  sl.registerLazySingletonAsync(() async => await Hive.openBox('visitsBox'));
}