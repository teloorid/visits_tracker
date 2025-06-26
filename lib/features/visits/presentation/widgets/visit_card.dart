import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/visit.dart';

class VisitCard extends StatelessWidget {
  final Visit visit;
  final String customerName;
  final List<String> activitiesDone;
  final VoidCallback onTap;

  const VisitCard({
    super.key,
    required this.visit,
    required this.customerName,
    required this.activitiesDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(visit.visitDate),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    visit.status,
                    style: TextStyle(
                      fontSize: 14,
                      color: visit.status == 'Completed'
                          ? Colors.green
                          : visit.status == 'Pending'
                          ? Colors.orange
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      visit.location,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (visit.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${visit.notes}',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (activitiesDone.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Activities: ${activitiesDone.join(', ')}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}