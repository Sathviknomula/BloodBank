import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blood_bank.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';
import '../management/hospital_profile_edit.dart';
import 'add_hospital_dialog.dart';

class ManageHospitalsScreen extends StatelessWidget {
  const ManageHospitalsScreen({super.key});

  void _confirmDelete(BuildContext context, BloodBank bank) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Hospital?'),
        content: Text('Are you sure you want to delete "${bank.name}" from the network?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<AppStateProvider>().deleteHospital(bank.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${bank.name} removed.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final hospitals = appState.bloodBanks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Blood Banks & Hospitals'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddHospitalDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Hospital'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: hospitals.length,
        itemBuilder: (ctx, i) {
          final bank = hospitals[i];
          final totalUnits = bank.totalUnits;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_hospital, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bank.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${bank.city} • ${bank.address}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${bank.phone} | Email: ${bank.managerEmail}',
                              style: const TextStyle(fontSize: 12, color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Sachets: $totalUnits units',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.accent),
                              tooltip: 'Edit Hospital Info',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Scaffold(
                                      appBar: AppBar(title: Text('Edit ${bank.name}')),
                                      body: HospitalProfileEdit(hospital: bank),
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                              tooltip: 'Delete Hospital',
                              onPressed: () => _confirmDelete(context, bank),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
