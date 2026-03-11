/// One row from list_punch_card_enrollments_for_business RPC.
class PunchCardEnrollment {
  const PunchCardEnrollment({
    required this.userPunchCardId,
    required this.programId,
    required this.programTitle,
    required this.punchesRequired,
    required this.currentPunches,
    required this.isRedeemed,
    this.userDisplayName,
    this.userEmail,
  });

  final String userPunchCardId;
  final String programId;
  final String programTitle;
  final int punchesRequired;
  final int currentPunches;
  final bool isRedeemed;
  final String? userDisplayName;
  final String? userEmail;

  bool get canRedeem =>
      !isRedeemed && currentPunches >= punchesRequired;

  factory PunchCardEnrollment.fromJson(Map<String, dynamic> json) {
    return PunchCardEnrollment(
      userPunchCardId: json['user_punch_card_id'] as String? ?? '',
      programId: json['program_id'] as String? ?? '',
      programTitle: json['program_title'] as String? ?? '',
      punchesRequired: (json['punches_required'] as num?)?.toInt() ?? 0,
      currentPunches: (json['current_punches'] as num?)?.toInt() ?? 0,
      isRedeemed: json['is_redeemed'] as bool? ?? false,
      userDisplayName: json['user_display_name'] as String?,
      userEmail: json['user_email'] as String?,
    );
  }
}
