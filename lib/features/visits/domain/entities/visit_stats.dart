import 'package:equatable/equatable.dart';

class VisitStats extends Equatable {
  final int totalVisits;
  final int completedVisits;
  final int pendingVisits;
  // You can add more statistics here as your app requires, e.g.:
  // final double averageVisitDuration;
  // final Map<String, int> visitsByStatus; // e.g., {'Completed': 10, 'Pending': 5}
  // final Map<int, int> visitsByCustomerId; // e.g., {1: 3, 2: 7}

  const VisitStats({
    required this.totalVisits,
    required this.completedVisits,
    required this.pendingVisits,
    // Add other fields here
  });

  // Factory constructor for easy creation if needed, or from a map
  // factory VisitStats.fromMap(Map<String, dynamic> map) {
  //   return VisitStats(
  //     totalVisits: map['totalVisits'] as int,
  //     completedVisits: map['completedVisits'] as int,
  //     pendingVisits: map['pendingVisits'] as int,
  //   );
  // }

  @override
  List<Object?> get props => [
    totalVisits,
    completedVisits,
    pendingVisits,
    // Add other fields to props
  ];
}