import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_view.freezed.dart';
part 'saved_view.g.dart';

@freezed
abstract class SavedView with _$SavedView {
  const factory SavedView({
    int? id,
    required String name,
    String? params,
    DateTime? createdAt,
  }) = _SavedView;

  factory SavedView.fromJson(Map<String, dynamic> json) =>
      _$SavedViewFromJson(json);
}
