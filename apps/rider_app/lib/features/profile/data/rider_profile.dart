/// Typed view of the rider's own profile from `GET /rider/profile`.
///
/// Parsing is tolerant: missing/!typed fields degrade to null/empty rather than
/// throwing, so the profile screen always renders something.
class RiderProfileView {
  const RiderProfileView({
    required this.fullName,
    required this.phone,
    required this.approvalStatus,
    required this.isOnline,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleRegistration,
    this.zone,
    this.ratingAvg,
    this.documents = const [],
  });

  final String fullName;
  final String? phone;
  final String approvalStatus; // PENDING | APPROVED | REJECTED | SUSPENDED
  final bool isOnline;
  final String? vehicleType;
  final String? vehicleModel;
  final String? vehicleRegistration;
  final String? zone;
  final double? ratingAvg;
  final List<RiderDocumentView> documents;

  bool get isApproved => approvalStatus == 'APPROVED';

  factory RiderProfileView.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final docs = json['documents'];
    return RiderProfileView(
      fullName: _str(json['fullName']) ?? 'Rider',
      phone: user is Map ? _str(user['phone']) : null,
      approvalStatus: _str(json['approvalStatus']) ?? 'PENDING',
      isOnline: json['isOnline'] == true,
      vehicleType: _str(json['vehicleType']),
      vehicleModel: _str(json['vehicleModel']),
      vehicleRegistration: _str(json['vehicleRegistration']),
      zone: _str(json['zone']),
      ratingAvg: (json['ratingAvg'] is num)
          ? (json['ratingAvg'] as num).toDouble()
          : null,
      documents: docs is List
          ? docs
              .whereType<Map>()
              .map((d) => RiderDocumentView.fromJson(
                    Map<String, dynamic>.from(d),
                  ))
              .toList()
          : const [],
    );
  }
}

/// One uploaded verification document.
class RiderDocumentView {
  const RiderDocumentView({
    required this.type,
    required this.status,
    this.url,
  });

  final String type; // NID | DRIVING_LICENSE | …
  final String status; // PENDING | APPROVED | REJECTED
  final String? url;

  /// Human-readable label for the document type.
  String get label => switch (type) {
        'NID' => 'National ID',
        'DRIVING_LICENSE' => 'Driving License',
        'VEHICLE_REGISTRATION' => 'Vehicle Registration',
        'INSURANCE' => 'Insurance',
        _ => 'Document',
      };

  factory RiderDocumentView.fromJson(Map<String, dynamic> json) {
    return RiderDocumentView(
      type: _str(json['type']) ?? 'OTHER',
      status: _str(json['status']) ?? 'PENDING',
      url: _str(json['url']),
    );
  }
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
