import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visits_tracker_v5/injection_container.dart' as di;
import 'package:visits_tracker_v5/routes/app_router.dart';

import 'features/visits/presentation/manager/visit_cubit.dart'; // Alias di for clarity
// Ensure you import your actual root app widget, e.g.:
// import 'package:visits_tracker_v5/my_app_root.dart'; // Adjust this path if your main app is in a different file

void main() {
  // THIS IS CRUCIAL: Ensure Flutter engine is initialized before ANY plugin calls (like Hive or SharedPreferences)
  WidgetsFlutterBinding.ensureInitialized();

  // Start the app with an initializer widget that handles async loading
  runApp(const AppInitializer());
}

/// A widget responsible for initializing app dependencies and showing a loading screen.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  // This Future will hold the result of our dependency initialization
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    // Start the asynchronous initialization process
    _initialization = di.init();
  }

  @override
  Widget build(BuildContext context) {
    // Use a FutureBuilder to wait for the initialization to complete
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        // Check the connection state of the Future
        if (snapshot.connectionState == ConnectionState.done) {
          // If initialization is complete:
          if (snapshot.hasError) {
            // Optional: Show an error screen if initialization failed
            debugPrint('Initialization error: ${snapshot.error}');
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('Error loading app: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                ),
              ),
            );
          }
          // If no errors, show your actual main application widget
          return const MyApp(); // <-- Replace MyApp() with your actual root widget if it has a different name
        } else {
          // While initializing, show a simple loading indicator
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VisitCubit>(
          create: (context) => di.sl<VisitCubit>(),
        ),
        // Add other BlocProviders for CustomerCubit, ActivityCubit if needed
      ],
      child: MaterialApp.router(
        title: 'Visits Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routerConfig: AppRouter.router, // Use go_router
      ),
    );
  }
}