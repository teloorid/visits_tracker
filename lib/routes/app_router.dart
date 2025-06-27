import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visits_tracker_v5/features/visits/presentation/pages/visits_list_page.dart';
import 'package:visits_tracker_v5/features/visits/presentation/pages/add_visit_page.dart';
import 'package:visits_tracker_v5/features/visits/presentation/pages/visit_detail_page.dart';
import 'package:visits_tracker_v5/features/visits/presentation/manager/visit_cubit.dart';
import 'package:visits_tracker_v5/injection_container.dart' as di;

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => ErrorPage(error: state.error),
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return BlocProvider(
            create: (context) => di.sl<VisitCubit>()..loadVisitsAndDependencies(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const VisitsListPage(),
            routes: [
              GoRoute(
                path: 'add_visit',
                name: 'add_visit',
                builder: (context, state) => const AddVisitPage(),
              ),
              GoRoute(
                path: 'visit_detail/:id',
                name: 'visit_detail',
                builder: (context, state) {
                  final visitId = int.tryParse(state.pathParameters['id'] ?? '');
                  if (visitId == null) {
                    return ErrorPage(
                      error: Exception('Invalid visit ID'),
                    );
                  }
                  return VisitDetailPage(visitId: visitId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Navigation helper methods
  static void goHome(BuildContext context) {
    context.go('/');
  }

  static void goToAddVisit(BuildContext context) {
    context.go('/add_visit');
  }

  static void goToVisitDetail(BuildContext context, int visitId) {
    context.go('/visit_detail/$visitId');
  }

  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      goHome(context);
    }
  }
}

class ErrorPage extends StatelessWidget {
  final Exception? error;

  const ErrorPage({
    super.key,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 72,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error?.toString() ?? 'An unexpected error occurred',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => AppRouter.goHome(context),
                    icon: const Icon(Icons.home),
                    label: const Text('Go Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => AppRouter.goBack(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension for easier navigation
extension GoRouterExtension on BuildContext {
  void goToHome() => AppRouter.goHome(this);
  void goToAddVisit() => AppRouter.goToAddVisit(this);
  void goToVisitDetail(int visitId) => AppRouter.goToVisitDetail(this, visitId);
  void goBackSafe() => AppRouter.goBack(this);
}