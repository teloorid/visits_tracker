import 'dart:async'; // ADD THIS IMPORT
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visits_tracker_v5/injection_container.dart' as di;
import 'package:visits_tracker_v5/routes/app_router.dart';
import 'features/visits/presentation/manager/visit_cubit.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Add global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack Trace: ${details.stack}');
  };

  try {
    // Set preferred orientations (optional - adjust as needed)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    debugPrint('System setup error: $e');
    // Continue even if system setup fails
  }

  // Start the app with the initializer
  runApp(const AppInitializer());
}

/// A widget responsible for initializing app dependencies with optimized loading
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<void> _initialization;
  bool _hasError = false;
  String _errorMessage = '';
  String _errorDetails = '';

  @override
  void initState() {
    super.initState();
    // FIXED: Initialize the Future immediately in initState
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('Starting app initialization...');

      // Add a small delay to let the UI render first
      await Future.delayed(const Duration(milliseconds: 100));

      // Initialize dependencies with timeout
      await di.init().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Initialization timeout - dependency injection took too long');
        },
      );

      // Another small delay before completing
      await Future.delayed(const Duration(milliseconds: 50));

      debugPrint('App initialization completed successfully');

    } catch (e, stackTrace) {
      debugPrint('Initialization error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Update error state
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _getUserFriendlyError(e);
          _errorDetails = '$e\n\nStack Trace:\n$stackTrace';
        });
      }

      // Re-throw to let FutureBuilder handle it
      rethrow;
    }
  }

  String _getUserFriendlyError(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('Hive')) {
      return 'Database initialization failed. Please clear app data and try again.';
    } else if (errorString.contains('SharedPreferences')) {
      return 'Settings initialization failed. Please check app permissions.';
    } else if (errorString.contains('timeout')) {
      return 'Initialization is taking too long. Please check your device storage and try again.';
    } else if (errorString.contains('permission')) {
      return 'App permissions are required. Please grant necessary permissions.';
    } else {
      return 'An unexpected error occurred during app startup.';
    }
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _errorDetails = '';
      _initialization = _initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visits Tracker',
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      home: _hasError ? _buildErrorScreen() : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        debugPrint('FutureBuilder state: ${snapshot.connectionState}');

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            debugPrint('FutureBuilder error: ${snapshot.error}');
            return _buildErrorScreen();
          }

          // Success - navigate to main app
          debugPrint('Navigating to main app...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const MyApp(),
                  transitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            }
          });
          return _buildLoadingScreen();
        }

        // Still loading
        return _buildLoadingScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.business_center,
                size: 40,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),

            // Loading indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 24),

            // Loading text
            const Text(
              'Initializing Visits Tracker...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Setting up database and preferences',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'Something went wrong while setting up the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Error details (expandable)
              if (_errorDetails.isNotEmpty)
                ExpansionTile(
                  title: const Text('Technical Details'),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _errorDetails,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              // Action buttons
              Column(
                children: [
                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint('Retrying initialization...');
                        _retryInitialization();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Clear data button (if database error)
                  if (_errorMessage.contains('Database') || _errorMessage.contains('Hive'))
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            debugPrint('Attempting to clear app data...');
                            // You might want to add a method to clear Hive boxes here
                            // await di.clearAllData(); // Implement this if needed
                            _retryInitialization();
                          } catch (e) {
                            debugPrint('Error clearing data: $e');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Clear Data & Retry',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  if (_errorMessage.contains('Database') || _errorMessage.contains('Hive'))
                    const SizedBox(height: 12),

                  // Exit button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => SystemNavigator.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Exit App',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'System',
      useMaterial3: true,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp widget...');

    return MultiBlocProvider(
      providers: [
        BlocProvider<VisitCubit>(
          create: (context) {
            debugPrint('Creating VisitCubit...');
            return di.sl<VisitCubit>();
          },
          lazy: true,
        ),
      ],
      child: MaterialApp.router(
        title: 'Visits Tracker',
        debugShowCheckedModeBanner: false,
        theme: _buildMainTheme(),
        routerConfig: AppRouter.router,

        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler.clamp(
                minScaleFactor: 0.8,
                maxScaleFactor: 1.2,
              ),
            ),
            child: child!,
          );
        },

        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(),
        ),
      ),
    );
  }

  ThemeData _buildMainTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
      platform: TargetPlatform.android,

      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),

      // FIXED: Use CardThemeData instead of CardTheme
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}