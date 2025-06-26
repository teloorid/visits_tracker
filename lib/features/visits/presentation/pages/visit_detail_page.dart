import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visits_tracker_v5/features/visits/presentation/manager/visit_cubit.dart';
import 'package:intl/intl.dart';

import '../../../activities/domain/entities/activity.dart';

class VisitDetailPage extends StatelessWidget {
  final int visitId;
  const VisitDetailPage({super.key, required this.visitId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Details'),
      ),
      body: BlocBuilder<VisitCubit, VisitState>(
        builder: (context, state) {
          if (state is VisitLoaded) {
            final visit = state.visits.firstWhere((v) => v.id == visitId,
                orElse: () => throw Exception('Visit not found'));
            final customer = state.customers.firstWhere(
                    (c) => c.id == visit.customerId,
                orElse: () => throw Exception('Customer not found'));
            final activitiesDone = visit.activitiesDoneIds
                .map((id) => state.activities
                .firstWhere((a) => a.id == id,
                orElse: () => Activity(
                    id: -1,
                    description: 'Unknown Activity',
                    createdAt: DateTime.now()))
                .description)
                .toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Customer:', customer.name),
                      _buildDetailRow('Date:', DateFormat('yyyy-MM-dd HH:mm').format(visit.visitDate)),
                      _buildDetailRow('Status:', visit.status),
                      _buildDetailRow('Location:', visit.location),
                      _buildDetailRow('Notes:', visit.notes),
                      _buildDetailRow('Activities Done:', activitiesDone.join(', ')),
                      _buildDetailRow('Created At:', DateFormat('yyyy-MM-dd HH:mm').format(visit.createdAt)),
                    ],
                  ),
                ),
              ),
            );
          } else if (state is VisitError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}