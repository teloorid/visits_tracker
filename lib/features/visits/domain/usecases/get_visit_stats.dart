import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/visit.dart';

class GetVisitStats implements UseCase<VisitStats, List<Visit>> {
  GetVisitStats(); // Does not depend on a repository directly, acts on existing data

  @override
  Future<Either<Failure, VisitStats>> call(List<Visit> visits) async {
    if (visits.isEmpty) {
      return const Right(VisitStats(totalVisits: 0, completedVisits: 0, pendingVisits: 0, cancelledVisits: 0));
    }

    final totalVisits = visits.length;
    final completedVisits = visits.where((visit) => visit.status == 'Completed').length;
    final pendingVisits = visits.where((visit) => visit.status == 'Pending').length;
    final cancelledVisits = visits.where((visit) => visit.status == 'Cancelled').length;

    return Right(VisitStats(
      totalVisits: totalVisits,
      completedVisits: completedVisits,
      pendingVisits: pendingVisits,
      cancelledVisits: cancelledVisits,
    ));
  }
}

class VisitStats extends Equatable {
  final int totalVisits;
  final int completedVisits;
  final int pendingVisits;
  final int cancelledVisits;

  const VisitStats({
    required this.totalVisits,
    required this.completedVisits,
    required this.pendingVisits,
    required this.cancelledVisits,
  });

  @override
  List<Object?> get props => [totalVisits, completedVisits, pendingVisits, cancelledVisits];
}