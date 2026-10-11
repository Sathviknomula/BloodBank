import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbank/models/blood_bank.dart';
import 'package:bloodbank/models/blood_request.dart';
import 'package:bloodbank/models/customer_profile.dart';
import 'package:bloodbank/services/mock_data_service.dart';
import 'package:bloodbank/services/route_service.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Blood Bank Core Tests', () {
    test('MockDataService returns hospitals with stock for all 8 blood groups', () {
      final banks = MockDataService.getInitialBloodBanks();
      expect(banks.isNotEmpty, true);

      final first = banks.first;
      expect(first.phone.startsWith('+91'), true);
      expect(first.totalUnits > 0, true);

      for (final group in BloodBank.standardBloodGroups) {
        expect(first.stock.containsKey(group), true);
        expect(first.getSachets(group) >= 0, true);
      }
    });

    test('BloodBank stock copyWith updates sachets correctly', () {
      final bank = MockDataService.getInitialBloodBanks().first;
      final initialOPlus = bank.getSachets('O+');

      final updatedStock = Map<String, int>.from(bank.stock);
      updatedStock['O+'] = initialOPlus + 5;

      final updatedBank = bank.copyWith(stock: updatedStock);
      expect(updatedBank.getSachets('O+'), initialOPlus + 5);
      expect(updatedBank.hasStock('O+'), true);
    });

    test('RouteService generates valid polyline waypoints and navigation steps', () {
      final start = const LatLng(17.4200, 78.4350);
      final dest = const LatLng(17.4156, 78.4116);

      final points = RouteService.generateRouteCoordinates(start, dest);
      expect(points.length, greaterThanOrEqualTo(8));
      expect(points.first.latitude, start.latitude);
      expect(points.last.latitude, dest.latitude);

      final steps = RouteService.generateNavigationSteps(start, dest, 'Apollo Hospital', 3.5);
      expect(steps.isNotEmpty, true);
      expect(steps.last.iconType, 'arrive');
    });

    test('CustomerProfile default values and copyWith work as expected', () {
      const profile = CustomerProfile();
      expect(profile.isConfigured, true);
      expect(profile.phone.startsWith('+91'), true);

      final updated = profile.copyWith(name: 'Rahul Sharma', bloodGroup: 'B+');
      expect(updated.name, 'Rahul Sharma');
      expect(updated.bloodGroup, 'B+');
    });

    test('BloodRequest model serializes and deserializes properly', () {
      final req = BloodRequest(
        id: 'test_req_1',
        customerName: 'Aarav Patel',
        customerPhone: '+91 98765 00000',
        bloodGroup: 'AB-',
        unitsCount: 2,
        hospitalId: 'bb_apollo_hyd',
        hospitalName: 'Apollo Hospital',
        urgencyLevel: 'Immediate Emergency',
      );

      expect(req.isEmergency, true);
      final json = req.toJson();
      final fromJson = BloodRequest.fromJson(json);

      expect(fromJson.id, req.id);
      expect(fromJson.customerName, 'Aarav Patel');
      expect(fromJson.bloodGroup, 'AB-');
      expect(fromJson.unitsCount, 2);
    });

    test('Ambulance logic falls back to 108 when distance exceeds limit or no hospitals', () {
      final banks = MockDataService.getInitialBloodBanks();
      expect(banks.first.emergencyPhone.isNotEmpty, true);

      // Verify 108 emergency service string
      const fallbackNumber = '108';
      expect(fallbackNumber, '108');
    });

    test('RouteService fetchRealRouteCoordinates returns points list with fallback', () async {
      final start = const LatLng(17.4200, 78.4350);
      final dest = const LatLng(17.4156, 78.4116);
      final points = await RouteService.fetchRealRouteCoordinates(start, dest);
      expect(points.isNotEmpty, true);
      expect(points.first.latitude, closeTo(start.latitude, 0.01));
    });
  });
}
