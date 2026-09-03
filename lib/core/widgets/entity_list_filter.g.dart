// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity_list_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The search and sort a list screen is holding, kept per [screen].
///
/// It lives outside the widget because the screens are rebuilt from scratch
/// on every navigation: state held in the State object meant that stepping
/// into an account and back threw away what had been typed. Kept alive for
/// the session, and separate per screen so a search on Konten does not
/// follow the reader into Tags.

@ProviderFor(EntityListFilter)
final entityListFilterProvider = EntityListFilterFamily._();

/// The search and sort a list screen is holding, kept per [screen].
///
/// It lives outside the widget because the screens are rebuilt from scratch
/// on every navigation: state held in the State object meant that stepping
/// into an account and back threw away what had been typed. Kept alive for
/// the session, and separate per screen so a search on Konten does not
/// follow the reader into Tags.
final class EntityListFilterProvider
    extends $NotifierProvider<EntityListFilter, EntityFilter> {
  /// The search and sort a list screen is holding, kept per [screen].
  ///
  /// It lives outside the widget because the screens are rebuilt from scratch
  /// on every navigation: state held in the State object meant that stepping
  /// into an account and back threw away what had been typed. Kept alive for
  /// the session, and separate per screen so a search on Konten does not
  /// follow the reader into Tags.
  EntityListFilterProvider._({
    required EntityListFilterFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'entityListFilterProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$entityListFilterHash();

  @override
  String toString() {
    return r'entityListFilterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EntityListFilter create() => EntityListFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntityFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntityFilter>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EntityListFilterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$entityListFilterHash() => r'925cb840905c9ed434da12e3bea1fc3364046d2e';

/// The search and sort a list screen is holding, kept per [screen].
///
/// It lives outside the widget because the screens are rebuilt from scratch
/// on every navigation: state held in the State object meant that stepping
/// into an account and back threw away what had been typed. Kept alive for
/// the session, and separate per screen so a search on Konten does not
/// follow the reader into Tags.

final class EntityListFilterFamily extends $Family
    with
        $ClassFamilyOverride<
          EntityListFilter,
          EntityFilter,
          EntityFilter,
          EntityFilter,
          String
        > {
  EntityListFilterFamily._()
    : super(
        retry: null,
        name: r'entityListFilterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The search and sort a list screen is holding, kept per [screen].
  ///
  /// It lives outside the widget because the screens are rebuilt from scratch
  /// on every navigation: state held in the State object meant that stepping
  /// into an account and back threw away what had been typed. Kept alive for
  /// the session, and separate per screen so a search on Konten does not
  /// follow the reader into Tags.

  EntityListFilterProvider call(String screen) =>
      EntityListFilterProvider._(argument: screen, from: this);

  @override
  String toString() => r'entityListFilterProvider';
}

/// The search and sort a list screen is holding, kept per [screen].
///
/// It lives outside the widget because the screens are rebuilt from scratch
/// on every navigation: state held in the State object meant that stepping
/// into an account and back threw away what had been typed. Kept alive for
/// the session, and separate per screen so a search on Konten does not
/// follow the reader into Tags.

abstract class _$EntityListFilter extends $Notifier<EntityFilter> {
  late final _$args = ref.$arg as String;
  String get screen => _$args;

  EntityFilter build(String screen);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EntityFilter, EntityFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EntityFilter, EntityFilter>,
              EntityFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
