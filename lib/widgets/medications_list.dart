import 'package:flutter/material.dart';
import 'package:elderly_care/models/medication_model.dart';
import 'package:elderly_care/services/medication_service.dart';
import 'package:intl/intl.dart';

class MedicationsList extends StatelessWidget {
  const MedicationsList({super.key});

  static final DateTime _currentTime = DateTime.parse('2025-02-21 15:00:53');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Medication>>(
      stream: MedicationService().getTodaysMedicationsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                TextButton(
                  onPressed: () {
                    // Trigger a rebuild to retry
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final medications = snapshot.data!;
        
        if (medications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No medications scheduled for today',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication = medications[index];
            final nextDose = medication.schedule.firstWhere(
              (time) => time.isAfter(_currentTime),
              orElse: () => medication.schedule.first,
            );

            return _MedicationCard(
              medication: medication,
              nextDose: nextDose,
              isUpcoming: nextDose.isAfter(_currentTime),
            );
          },
        );
      },
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final DateTime nextDose;
  final bool isUpcoming;

  const _MedicationCard({
    required this.medication,
    required this.nextDose,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: isUpcoming ? 2 : 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUpcoming ? theme.primaryColor.withOpacity(0.1) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medication,
            color: isUpcoming ? theme.primaryColor : Colors.grey,
          ),
        ),
        title: Text(
          medication.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(medication.dosage),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: isUpcoming ? theme.primaryColor : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Next dose: ${DateFormat('hh:mm a').format(nextDose)}',
                  style: TextStyle(
                    color: isUpcoming ? theme.primaryColor : Colors.grey,
                    fontWeight: isUpcoming ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (medication.instructions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                medication.instructions,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            isUpcoming ? Icons.check_circle_outline : Icons.check_circle,
            color: isUpcoming ? theme.primaryColor : Colors.green,
          ),
          onPressed: () async {
            try {
              // Show confirmation dialog
              final shouldMark = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Mark Medication'),
                  content: Text('Mark ${medication.name} as taken?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );

              if (shouldMark == true) {
                await MedicationService().markMedicationTaken(
                  medication.id,
                  nextDose,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${medication.name} marked as taken'),
                      backgroundColor: Colors.green,
                      action: SnackBarAction(
                        label: 'UNDO',
                        textColor: Colors.white,
                        onPressed: () {
                          // TODO: Implement undo functionality
                        },
                      ),
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}