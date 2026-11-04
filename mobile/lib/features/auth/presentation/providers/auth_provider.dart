import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories_impl/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    AuthRemoteDatasource(ref.watch(apiClientProvider)),
    ref.watch(secureStorageProvider),
  ),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial());

  /// Au démarrage : une session enregistrée rouvre l'application directement ;
  /// si elle a expiré, le premier appel API le dira et ramènera ici.
  Future<void> bootstrap() async {
    if (state is! AuthInitial) return;
    if (await _repository.hasSession()) {
      state = AuthAuthenticated(await _repository.currentUsername() ?? '');
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String username, String password) async {
    state = const AuthLoading();
    final result = await _repository.login(username.trim(), password);
    state = result.fold(
      (failure) => AuthError(failure.message),
      (_) => AuthAuthenticated(username.trim()),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// Le refresh token a été refusé : retour à la connexion.
  Future<void> sessionExpiree() async {
    if (state is! AuthAuthenticated) return;
    await _repository.logout();
    state = const AuthUnauthenticated('Session expirée, veuillez vous reconnecter.');
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref.watch(authRepositoryProvider));
  ref.watch(apiClientProvider).onSessionExpired = notifier.sessionExpiree;
  return notifier;
});
