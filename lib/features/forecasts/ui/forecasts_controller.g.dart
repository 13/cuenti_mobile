// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecasts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read-only family provider — the screen's year picker becomes the family
/// arg, so changing the year re-targets the provider instead of triggering
/// a manual reload.

@ProviderFor(forecast)
final forecastProvider = ForecastFamily._();

/// Read-only family provider — the screen's year picker becomes the family
/// arg, so changing the year re-targets the provider instead of triggering
/// a manual reload.

final class ForecastProvider
    extends
        $FunctionalProvider<
          AsyncValue<ForecastData>,
          ForecastData,
          FutureOr<ForecastData>
        >
    with $FutureModifier<ForecastData>, $FutureProvider<ForecastData> {
  /// Read-only family provider — the screen's year picker becomes the family
  /// arg, so changing the year re-targets the provider instead of triggering
  /// a manual reload.
  ForecastProvider._({
    required ForecastFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'forecastProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$forecastHash();

  @override
  String toString() {
    return r'forecastProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ForecastData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ForecastData> create(Ref ref) {
    final argument = this.argument as int;
    return forecast(ref, year: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ForecastProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$forecastHash() => r'927b842ec1157de3eccfb8aa4b9d57220ce77807';

/// Read-only family provider — the screen's year picker becomes the family
/// arg, so changing the year re-targets the provider instead of triggering
/// a manual reload.

final class ForecastFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ForecastData>, int> {
  ForecastFamily._()
    : super(
        retry: null,
        name: r'forecastProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Read-only family provider — the screen's year picker becomes the family
  /// arg, so changing the year re-targets the provider instead of triggering
  /// a manual reload.

  ForecastProvider call({required int year}) =>
      ForecastProvider._(argument: year, from: this);

  @override
  String toString() => r'forecastProvider';
}
