import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

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
import '../core/network/network_info.dart';

final sl = GetIt.instance;

Future<void> init() async {
  try {
    //! Core
    WidgetsFlutterBinding.ensureInitialized();

    // External dependencies
    await _initExternalDependencies();

    // Core services
    _initCoreServices();

    // Data sources
    await _initDataSources();

    // Repositories
    _initRepositories();

    // Use cases
    _initUseCases();

    // Cubits/Blocs
    _initCubits();

    print('✅ Dependency injection initialization completed');
  } catch (e) {
    print('❌ Error initializing dependencies: $e');
    rethrow;
  }
}

Future<void> _initExternalDependencies() async {
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Initialize Hive
  await Hive.initFlutter();

  // Open Hive boxes
  final visitsCacheBox = await Hive.openBox('visitsCacheBox');
  final pendingVisitsBox = await Hive.openBox('pendingVisitsBox');

  sl.registerLazySingleton<Box<dynamic>>(
        () => visitsCacheBox,
    instanceName: 'visitsCacheBox',
  );
  sl.registerLazySingleton<Box<dynamic>>(
        () => pendingVisitsBox,
    instanceName: 'pendingVisitsBox',
  );

  // Connectivity
  sl.registerLazySingleton(() => Connectivity());
}

void _initCoreServices() {
  // Network Info
  sl.registerLazySingleton<NetworkInfo>(
        () => NetworkInfoImpl(sl()),
  );

  // Dio Client with interceptors
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'apikey': ApiConstants.apiKey,
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ));
    }

    // Add retry interceptor
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ));

    return dio;
  });
}

Future<void> _initDataSources() async {
  // Local data sources
  sl.registerLazySingleton<VisitLocalDataSource>(
        () => VisitLocalDataSourceImpl(
      visitsBox: sl<Box<dynamic>>(instanceName: 'visitsCacheBox'),
      pendingVisitsBox: sl<Box<dynamic>>(instanceName: 'pendingVisitsBox'),
    ),
  );

  // Remote data sources
  sl.registerLazySingleton<VisitRemoteDataSource>(
        () => VisitRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<CustomerRemoteDataSource>(
        () => CustomerRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<ActivityRemoteDataSource>(
        () => ActivityRemoteDataSourceImpl(client: sl()),
  );
}

void _initRepositories() {
  sl.registerLazySingleton<VisitRepository>(
        () => VisitRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<CustomerRepository>(
        () => CustomerRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<ActivityRepository>(
        () => ActivityRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
}

void _initUseCases() {
  sl.registerLazySingleton(() => AddVisit(sl()));
  sl.registerLazySingleton(() => GetAllVisits(sl()));
  sl.registerLazySingleton(() => GetVisitStats());
  sl.registerLazySingleton(() => GetAllCustomers(sl()));
  sl.registerLazySingleton(() => GetAllActivities(sl()));
}

void _initCubits() {
  sl.registerFactory(
        () => VisitCubit(
      addVisit: sl(),
      getAllVisits: sl(),
      getVisitStats: sl(),
      getAllCustomers: sl(),
      getAllActivities: sl(),
    ),
  );
}

// Cleanup method
Future<void> dispose() async {
  await sl.reset();
  await Hive.close();
}

// Helper classes
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    required this.retries,
    required this.retryDelays,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] ?? 0;

    if (retryCount < retries && _shouldRetry(err)) {
      extra['retryCount'] = retryCount + 1;

      final delay = retryDelays.length > retryCount
          ? retryDelays[retryCount]
          : retryDelays.last;

      await Future.delayed(delay);

      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}