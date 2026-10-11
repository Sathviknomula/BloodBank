import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blood_bank.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stock_counter_tile.dart';

class StockEditorScreen extends StatelessWidget {
  final BloodBank hospital;

  const StockEditorScreen({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    // Fetch latest instance of this hospital from app state
    final currentBank = appState.bloodBanks.firstWhere(
      (b) => b.id == hospital.id,
      orElse: () => hospital,
    );

    final totalUnits = currentBank.totalUnits;
    final lowStockGroups = BloodBank.standardBloodGroups.where(
      (g) => currentBank.getSachets(g) < 5,
    ).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Stock Overview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8E0000), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(70),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
                      'Live Blood Inventory',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sync_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Real-Time Synced',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$totalUnits',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Total Sachets in Reserve',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (lowStockGroups.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withAlpha(200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Low Stock Alert in: ${lowStockGroups.join(", ")} (<5 sachets)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Sachets by Blood Group',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Tap count to edit exact',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sachet tiles for all 8 standard blood groups
          ...BloodBank.standardBloodGroups.map((group) {
            final count = currentBank.getSachets(group);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StockCounterTile(
                bloodGroup: group,
                count: count,
                onDelta: (delta) {
                  appState.adjustStock(currentBank.id, group, delta);
                },
                onSetExact: (exact) {
                  appState.setStock(currentBank.id, group, exact);
                },
              ),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
