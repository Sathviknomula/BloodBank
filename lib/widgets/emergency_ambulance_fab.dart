import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/blood_bank.dart';
import '../providers/app_state_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_colors.dart';

class EmergencyAmbulanceFab extends StatelessWidget {
  const EmergencyAmbulanceFab({super.key});

  Future<void> _makeCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _handleAmbulancePress(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final locProvider = context.read<LocationProvider>();

    final hospitals = List<BloodBank>.from(appState.bloodBanks.where((h) => h.isActive));

    BloodBank? nearestHospital;
    double minDistance = double.infinity;

    for (final h in hospitals) {
      final dist = locProvider.getDistanceKm(h);
      if (dist < minDistance) {
        minDistance = dist;
        nearestHospital = h;
      }
    }

    // If no hospital or distance is greater than 30 km, fallback directly to 108 Govt Ambulance
    final bool hasNearby = nearestHospital != null && minDistance <= 30.0;
    final String targetNumber = hasNearby ? nearestHospital.emergencyPhone : '108';
    final String targetName = hasNearby
        ? '${nearestHospital.name} Ambulance'
        : '108 Govt National Emergency Ambulance';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: AppColors.danger,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Ambulance SOS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        hasNearby
                            ? 'Nearest hospital detected (${minDistance.toStringAsFixed(1)} km away)'
                            : 'No nearby hospitals detected • Routing to Govt 108',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasNearby ? AppColors.textSecondary : AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Ambulance Call Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasNearby ? Icons.local_hospital_rounded : Icons.support_agent_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          targetName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Emergency Number: $targetNumber',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _makeCall(targetNumber);
                      },
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                      label: Text(
                        hasNearby ? 'Call Hospital Ambulance Now' : 'Call 108 Govt Ambulance Now',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Secondary option if a hospital was selected: Always offer 108 National Backup
            if (hasNearby) ...[
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _makeCall('108');
                },
                icon: const Icon(Icons.emergency_outlined, size: 18, color: AppColors.danger),
                label: const Text(
                  'Call 108 Govt National Ambulance Service (Toll-Free)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.danger.withAlpha(100)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
              const SizedBox(height: 10),
            ],

            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _handleAmbulancePress(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.emergency_rounded, size: 22),
      label: const Text(
        'Ambulance SOS (108)',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2),
      ),
    );
  }
}
