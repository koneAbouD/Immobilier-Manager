import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/organisation_remote_datasource.dart';
import '../../data/repositories_impl/organisation_repository_impl.dart';
import '../../domain/entities/organisation.dart';
import '../../domain/repositories/organisation_repository.dart';

final organisationRepositoryProvider = Provider<OrganisationRepository>(
  (ref) => OrganisationRepositoryImpl(OrganisationRemoteDatasource(ref.watch(apiClientProvider))),
);

/// Session de travail : l'utilisateur connecté et l'organisation retenue.
class SessionOrganisation {
  final Profil profil;

  /// Nulle tant que l'utilisateur, membre de plusieurs organisations, n'a pas choisi.
  final Adhesion? active;

  const SessionOrganisation(this.profil, this.active);

  RoleMembre get role => active?.role ?? RoleMembre.lecteur;
}

/// Chargé une fois par session (le conteneur est recréé à chaque connexion et
/// à chaque changement d'organisation). Retient l'organisation enregistrée si
/// elle est toujours accessible, sinon l'unique organisation du compte ; avec
/// plusieurs organisations et aucun choix valable, [SessionOrganisation.active]
/// reste nulle et l'application demande le choix.
final sessionOrganisationProvider = FutureProvider<SessionOrganisation>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final client = ref.watch(apiClientProvider);
  // Action refusée par le serveur : un administrateur a pu changer le rôle
  // depuis l'ouverture de la session. On relit le profil, et on ne recharge
  // la session (donc les droits affichés) que si le rôle a vraiment changé.
  var verification = false;
  client.onDroitsRefuses = () async {
    final active = ref.state.valueOrNull?.active;
    if (verification || active == null) return;
    verification = true;
    try {
      final relu = await ref.read(organisationRepositoryProvider).moi();
      final role = relu.fold((_) => null, (p) => p.adhesion(active.organisationId)?.role);
      if (role != null && role != active.role) ref.invalidateSelf();
    } finally {
      verification = false;
    }
  };
  ref.onDispose(() => client.onDroitsRefuses = null);
  final result = await ref.watch(organisationRepositoryProvider).moi();
  final profil = result.fold((f) => throw f.message, (p) => p);

  Adhesion? active = profil.adhesion(await storage.getOrganisationId());
  if (active == null && profil.organisations.length == 1) active = profil.organisations.first;
  if (active != null) {
    await storage.setOrganisationId(active.organisationId);
  } else {
    await storage.clearOrganisationId();
  }
  return SessionOrganisation(profil, active);
});

/// Rôle de l'utilisateur dans l'organisation active ; lecteur par prudence tant
/// qu'il n'est pas connu.
final monRoleProvider = Provider<RoleMembre>(
  (ref) => ref.watch(sessionOrganisationProvider).valueOrNull?.role ?? RoleMembre.lecteur,
);

/// Vrai si l'abonnement de l'organisation active autorise l'écriture ; le rôle
/// décide ensuite de chaque action (voir `ActionMetier`).
final ecritureOuverteProvider = Provider<bool>((ref) {
  final active = ref.watch(sessionOrganisationProvider).valueOrNull?.active;
  return active != null && active.acces == AccesOrganisation.complet;
});

/// Organisation courante, abonnement compris ; à invalider après modification.
final organisationCouranteProvider = FutureProvider.autoDispose<OrganisationCourante>((ref) async {
  final result = await ref.watch(organisationRepositoryProvider).courante();
  return result.fold((f) => throw f.message, (o) => o);
});

final logoOrganisationProvider = FutureProvider.autoDispose<Uint8List?>((ref) async {
  final organisation = await ref.watch(organisationCouranteProvider.future);
  if (!organisation.logo) return null;
  final result = await ref.watch(organisationRepositoryProvider).logo();
  return result.fold((_) => null, (b) => b);
});

final membresProvider = FutureProvider.autoDispose<List<MembreEquipe>>((ref) async {
  final result = await ref.watch(organisationRepositoryProvider).membres();
  return result.fold((f) => throw f.message, (l) => l);
});

final plansProvider = FutureProvider.autoDispose<List<Plan>>((ref) async {
  final result = await ref.watch(organisationRepositoryProvider).plans();
  return result.fold((f) => throw f.message, (l) => l);
});
