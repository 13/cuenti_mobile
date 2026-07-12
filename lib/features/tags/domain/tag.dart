import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

@freezed
abstract class Tag with _$Tag {
  const factory Tag({
    int? id,
    @Default('') String name,
  }) = _Tag;

  const Tag._();

  factory Tag.fromJson(Map<String, dynamic> json) =>
      _$TagFromJson(json);
}
