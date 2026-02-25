import 'package:my_app/core/data/models/email_template.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Email templates (backend-cheatsheet §2). Admin only.
class EmailTemplatesRepository {
  EmailTemplatesRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  Future<List<EmailTemplate>> list() async {
    final client = _client;
    if (client == null) return [];
    final list = await client.from('email_templates').select();
    return (list as List).map((e) => EmailTemplate.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EmailTemplate?> getByName(String name) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('email_templates').select().eq('name', name).maybeSingle();
    if (res == null) return null;
    return EmailTemplate.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> upsert(EmailTemplate t) async {
    final client = _client;
    if (client == null) return;
    await client.from('email_templates').upsert(t.toJson());
  }

  Future<void> delete(String name) async {
    final client = _client;
    if (client == null) return;
    await client.from('email_templates').delete().eq('name', name);
  }
}
