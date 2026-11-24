import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/organisation.dart';
import '../../domain/repositories/organisation_repository.dart';
import '../datasources/organisation_remote_datasource.dart';

class OrganisationRepositoryImpl implements OrganisationRepository {
  final OrganisationRemoteDatasource _ds;
  const OrganisationRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, Profil>> moi() => guard(_ds.moi);

  @override
  Future<Either<Failure, void>> changerMotDePasse(String actuel, String nouveau) =>
      guard(() => _ds.changerMotDePasse(actuel, nouveau));

  @override
  Future<Either<Failure, OrganisationCourante>> courante() => guard(_ds.courante);

  @override
  Future<Either<Failure, OrganisationCourante>> modifier(Map<String, dynamic> identite) =>
      guard(() => _ds.modifier(identite));

  @override
  Future<Either<Failure, Uint8List>> logo() => guard(_ds.logo);

  @override
  Future<Either<Failure, OrganisationCourante>> deposerLogo(Uint8List contenu, String nomFichier, String type) =>
      guard(() => _ds.deposerLogo(contenu, nomFichier, type));

  @override
  Future<Either<Failure, void>> supprimerLogo() => guard(_ds.supprimerLogo);

  @override
  Future<Either<Failure, List<MembreEquipe>>> membres() => guard(_ds.membres);

  @override
  Future<Either<Failure, MembreEquipe>> ajouterMembre(
          {required String email, required String prenom, required String nom, required RoleMembre role}) =>
      guard(() => _ds.ajouterMembre(email: email, prenom: prenom, nom: nom, role: role));

  @override
  Future<Either<Failure, MembreEquipe>> modifierMembre(int id, {RoleMembre? role, bool? actif}) =>
      guard(() => _ds.modifierMembre(id, role: role, actif: actif));

  @override
  Future<Either<Failure, void>> retirerMembre(int id) => guard(() => _ds.retirerMembre(id));

  @override
  Future<Either<Failure, MembreEquipe>> transfererPropriete(int id) => guard(() => _ds.transfererPropriete(id));

  @override
  Future<Either<Failure, List<Plan>>> plans() => guard(_ds.plans);

  @override
  Future<Either<Failure, PageResult<OrganisationCourante>>> organisationsPlateforme(
          {int page = 0, int size = 20, String? recherche}) =>
      guard(() => _ds.organisationsPlateforme(page: page, size: size, recherche: recherche));

  @override
  Future<Either<Failure, OrganisationCourante>> modifierAbonnement(int organisationId,
          {required String plan, required String statut, DateTime? essaiFinLe, DateTime? abonnementFinLe}) =>
      guard(() => _ds.modifierAbonnement(organisationId,
          plan: plan, statut: statut, essaiFinLe: essaiFinLe, abonnementFinLe: abonnementFinLe));
}
