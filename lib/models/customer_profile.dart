class CustomerProfile {
  final String name;
  final String phone;
  final String bloodGroup;

  const CustomerProfile({
    this.name = 'Priya Sharma',
    this.phone = '+91 98765 43210',
    this.bloodGroup = 'O+',
  });

  bool get isConfigured => name.trim().isNotEmpty && phone.trim().isNotEmpty;

  CustomerProfile copyWith({
    String? name,
    String? phone,
    String? bloodGroup,
  }) {
    return CustomerProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'bloodGroup': bloodGroup,
    };
  }

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      name: json['name'] as String? ?? 'Priya Sharma',
      phone: json['phone'] as String? ?? '+91 98765 43210',
      bloodGroup: json['bloodGroup'] as String? ?? 'O+',
    );
  }
}
