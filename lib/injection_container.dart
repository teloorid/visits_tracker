import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart'; // Ensure this is imported for WidgetsFlutterBinding.ensureInitialized()

// Visit Feature Imports
import '../features/visits/data/datasources/visit_remote_data_source.dart';
import '../features/visits/data/datasources/visit_local_data_source.dart';
import '../features/visits/data/datasources/visit_local_data_source_impl.dart';
import '../features/visits/data/repositories/visit_repository_impl.dart';
import '../features/visits/domain/repositories/visit_repository.dart';
import '../features/visits/domain/usecases/add_visit.dart';
import '../features/visits/domain/usecases/get_all_visits.dart';
import '../features/visits/domain/usecases/get_visit_stats.dart';
import '../features/visits/presentation/manager/visit_cubit.dart';

// Customer Feature Imports
import '../features/customers/data/datasources/customer_remote_data_source.dart';
import '../features/customers/data/repositories/customer_repository_impl.dart';
import '../features/customers/domain/repositories/customer_repository.dart';
import '../features/customers/domain/usecases/get_all_customers.dart';

// Activity Feature Imports
import '../features/activities/data/datasources/activity_remote_data_source.dart';
import '../features/activities/data/repositories/activity_repository_impl.dart';
import '../features/activities/domain/repositories/activity_repository.dart';
import '../features/activities/domain/usecases/get_all_activities.dart';

// Core Imports
import '../core/constants/api_constants.dart';

final sl = GetIt.instance; // sl stands for Service Locator

Future<void> init() async {
  //! Core
  // WidgetsFlutterBinding.ensureInitialized() should be in main.dart, but harmless here if also present there.
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  await Hive.initFlutter();

  // IMPORTANT: Register asynchronous dependencies first and then await their readiness
  // We explicitly await the registration futures to ensure the boxes are open
  // before anything tries to retrieve them.
  sl.registerLazySingletonAsync<Box<dynamic>>(
        () => Hive.openBox('visitsCacheBox'), // This is the Future that needs to complete
    instanceName: 'visitsCacheBox',
  );
  sl.registerLazySingletonAsync<Box<dynamic>>(
        () => Hive.openBox('pendingVisitsBox'),
    instanceName: 'pendingVisitsBox',
  );

  // Await the completion of all async registrations before registering anything that depends on them.
  // This tells GetIt to wait until all currently registered async factories/singletons are ready.
  await sl.allReady();

  sl.registerLazySingleton<VisitLocalDataSource>(
        () => VisitLocalDataSourceImpl(
      visitsBox: sl<Box<dynamic>>(instanceName: 'visitsCacheBox'), // Now safe to retrieve
      pendingVisitsBox: sl<Box<dynamic>>(instanceName: 'pendingVisitsBox'), // Now safe to retrieve
    ),
  );

  // Dio Client (This can be registered before or after asyncs if it doesn't depend on them)
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

  //! Features - Visits
  // Cubit
  // Registering Cubit as factory means it's created on demand.
  // Ensure all its dependencies (like UseCases) are registered before it's created.
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
  sl.registerLazySingleton(() => GetVisitStats());

  // Repository
  sl.registerLazySingleton<VisitRepository>(
        () => VisitRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(), // localDataSource depends on Hive Boxes
    ),
  );

  // Data sources
  sl.registerLazySingleton<VisitRemoteDataSource>(
        () => VisitRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Customers
  sl.registerLazySingleton(() => GetAllCustomers(sl()));
  sl.registerLazySingleton<CustomerRepository>(
        () => CustomerRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CustomerRemoteDataSource>(
        () => CustomerRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Activities
  sl.registerLazySingleton(() => GetAllActivities(sl()));
  sl.registerLazySingleton<ActivityRepository>(
        () => ActivityRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ActivityRemoteDataSource>(
        () => ActivityRemoteDataSourceImpl(client: sl()),
  );
}