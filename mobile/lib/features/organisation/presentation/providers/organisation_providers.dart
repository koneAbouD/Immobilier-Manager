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

/// Vrai si l'utilisateur peut créer et modifier des données : gestionnaire ou
/// plus, dans une organisation dont l'abonnement autorise l'écriture.
final peutEcrireProvider = Provider<bool>((ref) {
  final active = ref.watch(sessionOrganisationProvider).valueOrNull?.active;
  return active != null && active.role.peutEcrire && active.acces == AccesOrganisation.complet;
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
