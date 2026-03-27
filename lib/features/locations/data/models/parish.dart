import 'package:freezed_annotation/freezed_annotation.dart';

part 'parish.freezed.dart';
part 'parish.g.dart';

@freezed
abstract class Parish with _$Parish {
  const factory Parish({
    required String id,
    required String name,
    String? slug,
    @JsonKey(name: 'sort_order', defaultValue: 0) required int sortOrder,
  }) = _Parish;

  factory Parish.fromJson(Map<String, dynamic> json) => _$ParishFromJson(json);
}
