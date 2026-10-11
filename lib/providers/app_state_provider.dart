import 'package:flutter/material.dart';
import '../models/blood_bank.dart';
import '../models/blood_request.dart';
import '../models/customer_profile.dart';
import '../models/user_role.dart';
import '../services/firebase_auth_service.dart';
import '../services/storage_service.dart';

class AppStateProvider with ChangeNotifier {
  final StorageService _storageService;

  List<BloodBank> _bloodBanks = [];
  List<BloodRequest> _requests = [];
  CustomerProfile _customerProfile = const CustomerProfile();

  UserRole _currentRole = UserRole.customer;
  BloodBank? _currentLoggedInBank;
  String _selectedBloodGroupFilter = 'All';
  String _searchQuery = '';
  double? _maxDistanceKm; // Optional radius filter

  AppStateProvider(this._storageService) {
    _loadInitialData();
  }

  // Getters
  List<BloodBank> get bloodBanks => List.unmodifiable(_bloodBanks);
  List<BloodRequest> get requests => List.unmodifiable(_requests);
  CustomerProfile get customerProfile => _customerProfile;
  UserRole get currentRole => _currentRole;
  BloodBank? get currentLoggedInBank => _currentLoggedInBank;
  String get selectedBloodGroupFilter => _selectedBloodGroupFilter;
  String get searchQuery => _searchQuery;
  double? get maxDistanceKm => _maxDistanceKm;

  void _loadInitialData() {
    _bloodBanks = _storageService.loadBloodBanks();
    _requests = _storageService.loadRequests();
    _customerProfile = _storageService.loadCustomerProfile();
    notifyListeners();
  }

