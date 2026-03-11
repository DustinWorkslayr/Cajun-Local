/// Schema-aligned model for `business_hours` (backend-cheatsheet §1).
library;

class BusinessHours {
  const BusinessHours({
    required this.businessId,
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    this.isClosed,
  });

  final String businessId;
  final String dayOfWeek;
  final String? openTime;
  final String? closeTime;
  final bool? isClosed;

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      businessId: json['business_id'] as String,
      dayOfWeek: json['day_of_week'] as String,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      isClosed: json['is_closed'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'day_of_week': dayOfWeek,
      'open_time': openTime,
      'close_time': closeTime,
      'is_closed': isClosed,
    };
  }
}
