import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/deals/data/api/punch_card_programs_api.dart';
import 'package:cajun_local/features/deals/data/models/punch_card_program.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'punch_card_programs_repository.g.dart';

/// Public read: punch_card_programs (backend-cheatsheet §7).
class PunchCardProgramsRepository {
  PunchCardProgramsRepository({PunchCardProgramsApi? api}) : _api = api ?? PunchCardProgramsApi(ApiClient.instance);
  final PunchCardProgramsApi _api;

  Future<List<PunchCardProgram>> listActive({String? businessId}) async {
    return _api.listActive(businessId: businessId);
  }

  /// Manager: delete a punch card program. RLS must allow manager to delete own business programs.
  Future<void> deleteForManager(String programId) async {
    await _api.deleteForManager(programId);
  }

  /// Manager/admin: insert a new punch card program.
  Future<void> insert({
    required String businessId,
    required int punchesRequired,
    required String rewardDescription,
    String? title,
    bool isActive = true,
  }) async {
    await _api.insert(
      businessId: businessId,
      punchesRequired: punchesRequired,
      rewardDescription: rewardDescription,
      title: title,
      isActive: isActive,
    );
  }
}

@riverpod
PunchCardProgramsRepository punchCardProgramsRepository(PunchCardProgramsRepositoryRef ref) {
  return PunchCardProgramsRepository(api: ref.watch(punchCardProgramsApiProvider));
}
