import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(apiClientProvider));
});

/// Document types the rider can upload during onboarding. Values match the
/// backend `RiderDocumentType` enum.
enum RiderDocType {
  nid('NID', 'National ID (NID)'),
  drivingLicense('DRIVING_LICENSE', 'Driving License'),
  vehicleRegistration('VEHICLE_REGISTRATION', 'Vehicle Registration'),
  insurance('INSURANCE', 'Insurance');

  const RiderDocType(this.wire, this.label);

  /// The enum value the backend expects.
  final String wire;

  /// Human-readable label for the UI.
  final String label;
}

/// Talks to the rider self-service + registration endpoints used by the
/// onboarding flow. Mirrors [AuthRepository]'s error-unwrapping convention.
class OnboardingRepository {
  OnboardingRepository(this._api);

  final ApiClient _api;

  /// Registers a new rider and persists the returned tokens so subsequent
  /// document/profile calls are authenticated. The rider is created PENDING;
  /// operational endpoints stay gated until an admin approves.
  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? vehicleType,
  }) async {
    try {
      final res = await _api.post(
        ApiEndpoints.registerRider,
        data: {
          'fullName': fullName,
          'phone': phone,
          'email': email,
          'password': password,
          if (vehicleType != null && vehicleType.isNotEmpty)
            'vehicleType': vehicleType,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      if (access == null || refresh == null) {
        throw Exception('Registration did not return a session');
      }
      await _api.saveTokens(access, refresh);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Registration failed. Please try again.'));
    }
  }

  /// Updates the rider's work details (vehicle + zone). Requires a session.
  Future<void> updateWorkDetails({
    String? vehicleType,
    String? vehicleModel,
    String? vehicleRegistration,
    String? zone,
  }) async {
    try {
      await _api.patch(
        ApiEndpoints.riderProfile,
        data: {
          'vehicleType': ?vehicleType,
          'vehicleModel': ?vehicleModel,
          'vehicleRegistration': ?vehicleRegistration,
          'zone': ?zone,
        },
      );
    } on DioException catch (e) {
      throw Exception(_message(e, 'Could not save your work details.'));
    }
  }

  /// Uploads one verification document (multipart). Requires a session.
  Future<void> uploadDocument({
    required RiderDocType type,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final form = FormData.fromMap({
        'type': type.wire,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: _contentTypeFor(fileName),
        ),
      });
      await _api.post(ApiEndpoints.riderDocuments, data: form);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Could not upload the document.'));
    }
  }

  /// Clears the onboarding session tokens.
  ///
  /// The token issued at registration only authenticates the document/work-
  /// details steps. Once onboarding completes the rider is still PENDING, so we
  /// discard the session — they must log in (which is approval-gated) once
  /// approved, rather than silently landing in the app on restart.
  Future<void> clearSession() => _api.clearTokens();

  /// Sends a 6-digit OTP to [email] for post-registration email verification.
  /// Returns the devCode if the backend is running in development mode.
  Future<String?> sendEmailOtp(String email) async {
    try {
      final res = await _api.post(
        ApiEndpoints.otpSend,
        data: {'email': email, 'purpose': 'VERIFY_PHONE'}, // Using VERIFY_PHONE purpose for standard verification
      );
      final data = res.data as Map<String, dynamic>;
      return data['devCode'] as String?;
    } on DioException catch (e) {
      throw Exception(_message(e, 'Could not send verification code.'));
    }
  }

  /// Verifies the 6-digit [code] sent to [email].
  Future<void> verifyEmailOtp(String email, String code) async {
    try {
      await _api.post(
        ApiEndpoints.otpVerify,
        data: {'email': email, 'code': code, 'purpose': 'VERIFY_PHONE'},
      );
    } on DioException catch (e) {
      throw Exception(_message(e, 'Invalid or expired code.'));
    }
  }

  MediaType? _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  String _message(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      return m is List ? m.first.toString() : m.toString();
    }
    return fallback;
  }
}
