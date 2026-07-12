// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Plain read-only provider — the dashboard is a snapshot with no
/// mutations from this screen, so a function provider (not a class
/// notifier) is enough. Refresh via `ref.invalidate(dashboardProvider)`.

@ProviderFor(dashboard)
final dashboardProvider = DashboardProvider._();

/// Plain read-only provider — the dashboard is a snapshot with no
/// mutations from this screen, so a function provider (not a class
/// notifier) is enough. Refresh via `ref.invalidate(dashboardProvider)`.

final class DashboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardData>,
          DashboardData,
          FutureOr<DashboardData>
        >
    with $FutureModifier<DashboardData>, $FutureProvider<DashboardData> {
  /// Plain read-only provider — the dashboard is a snapshot with no
  /// mutations from this screen, so a function provider (not a class
  /// notifier) is enough. Refresh via `ref.invalidate(dashboardProvider)`.
  DashboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardHash();

  @$internal
  @override
  $FutureProviderElement<DashboardData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardData> create(Ref ref) {
    return dashboard(ref);
  }
}

String _$dashboardHash() => r'52fd5d2ea33b84536b3f1609922e2681758a7943';
