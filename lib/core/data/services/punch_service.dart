import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'punch_service.g.dart';

class PunchService {
  PunchService(this._client);
  final ApiClient _client;

  /// Generate a one-time punch token for the given program (customer).
  /// Returns the JWT token to display as QR. Valid 5 min.
  Future<String> generatePunchToken(String programId) async {
    try {
      final response = await _client.dio.post('/punch-cards/token', data: {'program_id': programId});
      return response.data['token'] as String;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Failed to generate token';
      throw PunchException(detail.toString());
    }
  }

  /// Validate a punch token (business owner).
  Future<PunchValidateResult> validatePunch(String punchToken, {int punches = 1}) async {
    try {
      final response = await _client.dio.post(
        '/punch-cards/validate',
        data: {'punch_token': punchToken.trim(), 'punches': punches},
      );

      final data = response.data;
      return PunchValidateResult(
        success: data['success'] as bool? ?? false,
        message: data['message'] as String? ?? 'Punch recorded',
      );
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Validation failed';
      return PunchValidateResult(success: false, message: detail.toString());
    }
  }
}

class PunchException implements Exception {
  PunchException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PunchValidateResult {
  const PunchValidateResult({required this.success, this.message});
  final bool success;
  final String? message;
}

@riverpod
PunchService punchService(PunchServiceRef ref) {
  return PunchService(ApiClient.instance);
}
