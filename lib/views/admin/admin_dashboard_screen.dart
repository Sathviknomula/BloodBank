import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blood_bank.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stat_card.dart';
import 'add_hospital_dialog.dart';
import 'all_requests_screen.dart';
import 'manage_hospitals_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final totalHospitals = appState.totalHospitalsListed;
    final totalUnits = appState.totalUnitsAvailable;
    final totalOrders = appState.totalOrdersPlaced;
    final pendingOrders = appState.pendingOrdersCount;
    final distribution = appState.networkStockDistribution;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin & Developer Console', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Central Blood Bank Oversight & Analytics', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Demo Data',
            icon: const Icon(Icons.restore_page_rounded, color: AppColors.textSecondary),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Demo Data?'),
                  content: const Text('This will reset all hospitals, stock counts, and requests back to initial defaults.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
                  ],
                ),
              );
              if (confirm == true) {
                await appState.resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo data reset successfully.')),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            onPressed: () {
              appState.logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. KPI Stat Cards Grid
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 600;
                final crossAxisCount = isWide ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isWide ? 1.4 : 1.25,
                  children: [
                    StatCard(
                      title: 'Listed Hospitals',
                      value: '$totalHospitals',
                      icon: Icons.local_hospital_rounded,
                      color: AppColors.primary,
                      subtitle: 'Active blood centers',
                    ),
                    StatCard(
                      title: 'Total Sachets',
                      value: '$totalUnits',
                      icon: Icons.water_drop_rounded,
                      color: Colors.red.shade800,
                      subtitle: 'Across all groups',
                    ),
                    StatCard(
                      title: 'Total Requests',
                      value: '$totalOrders',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.accent,
                      subtitle: 'Customer orders',
                    ),
                    StatCard(
                      title: 'Pending Orders',
                      value: '$pendingOrders',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.warning,
                      subtitle: 'Awaiting dispatch',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 2. Network Blood Stock Breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Network Inventory by Blood Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$totalUnits Sachets Total',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Distribution bars
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: BloodBank.standardBloodGroups.map((group) {
                      final count = distribution[group] ?? 0;
                      final fraction = totalUnits > 0 ? (count / totalUnits).clamp(0.0, 1.0) : 0.0;

                      return SizedBox(
                        width: 140,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    group,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    '$count units',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: fraction,
                                backgroundColor: Colors.grey.shade300,
                                color: count < 10 ? AppColors.warning : AppColors.primary,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Admin Actions & Management Hub
            const Text(
              'System Management & Audits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    context: context,
                    title: 'Manage Hospitals',
                    subtitle: '$totalHospitals Blood Banks listed',
                    icon: Icons.domain_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageHospitalsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildActionTile(
                    context: context,
                    title: 'Customer Orders',
                    subtitle: '$totalOrders Requests recorded',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllRequestsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            ElevatedButton.icon(
              onPressed: () => AddHospitalDialog.show(context),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Register New Blood Bank in Network'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
