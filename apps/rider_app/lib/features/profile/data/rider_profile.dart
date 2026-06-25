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
    this.avatarUrl,
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
  final String? avatarUrl;
  final String? vehicleType;
  final String? vehicleModel;
  final String? vehicleRegistration;
  final String? zone;
  final double? ratingAvg;
  final List<RiderDocumentView> documents;

  bool get isApproved => approvalStatus == 'APPROVED';

  bool get hasWorkDetails =>
      _hasText(vehicleType) ||
      _hasText(vehicleModel) ||
      _hasText(vehicleRegistration) ||
      _hasText(zone);

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  factory RiderProfileView.fromJson(Map<String, dynamic> json) {
    final root = _unwrap(json);
    final user = root['user'];
    final docs = root['documents'];
    return RiderProfileView(
      fullName: _str(root['fullName']) ?? 'Rider',
      phone: user is Map ? _str(user['phone']) : _str(root['phone']),
      approvalStatus: _str(root['approvalStatus']) ?? 'PENDING',
      isOnline: root['isOnline'] == true,
      avatarUrl: _str(root['avatarUrl'] ?? root['avatar_url']),
      vehicleType: _str(root['vehicleType'] ?? root['vehicle_type']),
      vehicleModel: _str(root['vehicleModel'] ?? root['vehicle_model']),
      vehicleRegistration: _str(
        root['vehicleRegistration'] ??
            root['vehicle_registration'] ??
            root['plate'],
      ),
      zone: _str(root['zone'] ?? root['deliveryZone'] ?? root['delivery_zone']),
      ratingAvg: _asDouble(root['ratingAvg'] ?? root['rating_avg']),
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

Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
  final nested = json['data'] ?? json['profile'] ?? json['riderProfile'];
  if (nested is Map) {
    return Map<String, dynamic>.from(nested);
  }
  return json;
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
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
