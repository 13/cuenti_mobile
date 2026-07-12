import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/forecasts_repository.dart';
import '../domain/forecast_data.dart';

part 'forecasts_controller.g.dart';

/// Read-only family provider — the screen's year picker becomes the family
/// arg, so changing the year re-targets the provider instead of triggering
/// a manual reload.
@riverpod
Future<ForecastData> forecast(
  Ref ref, {
  required int year,
}) =>
    ref.watch(forecastsRepositoryProvider).getForecast(year);
