import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_role.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';
import '../customer/customer_home_screen.dart';
import 'hospital_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color iconBg,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? AppColors.primary : AppColors.border,
          width: isPrimary ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? AppColors.primary.withAlpha(25)
                : Colors.black.withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),

                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPrimary ? AppColors.primaryTint : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isPrimary ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Brand Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(90),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bloodtype_rounded,
                            color: Colors.white,
                            size: 46,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Blood Bank Network',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Real-Time Blood Availability, Live Tracking & Stock Management across India',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section Title
                  const Text(
                    'Select How You Want to Continue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Option 1: Customer (NO LOGIN NEEDED)
                  _buildRoleCard(
                    context: context,
                    title: 'Recipient / Customer',
                    subtitle: 'Find blood sachets, calculate real-time distance/ETA, call hospitals & track live route on map.',
                    badgeText: 'Instant Access (No Login)',
                    icon: Icons.person_pin_circle_rounded,
                    iconBg: AppColors.primary,
                    isPrimary: true,
                    onTap: () {
                      appState.setRole(UserRole.customer);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                      );
                    },
                  ),

                  // Option 2: Blood Bank Management (Email/Password)
                  _buildRoleCard(
                    context: context,
                    title: 'Blood Bank Management',
                    subtitle: 'Manage blood stock sachets per group (A+, B+, etc.), update hospital contact info & fulfill orders.',
                    badgeText: 'Hospital Login',
                    icon: Icons.domain_rounded,
                    iconBg: AppColors.accent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HospitalLoginScreen(isAdminLogin: false),
                        ),
                      );
                    },
                  ),

                  // Option 3: Developer / Admin (Full Audit & CRUD)
                  _buildRoleCard(
                    context: context,
                    title: 'Developer / Admin',
                    subtitle: 'Executive overview, manage registered hospitals, view network request audit logs & analytics.',
                    badgeText: 'Admin Portal',
                    icon: Icons.admin_panel_settings_rounded,
                    iconBg: const Color(0xFF37474F),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HospitalLoginScreen(isAdminLogin: true),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Network Live Summary Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatTicker(
                          label: 'Hospitals',
                          value: '${appState.totalHospitalsListed}',
                          icon: Icons.local_hospital,
                        ),
                        Container(height: 28, width: 1, color: AppColors.border),
                        _buildStatTicker(
                          label: 'Units Available',
                          value: '${appState.totalUnitsAvailable}',
                          icon: Icons.water_drop,
                        ),
                        Container(height: 28, width: 1, color: AppColors.border),
                        _buildStatTicker(
                          label: 'Orders Handled',
                          value: '${appState.totalOrdersPlaced}',
                          icon: Icons.receipt_long,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTicker({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
