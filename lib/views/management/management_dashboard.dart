import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';
import 'hospital_orders_screen.dart';
import 'hospital_profile_edit.dart';
import 'stock_editor_screen.dart';

class ManagementDashboard extends StatefulWidget {
  const ManagementDashboard({super.key});

  @override
  State<ManagementDashboard> createState() => _ManagementDashboardState();
}

class _ManagementDashboardState extends State<ManagementDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final bank = appState.currentLoggedInBank ?? appState.bloodBanks.first;
    final pendingOrders = appState.getRequestsForHospital(bank.id).where((r) => r.status == 'Pending').length;

    final screens = [
      StockEditorScreen(hospital: bank),
      HospitalOrdersScreen(hospital: bank),
      HospitalProfileEdit(hospital: bank),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bank.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${bank.city} • Stock Manager Portal',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
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
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
            label: 'Blood Stock',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingOrders > 0,
              label: Text('$pendingOrders'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendingOrders > 0,
              label: Text('$pendingOrders'),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            ),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital_rounded, color: AppColors.primary),
            label: 'Hospital Info',
          ),
        ],
      ),
    );
  }
}
