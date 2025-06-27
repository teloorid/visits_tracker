import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:visits_tracker_v5/features/activities/domain/entities/activity.dart';
import 'package:visits_tracker_v5/features/activities/domain/usecases/get_all_activities.dart';
import 'package:visits_tracker_v5/features/customers/domain/entities/customer.dart';
import 'package:visits_tracker_v5/features/customers/domain/usecases/get_all_customers.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/visit.dart';
import '../../domain/usecases/add_visit.dart';
import '../../domain/usecases/get_all_visits.dart';
import '../../domain/usecases/get_visit_stats.dart';

part 'visit_state.dart';

class VisitCubit extends Cubit<VisitState> {
  final AddVisit addVisit;
  final GetAllVisits getAllVisits;
  final GetVisitStats getVisitStats;
  final GetAllCustomers getAllCustomers;
  final GetAllActivities getAllActivities;

  // Add a flag to prevent multiple simultaneous loads
  bool _isLoading = false;

  VisitCubit({
    required this.addVisit,
    required this.getAllVisits,
    required this.getVisitStats,
    required this.getAllCustomers,
    required this.getAllActivities,
  }) : super(VisitInitial());

  Future<void> loadVisitsAndDependencies() async {
    // Prevent multiple simultaneous loads
    if (_isLoading) return;

    _isLoading = true;
    emit(VisitLoading());

    try {
      // Load all data concurrently for better performance
      final results = await Future.wait([
        getAllVisits(const NoParams()),
        getAllCustomers(const NoParams()),
        getAllActivities(const NoParams()),
      ]);

      final visitsResult = results[0];
      final customersResult = results[1];
      final activitiesResult = results[2];

      // Check for failures and extract values properly
      List<Visit> visits = [];
      List<Customer> customers = [];
      List<Activity> activities = [];

      // Handle visits result
      visitsResult.fold(
            (failure) {
          emit(VisitError(message: _mapFailureToMessage(failure)));
          return;
        },
            (success) => visits = success as List<Visit>,
      );

      // Only continue if visits loaded successfully
      if (state is VisitError) {
        _isLoading = false;
        return;
      }

      // Handle customers result
      customersResult.fold(
            (failure) {
          emit(VisitError(message: _mapFailureToMessage(failure)));
          return;
        },
            (success) => customers = success as List<Customer>,
      );

      // Only continue if customers loaded successfully
      if (state is VisitError) {
        _isLoading = false;
        return;
      }

      // Handle activities result
      activitiesResult.fold(
            (failure) {
          emit(VisitError(message: _mapFailureToMessage(failure)));
          return;
        },
            (success) => activities = success as List<Activity>,
      );

      // Only continue if activities loaded successfully
      if (state is VisitError) {
        _isLoading = false;
        return;
      }

      // Get stats only if all data loaded successfully
      final statsResult = await getVisitStats(visits);
      statsResult.fold(
            (failure) => emit(VisitError(message: _mapFailureToMessage(failure))),
            (stats) => emit(VisitLoaded(
          visits: visits,
          customers: customers,
          activities: activities,
          stats: stats,
          filteredVisits: visits,
        )),
      );
    } catch (e, stackTrace) {
      print('*** VisitCubit Global Catch Error ***');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace: $stackTrace');
      emit(VisitError(message: 'An unexpected error occurred: ${e.toString()}'));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> addNewVisit({
    required int customerId,
    required DateTime visitDate,
    required String status,
    required String location,
    required String notes,
    required List<int> activitiesDoneIds,
  }) async {
    if (state is! VisitLoaded) return;

    final currentState = state as VisitLoaded;
    emit(VisitLoading());

    try {
      final result = await addVisit(AddVisitParams(
        customerId: customerId,
        visitDate: visitDate,
        status: status,
        location: location,
        notes: notes,
        activitiesDoneIds: activitiesDoneIds,
      ));

      result.fold(
            (failure) => emit(VisitError(message: _mapFailureToMessage(failure))),
            (newVisit) async {
          final updatedVisits = [...currentState.visits, newVisit];
          final statsResult = await getVisitStats(updatedVisits);

          statsResult.fold(
                (failure) => emit(VisitError(message: _mapFailureToMessage(failure))),
                (stats) => emit(currentState.copyWith(
              visits: updatedVisits,
              stats: stats,
              filteredVisits: updatedVisits,
            )),
          );
        },
      );
    } catch (e) {
      emit(VisitError(message: 'Failed to add visit: ${e.toString()}'));
    }
  }

  void filterVisits(String query, String? statusFilter) {
    if (state is! VisitLoaded) return;

    final currentState = state as VisitLoaded;
    List<Visit> tempFilteredVisits = currentState.visits;

    // Apply status filter
    if (statusFilter != null && statusFilter != 'All') {
      tempFilteredVisits = tempFilteredVisits
          .where((visit) => visit.status == statusFilter)
          .toList();
    }

    // Apply search query
    if (query.isNotEmpty) {
      final lowerCaseQuery = query.toLowerCase();
      tempFilteredVisits = tempFilteredVisits.where((visit) {
        final customer = currentState.customers.firstWhere(
              (cust) => cust.id == visit.customerId,
          orElse: () => Customer(
            id: -1,
            name: 'Unknown',
            createdAt: DateTime.now(),
          ),
        );

        return visit.notes.toLowerCase().contains(lowerCaseQuery) ||
            visit.location.toLowerCase().contains(lowerCaseQuery) ||
            customer.name.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    emit(currentState.copyWith(filteredVisits: tempFilteredVisits));
  }

  void clearFilters() {
    if (state is VisitLoaded) {
      final currentState = state as VisitLoaded;
      emit(currentState.copyWith(filteredVisits: currentState.visits));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    return switch (failure.runtimeType) {
      ServerFailure _ => (failure as ServerFailure).message,
      CacheFailure _ => (failure as CacheFailure).message,
      NetworkFailure _ => (failure as NetworkFailure).message,
      _ => 'Unexpected error occurred',
    };
  }

  @override
  Future<void> close() {
    _isLoading = false;
    return super.close();
  }
}