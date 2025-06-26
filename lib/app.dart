import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visits_tracker_v5/features/visits/presentation/manager/visit_cubit.dart';
import 'package:visits_tracker_v5/injection_container.dart';
import 'package:visits_tracker_v5/routes/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VisitCubit>(
          create: (context) => sl<VisitCubit>(),
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