  // Role Management
  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  bool loginHospital(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    // 1. Check if steaverogers111@gmail.com is logging into hospital portal
    if (FirebaseAuthService.isAuthorizedHospitalManager(cleanEmail, cleanPass)) {
      _currentLoggedInBank = _bloodBanks.isNotEmpty ? _bloodBanks.first : null;
      _currentRole = UserRole.hospitalManager;
      notifyListeners();
      return true;
    }

    // 2. Check registered hospital manager credentials
    try {
      final bank = _bloodBanks.firstWhere(
        (b) => b.managerEmail.toLowerCase() == cleanEmail && b.managerPassword == cleanPass,
      );
      _currentLoggedInBank = bank;
      _currentRole = UserRole.hospitalManager;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool loginAdmin(String email, String password) {
    if (FirebaseAuthService.verifyAdminCredentials(email, password)) {
      _currentRole = UserRole.admin;
      _currentLoggedInBank = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentRole = UserRole.customer;
    _currentLoggedInBank = null;
    notifyListeners();
  }

  // Filter & Search
  void setBloodGroupFilter(String group) {
    _selectedBloodGroupFilter = group;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setMaxDistanceKm(double? maxDist) {
    _maxDistanceKm = maxDist;
    notifyListeners();
  }

  // Filtered Blood Banks for Customers
  List<BloodBank> get filteredBloodBanks {
    return _bloodBanks.where((bank) {
      if (!bank.isActive) return false;

      // Filter by search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = bank.name.toLowerCase().contains(q);
        final matchCity = bank.city.toLowerCase().contains(q);
        final matchAddress = bank.address.toLowerCase().contains(q);
        if (!matchName && !matchCity && !matchAddress) return false;
      }

      // Filter by selected blood group
      if (_selectedBloodGroupFilter != 'All') {
        final available = bank.getSachets(_selectedBloodGroupFilter);
        if (available <= 0) return false;
      }

      return true;
    }).toList();
  }

  // Stock Management
  Future<void> adjustStock(String hospitalId, String bloodGroup, int delta) async {
    final index = _bloodBanks.indexWhere((b) => b.id == hospitalId);
    if (index != -1) {
      final bank = _bloodBanks[index];
      final currentSachets = bank.getSachets(bloodGroup);
      final newSachets = (currentSachets + delta).clamp(0, 9999);

      final updatedStock = Map<String, int>.from(bank.stock);
      updatedStock[bloodGroup] = newSachets;

      final updatedBank = bank.copyWith(
        stock: updatedStock,
        lastUpdated: DateTime.now(),
      );

      _bloodBanks[index] = updatedBank;

      if (_currentLoggedInBank?.id == hospitalId) {
        _currentLoggedInBank = updatedBank;
      }

      await _storageService.saveBloodBanks(_bloodBanks);
      notifyListeners();
    }
  }

  Future<void> setStock(String hospitalId, String bloodGroup, int exactCount) async {
    final index = _bloodBanks.indexWhere((b) => b.id == hospitalId);
    if (index != -1) {
      final bank = _bloodBanks[index];
      final updatedStock = Map<String, int>.from(bank.stock);
      updatedStock[bloodGroup] = exactCount.clamp(0, 9999);

      final updatedBank = bank.copyWith(
        stock: updatedStock,
        lastUpdated: DateTime.now(),
      );

      _bloodBanks[index] = updatedBank;
      if (_currentLoggedInBank?.id == hospitalId) {
        _currentLoggedInBank = updatedBank;
      }

      await _storageService.saveBloodBanks(_bloodBanks);
      notifyListeners();
    }
  }

  // Hospital Management & Profile
  Future<void> updateHospital(BloodBank updated) async {
    final index = _bloodBanks.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _bloodBanks[index] = updated;
      if (_currentLoggedInBank?.id == updated.id) {
        _currentLoggedInBank = updated;
      }
      await _storageService.saveBloodBanks(_bloodBanks);
      notifyListeners();
    }
  }

  Future<void> addHospital(BloodBank newBank) async {
    _bloodBanks.insert(0, newBank);
    await _storageService.saveBloodBanks(_bloodBanks);
    notifyListeners();
  }

  Future<void> deleteHospital(String id) async {
    _bloodBanks.removeWhere((b) => b.id == id);
    if (_currentLoggedInBank?.id == id) {
      _currentLoggedInBank = null;
    }
    await _storageService.saveBloodBanks(_bloodBanks);
    notifyListeners();
  }

  // Customer Profile
  Future<void> updateCustomerProfile(CustomerProfile profile) async {
    _customerProfile = profile;
    await _storageService.saveCustomerProfile(profile);
    notifyListeners();
  }

  // Blood Requests / Orders
  Future<void> createBloodRequest({
    required String hospitalId,
    required String hospitalName,
    required String bloodGroup,
    required int unitsCount,
    required String urgencyLevel,
    String notes = '',
  }) async {
    final newRequest = BloodRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      customerName: _customerProfile.name.isEmpty ? 'Anonymous' : _customerProfile.name,
      customerPhone: _customerProfile.phone.isEmpty ? '+91' : _customerProfile.phone,
      bloodGroup: bloodGroup,
      unitsCount: unitsCount,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
      urgencyLevel: urgencyLevel,
      status: 'Pending',
      createdAt: DateTime.now(),
      notes: notes,
    );

    _requests.insert(0, newRequest);
    await _storageService.saveRequests(_requests);
    notifyListeners();
  }

  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final req = _requests[index];
      _requests[index] = req.copyWith(status: newStatus);

      if (newStatus == 'Dispensed' && req.status != 'Dispensed') {
        await adjustStock(req.hospitalId, req.bloodGroup, -req.unitsCount);
      }

      await _storageService.saveRequests(_requests);
      notifyListeners();
    }
  }

  List<BloodRequest> getRequestsForHospital(String hospitalId) {
    return _requests.where((r) => r.hospitalId == hospitalId).toList();
  }

  // System & Analytics Getters
  int get totalHospitalsListed => _bloodBanks.length;
  int get totalUnitsAvailable => _bloodBanks.fold(0, (sum, b) => sum + b.totalUnits);
  int get totalOrdersPlaced => _requests.length;
  int get pendingOrdersCount => _requests.where((r) => r.status == 'Pending').length;
  int get dispensedOrdersCount => _requests.where((r) => r.status == 'Dispensed').length;

  Map<String, int> get networkStockDistribution {
    final distribution = <String, int>{};
    for (final group in BloodBank.standardBloodGroups) {
      distribution[group] = 0;
    }
    for (final bank in _bloodBanks) {
      for (final group in BloodBank.standardBloodGroups) {
        distribution[group] = (distribution[group] ?? 0) + bank.getSachets(group);
      }
    }
    return distribution;
  }

  Future<void> resetToDefaults() async {
    await _storageService.resetToDefaults();
    _loadInitialData();
  }
}
