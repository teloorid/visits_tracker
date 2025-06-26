import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:visits_tracker_v5/features/visits/presentation/pages/visits_list_page.dart';
import 'package:visits_tracker_v5/features/visits/presentation/pages/add_visit_page.dart';
import 'package:visits_tracker_v5/features/visits/presentation/pages/visit_detail_page.dart'; // Assuming you'll have this

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const VisitsListPage();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'add_visit',
            builder: (BuildContext context, GoRouterState state) {
              return const AddVisitPage();
            },
          ),
          GoRoute(
            path: 'visit_detail/:id',
            builder: (BuildContext context, GoRouterState state) {
              final visitId = int.parse(state.pathParameters['id']!);
              return VisitDetailPage(visitId: visitId);
            },
          ),
        ],
      ),
    ],
  );
}