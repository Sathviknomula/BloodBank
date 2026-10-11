import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blood_bank.dart';
import '../models/blood_request.dart';
import '../models/customer_profile.dart';
import 'mock_data_service.dart';

class StorageService {
  static const _keyBloodBanks = 'blood_banks_data_v1';
  static const _keyBloodRequests = 'blood_requests_data_v1';
  static const _keyCustomerProfile = 'customer_profile_data_v1';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Load Blood Banks
  List<BloodBank> loadBloodBanks() {
    final raw = _prefs.getString(_keyBloodBanks);
    if (raw == null || raw.isEmpty) {
      final initial = MockDataService.getInitialBloodBanks();
      saveBloodBanks(initial);
      return initial;
    }
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => BloodBank.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return MockDataService.getInitialBloodBanks();
    }
  }

  Future<bool> saveBloodBanks(List<BloodBank> banks) {
    final encoded = jsonEncode(banks.map((e) => e.toJson()).toList());
    return _prefs.setString(_keyBloodBanks, encoded);
  }

  // Load Requests
  List<BloodRequest> loadRequests() {
    final raw = _prefs.getString(_keyBloodRequests);
    if (raw == null || raw.isEmpty) {
      final initial = MockDataService.getInitialRequests();
      saveRequests(initial);
      return initial;
    }
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => BloodRequest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return MockDataService.getInitialRequests();
    }
  }

  Future<bool> saveRequests(List<BloodRequest> requests) {
    final encoded = jsonEncode(requests.map((e) => e.toJson()).toList());
    return _prefs.setString(_keyBloodRequests, encoded);
  }

  // Load Customer Profile
  CustomerProfile loadCustomerProfile() {
    final raw = _prefs.getString(_keyCustomerProfile);
    if (raw == null || raw.isEmpty) {
      return const CustomerProfile();
    }
    try {
      return CustomerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const CustomerProfile();
    }
  }

  Future<bool> saveCustomerProfile(CustomerProfile profile) {
    return _prefs.setString(_keyCustomerProfile, jsonEncode(profile.toJson()));
  }

  // Reset to Factory Default Data
  Future<void> resetToDefaults() async {
    await saveBloodBanks(MockDataService.getInitialBloodBanks());
    await saveRequests(MockDataService.getInitialRequests());
    await saveCustomerProfile(const CustomerProfile());
  }
}
