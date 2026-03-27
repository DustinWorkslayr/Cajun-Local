import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_models.freezed.dart';
part 'home_models.g.dart';


@freezed
abstract class HomeEvent with _$HomeEvent {
  const factory HomeEvent({
    required String id,
    required String businessId,
    required String businessName,
    required String title,
    required DateTime eventDate,
    String? imageUrl,
    String? location,
  }) = _HomeEvent;

  factory HomeEvent.fromJson(Map<String, dynamic> json) => _$HomeEventFromJson(json);
}
