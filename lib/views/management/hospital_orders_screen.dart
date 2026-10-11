import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/blood_bank.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';

class HospitalOrdersScreen extends StatelessWidget {
  final BloodBank hospital;

  const HospitalOrdersScreen({super.key, required this.hospital});

  Future<void> _callCustomer(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.accent;
      case 'Dispensed':
        return AppColors.success;
      case 'Rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final orders = appState.getRequestsForHospital(hospital.id);

    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No Incoming Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Customer requests and emergency blood reservations for your blood bank will appear here in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final timeFormatter = DateFormat('hh:mm a, d MMM');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final order = orders[i];
        final isEmergency = order.isEmergency;
        final statusColor = _getStatusColor(order.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEmergency ? Colors.red.shade200 : AppColors.border,
              width: isEmergency ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Urgency and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEmergency ? AppColors.dangerLight : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEmergency ? Icons.warning_rounded : Icons.info_outline_rounded,
                            size: 14,
                            color: isEmergency ? AppColors.danger : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.urgencyLevel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isEmergency ? AppColors.danger : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Customer Name and Blood Group Requested
                Row(
                  children: [
                    // Blood Group Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          order.bloodGroup,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Requested: ${order.unitsCount} Sachet(s) • ${timeFormatter.format(order.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (order.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Notes: ${order.notes}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],

                const Divider(height: 20),

                // Actions: Call customer & change status
                Row(
                  children: [
                    // Call customer in India button
                    OutlinedButton.icon(
                      onPressed: () => _callCustomer(order.customerPhone),
                      icon: const Icon(Icons.phone, size: 16),
                      label: Text(order.customerPhone),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const Spacer(),

                    // Action buttons according to status
                    if (order.status == 'Pending') ...[
                      ElevatedButton(
                        onPressed: () {
                          appState.updateRequestStatus(order.id, 'Approved');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Approve'),
                      ),
                    ] else if (order.status == 'Approved') ...[
                      ElevatedButton(
                        onPressed: () {
                          appState.updateRequestStatus(order.id, 'Dispensed');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${order.unitsCount} sachets of ${order.bloodGroup} dispensed and stock updated!',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Dispense Sachets'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
