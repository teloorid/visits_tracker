part of 'visit_cubit.dart';

abstract class VisitState extends Equatable {
  const VisitState();

  @override
  List<Object> get props => [];
}

class VisitInitial extends VisitState {}

class VisitLoading extends VisitState {}

class VisitLoaded extends VisitState {
  final List<Visit> visits;
  final List<Visit> filteredVisits;
  final List<Customer> customers; // All available customers
  final List<Activity> activities; // All available activities
  final VisitStats stats;

  const VisitLoaded({
    required this.visits,
    required this.filteredVisits,
    required this.customers,
    required this.activities,
    required this.stats,
  });

  VisitLoaded copyWith({
    List<Visit>? visits,
    List<Visit>? filteredVisits,
    List<Customer>? customers,
    List<Activity>? activities,
    VisitStats? stats,
  }) {
    return VisitLoaded(
      visits: visits ?? this.visits,
      filteredVisits: filteredVisits ?? this.filteredVisits,
      customers: customers ?? this.customers,
      activities: activities ?? this.activities,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object> get props => [visits, filteredVisits, customers, activities, stats];
}

class VisitError extends VisitState {
  final String message;

  const VisitError({required this.message});

  @override
  List<Object> get props => [message];
}