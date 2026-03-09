import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/email_templates_api.dart';
import 'package:my_app/core/data/models/email_template.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'email_templates_repository.g.dart';

/// Email templates (backend-cheatsheet §2). Admin only.
class EmailTemplatesRepository {
  EmailTemplatesRepository({EmailTemplatesApi? api}) : _api = api ?? EmailTemplatesApi(ApiClient.instance);
  final EmailTemplatesApi _api;

  Future<List<EmailTemplate>> list() async {
    return _api.list();
  }

  Future<EmailTemplate?> getByName(String name) async {
    return _api.getByName(name);
  }

  Future<void> upsert(EmailTemplate t) async {
    await _api.upsert(t);
  }

  Future<void> delete(String name) async {
    await _api.delete(name);
  }
}

@riverpod
EmailTemplatesRepository emailTemplatesRepository(EmailTemplatesRepositoryRef ref) {
  return EmailTemplatesRepository(api: ref.watch(emailTemplatesApiProvider));
}
