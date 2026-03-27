import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_event.freezed.dart';
part 'business_event.g.dart';

@freezed
abstract class BusinessEvent with _$BusinessEvent {
  const factory BusinessEvent({
    required String id,
    @JsonKey(name: 'business_id') required String businessId,
    required String title,
    @JsonKey(name: 'event_date') required DateTime eventDate,
    String? description,
    @JsonKey(name: 'end_date') DateTime? endDate,
    String? location,
    @JsonKey(name: 'image_url') String? imageUrl,
    @Default('pending') String status,
  }) = _BusinessEvent;

  factory BusinessEvent.fromJson(Map<String, dynamic> json) => _$BusinessEventFromJson(json);
}
