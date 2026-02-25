/// Schema-aligned model for `punch_card_programs` (backend-cheatsheet §1).
/// Public read: all rows.
library;

class PunchCardProgram {
  const PunchCardProgram({
    required this.id,
    required this.businessId,
    required this.punchesRequired,
    required this.rewardDescription,
    this.isActive,
    this.title,
  });

  final String id;
  final String businessId;
  final int punchesRequired;
  final String rewardDescription;
  final bool? isActive;
  final String? title;

  factory PunchCardProgram.fromJson(Map<String, dynamic> json) {
    return PunchCardProgram(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      punchesRequired: json['punches_required'] as int,
      rewardDescription: json['reward_description'] as String,
      isActive: json['is_active'] as bool?,
      title: json['title'] as String?,
    );
  }
}
