class BloodBank {
  final String id;
  final String name;
  final String city;
  final String address;
  final String phone;
  final String emergencyPhone;
  final double latitude;
  final double longitude;
  final String operatingHours;
  final String managerEmail;
  final String managerPassword;
  final Map<String, int> stock; // e.g. {'A+': 12, 'O+': 20, ...}
  final bool isActive;
  final DateTime lastUpdated;

  static const List<String> standardBloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  BloodBank({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    required this.emergencyPhone,
    required this.latitude,
    required this.longitude,
    required this.operatingHours,
    required this.managerEmail,
    required this.managerPassword,
    required this.stock,
    this.isActive = true,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  int getSachets(String bloodGroup) {
    return stock[bloodGroup] ?? 0;
  }

  int get totalUnits => stock.values.fold(0, (a, b) => a + b);

  bool hasStock(String bloodGroup) {
    return (stock[bloodGroup] ?? 0) > 0;
  }

  BloodBank copyWith({
    String? id,
    String? name,
    String? city,
    String? address,
    String? phone,
    String? emergencyPhone,
    double? latitude,
    double? longitude,
    String? operatingHours,
    String? managerEmail,
    String? managerPassword,
    Map<String, int>? stock,
    bool? isActive,
    DateTime? lastUpdated,
  }) {
    return BloodBank(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      operatingHours: operatingHours ?? this.operatingHours,
      managerEmail: managerEmail ?? this.managerEmail,
      managerPassword: managerPassword ?? this.managerPassword,
      stock: stock != null ? Map<String, int>.from(stock) : Map<String, int>.from(this.stock),
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'phone': phone,
      'emergencyPhone': emergencyPhone,
      'latitude': latitude,
      'longitude': longitude,
      'operatingHours': operatingHours,
      'managerEmail': managerEmail,
      'managerPassword': managerPassword,
      'stock': stock,
      'isActive': isActive,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory BloodBank.fromJson(Map<String, dynamic> json) {
    final rawStock = json['stock'] as Map<String, dynamic>? ?? {};
    final parsedStock = <String, int>{};
    for (final group in standardBloodGroups) {
      parsedStock[group] = (rawStock[group] as num?)?.toInt() ?? 0;
    }

    return BloodBank(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      emergencyPhone: json['emergencyPhone'] as String? ?? json['phone'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      operatingHours: json['operatingHours'] as String? ?? '24/7 Open',
      managerEmail: json['managerEmail'] as String? ?? '',
      managerPassword: json['managerPassword'] as String? ?? '',
      stock: parsedStock,
      isActive: json['isActive'] as bool? ?? true,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
