class BloodRequest {
  final String id;
  final String customerName;
  final String customerPhone;
  final String bloodGroup;
  final int unitsCount;
  final String hospitalId;
  final String hospitalName;
  final String urgencyLevel; // 'Immediate Emergency', 'Within 4 Hours', 'Normal / Scheduled'
  final String status; // 'Pending', 'Approved', 'Dispensed', 'Rejected'
  final DateTime createdAt;
  final String notes;

  BloodRequest({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.bloodGroup,
    required this.unitsCount,
    required this.hospitalId,
    required this.hospitalName,
    this.urgencyLevel = 'Immediate Emergency',
    this.status = 'Pending',
    DateTime? createdAt,
    this.notes = '',
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isEmergency => urgencyLevel.toLowerCase().contains('emergency');

  BloodRequest copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? bloodGroup,
    int? unitsCount,
    String? hospitalId,
    String? hospitalName,
    String? urgencyLevel,
    String? status,
    DateTime? createdAt,
    String? notes,
  }) {
    return BloodRequest(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      unitsCount: unitsCount ?? this.unitsCount,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'bloodGroup': bloodGroup,
      'unitsCount': unitsCount,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'urgencyLevel': urgencyLevel,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      bloodGroup: json['bloodGroup'] as String,
      unitsCount: (json['unitsCount'] as num?)?.toInt() ?? 1,
      hospitalId: json['hospitalId'] as String,
      hospitalName: json['hospitalName'] as String,
      urgencyLevel: json['urgencyLevel'] as String? ?? 'Immediate Emergency',
      status: json['status'] as String? ?? 'Pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String? ?? '',
    );
  }
}
