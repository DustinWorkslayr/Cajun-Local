import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/admin/data/models/email_template.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'email_templates_api.g.dart';

class EmailTemplatesApi {
  EmailTemplatesApi(this._client);
  final ApiClient _client;

  Future<List<EmailTemplate>> list() async {
    try {
      final response = await _client.dio.get('/email-templates/');
      final data = response.data as List;
      return data.map((json) => EmailTemplate.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list email templates');
    }
  }

  Future<EmailTemplate?> getByName(String name) async {
    try {
      final response = await _client.dio.get('/email-templates/$name');
      return EmailTemplate.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get email template');
    }
  }

  Future<void> upsert(EmailTemplate template) async {
    try {
      await _client.dio.put('/email-templates/', data: template.toJson());
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to upsert email template');
    }
  }

  Future<void> delete(String name) async {
    try {
      await _client.dio.delete('/email-templates/$name');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to delete email template');
    }
  }
}

@riverpod
EmailTemplatesApi emailTemplatesApi(EmailTemplatesApiRef ref) {
  return EmailTemplatesApi(ApiClient.instance);
}
