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

  VisitCubit({
    required this.addVisit,
    required this.getAllVisits,
    required this.getVisitStats,
    required this.getAllCustomers,
    required this.getAllActivities,
  }) : super(VisitInitial());

  Future<void> loadVisitsAndDependencies() async {
    emit(VisitLoading());
    final visitsResult = await getAllVisits(const NoParams());
    final customersResult = await getAllCustomers(const NoParams());
    final activitiesResult = await getAllActivities(const NoParams());

    // Remove await here. The fold operation itself is synchronous.
    visitsResult.fold(
          (failure) {
        emit(VisitError(message: _mapFailureToMessage(failure)));
      },
          (visits) { // This callback doesn't need to be async if only synchronous emits happen
        // Remove await here
        customersResult.fold(
              (failure) {
            emit(VisitError(message: _mapFailureToMessage(failure)));
          },
              (customers) { // This callback doesn't need to be async
            // Remove await here
            activitiesResult.fold(
                  (failure) {
                emit(VisitError(message: _mapFailureToMessage(failure)));
              },
                  (activities) async { // This one *does* need to be async because of the await inside
                final statsResult = await getVisitStats(visits);
                statsResult.fold(
                      (failure) => emit(VisitError(message: _mapFailureToMessage(failure))),
                      (stats) => emit(VisitLoaded(
                    visits: visits,
                    customers: customers,
                    activities: activities,
                    stats: stats,
                    filteredVisits: visits, // Initialize filtered visits
                  )),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> addNewVisit({
    required int customerId,
    required DateTime visitDate,
    required String status,
    required String location,
    required String notes,
    required List<int> activitiesDoneIds,
  }) async {
    if (state is VisitLoaded) {
      final currentState = state as VisitLoaded;
      emit(VisitLoading()); // Indicate adding in progress

      final result = await addVisit(AddVisitParams(
        customerId: customerId,
        visitDate: visitDate,
        status: status,
        location: location,
        notes: notes,
        activitiesDoneIds: activitiesDoneIds,
      ));

      // HERE IS THE FIX: Remove await before result.fold
      result.fold(
            (failure) => emit(VisitError(message: _mapFailureToMessage(failure))),
            (newVisit) async { // This callback needs to be async because of the await inside
          final updatedVisits = List<Visit>.from(currentState.visits)..add(newVisit);
          final statsResult = await getVisitStats(updatedVisits);
          statsResult.fold(
                (failure) => emit(VisitError(message: _mapFailureToMessage(failure))),
                (stats) => emit(currentState.copyWith(
              visits: updatedVisits,
              stats: stats,
              filteredVisits: updatedVisits, // Update filtered visits as well
            )),
          );
        },
      );
    }
  }

  void filterVisits(String query, String? statusFilter) {
    if (state is VisitLoaded) {
      final currentState = state as VisitLoaded;
      List<Visit> tempFilteredVisits = currentState.visits;

      if (statusFilter != null && statusFilter != 'All') {
        tempFilteredVisits = tempFilteredVisits.where((visit) => visit.status == statusFilter).toList();
      }

      if (query.isNotEmpty) {
        final lowerCaseQuery = query.toLowerCase();
        tempFilteredVisits = tempFilteredVisits.where((visit) {
          final customer = currentState.customers.firstWhere(
                (cust) => cust.id == visit.customerId,
            orElse: () => Customer(id: -1, name: 'Unknown', createdAt: DateTime.now()),
          );
          return visit.notes.toLowerCase().contains(lowerCaseQuery) ||
              visit.location.toLowerCase().contains(lowerCaseQuery) ||
              customer.name.toLowerCase().contains(lowerCaseQuery);
        }).toList();
      }
      emit(currentState.copyWith(filteredVisits: tempFilteredVisits));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case CacheFailure:
        return (failure as CacheFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      default:
        return 'Unexpected error';
    }
  }
}