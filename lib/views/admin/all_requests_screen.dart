import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';

class AllRequestsScreen extends StatefulWidget {
  const AllRequestsScreen({super.key});

  @override
  State<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

class _AllRequestsScreenState extends State<AllRequestsScreen> {
  String _statusFilter = 'All';

  Future<void> _callCustomer(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final allRequests = appState.requests;
    final filtered = _statusFilter == 'All'
        ? allRequests
        : allRequests.where((r) => r.status == _statusFilter).toList();

    final timeFormatter = DateFormat('hh:mm a, d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Orders & Request Audit Log'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: ['All', 'Pending', 'Approved', 'Dispensed', 'Rejected'].map((status) {
                final isSel = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _statusFilter = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No orders found for this status filter.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final req = filtered[i];
                      final isEmergency = req.isEmergency;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isEmergency ? AppColors.dangerLight : AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          req.urgencyLevel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isEmergency ? AppColors.danger : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: req.status == 'Dispensed'
                                          ? AppColors.successLight
                                          : req.status == 'Approved'
                                              ? AppColors.primaryTint
                                              : AppColors.warningLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      req.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: req.status == 'Dispensed'
                                            ? AppColors.success
                                            : req.status == 'Approved'
                                                ? AppColors.primary
                                                : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        req.bloodGroup,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
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
                                          '${req.customerName} (${req.unitsCount} Sachets)',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Hospital: ${req.hospitalName}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: Colors.green),
                                    tooltip: 'Call Customer (${req.customerPhone})',
                                    onPressed: () => _callCustomer(req.customerPhone),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Time: ${timeFormatter.format(req.createdAt)} • Phone: ${req.customerPhone}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
