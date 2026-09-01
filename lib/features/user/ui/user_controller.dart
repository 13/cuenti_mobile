import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_controller.g.dart';

/// Plain read-only providers for the admin panel. Writes go through
/// `userRepositoryProvider` directly and then `ref.invalidate` these to
/// refetch — no local optimistic state to manage, so a class notifier
/// would add nothing.
@riverpod
Future<List<UserProfile>> adminUsers(Ref ref) =>
    ref.watch(userRepositoryProvider).getAllUsers();

@riverpod
Future<AdminSettings> adminSettings(Ref ref) =>
    ref.watch(userRepositoryProvider).getAdminSettings();
