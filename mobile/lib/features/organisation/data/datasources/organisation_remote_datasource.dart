import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/organisation.dart';

/// API « compte » et « organisation » : profil, organisation courante,
/// équipe, formules, et back-office de la plateforme.
class OrganisationRemoteDatasource {
  final ApiClient _client;
  const OrganisationRemoteDatasource(this._client);

  // ── Profil ─────────────────────────────────────────────────────────────────

  Future<Profil> moi() async => _profil(await _client.get('/moi') as Map<String, dynamic>);

  Future<void> changerMotDePasse(String actuel, String nouveau) =>
      _client.put('/moi/mot-de-passe', {'actuel': actuel, 'nouveau': nouveau});

  // ── Organisation courante ──────────────────────────────────────────────────

  Future<OrganisationCourante> courante() async =>
      organisation(await _client.get('/organisation') as Map<String, dynamic>);

  Future<OrganisationCourante> modifier(Map<String, dynamic> identite) async =>
      organisation(await _client.put('/organisation', identite) as Map<String, dynamic>);

  Future<Uint8List> logo() => _client.getBytes('/organisation/logo');

  Future<OrganisationCourante> deposerLogo(Uint8List contenu, String nomFichier, String type) async =>
      organisation(await _client.postFichier('/organisation/logo',
          champ: 'fichier', contenu: contenu, nomFichier: nomFichier, type: type) as Map<String, dynamic>);

  Future<void> supprimerLogo() => _client.delete('/organisation/logo');

  // ── Équipe ─────────────────────────────────────────────────────────────────

  Future<List<MembreEquipe>> membres() async => (await _client.get('/organisation/membres') as List)
      .map((e) => _membre(e as Map<String, dynamic>))
      .toList();

  Future<MembreEquipe> ajouterMembre(
          {required String email, required String prenom, required String nom, required RoleMembre role}) async =>
      _membre(await _client.post('/organisation/membres',
          {'email': email, 'prenom': prenom, 'nom': nom, 'role': role.code}) as Map<String, dynamic>);

  Future<MembreEquipe> modifierMembre(int id, {RoleMembre? role, bool? actif}) async =>
      _membre(await _client.patch('/organisation/membres/$id', {
        'role': ?role?.code,
        'actif': ?actif,
      }) as Map<String, dynamic>);

  Future<void> retirerMembre(int id) => _client.delete('/organisation/membres/$id');

  Future<MembreEquipe> transfererPropriete(int id) async =>
      _membre(await _client.post('/organisation/membres/$id/propriete') as Map<String, dynamic>);

  // ── Formules et plateforme ─────────────────────────────────────────────────

  Future<List<Plan>> plans() async =>
      (await _client.getPublic('/auth/plans') as List).map((e) => _plan(e as Map<String, dynamic>)).toList();

  Future<PageResult<OrganisationCourante>> organisationsPlateforme(
      {int page = 0, int size = 20, String? recherche}) async {
    final data = await _client.get('/plateforme/organisations', query: {
      'page': '$page',
      'size': '$size',
      if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
    });
    return PageResult.fromJson(data as Map<String, dynamic>, organisation);
  }

  Future<OrganisationCourante> modifierAbonnement(int organisationId,
          {required String plan, required String statut, DateTime? essaiFinLe, DateTime? abonnementFinLe}) async =>
      organisation(await _client.put('/plateforme/organisations/$organisationId/abonnement', {
        'plan': plan,
        'statut': statut,
        if (essaiFinLe != null) 'essaiFinLe': isoDate(essaiFinLe),
        'abonnementFinLe': abonnementFinLe == null ? null : isoDate(abonnementFinLe),
      }) as Map<String, dynamic>);

  // ── JSON ───────────────────────────────────────────────────────────────────

  static Profil _profil(Map<String, dynamic> j) => Profil(
        id: j['id'] as int,
        email: j['email'] as String?,
        telephone: j['telephone'] as String?,
        prenom: j['prenom'] as String?,
        nom: j['nom'] as String?,
        nomComplet: j['nomComplet'] as String? ?? j['email'] as String? ?? j['telephone'] as String? ?? '',
        superAdmin: j['superAdmin'] as bool? ?? false,
        organisations: (j['organisations'] as List? ?? const [])
            .map((e) => e as Map<String, dynamic>)
            .map((a) => Adhesion(
                  organisationId: a['organisationId'] as int,
                  organisation: a['organisation'] as String,
                  role: RoleMembre.fromCode(a['role'] as String?),
                  statut: StatutAbonnement.fromCode(a['statutAbonnement'] as String?),
                  acces: AccesOrganisation.fromCode(a['acces'] as String?),
                ))
            .toList(),
      );

  static Plan _plan(Map<String, dynamic> j) => Plan(
        code: j['code'] as String,
        libelle: j['libelle'] as String,
        lotsMax: j['lotsMax'] as int?,
        membresMax: j['membresMax'] as int?,
        tarifMensuel: (j['tarifMensuel'] as num?)?.toInt(),
      );

  static OrganisationCourante organisation(Map<String, dynamic> j) {
    final a = j['abonnement'] as Map<String, dynamic>;
    return OrganisationCourante(
      id: j['id'] as int,
      nom: j['nom'] as String,
      representant: j['representant'] as String?,
      email: j['email'] as String?,
      telephone: j['telephone'] as String?,
      adresse: j['adresse'] as String?,
      ville: j['ville'] as String?,
      pays: j['pays'] as String? ?? 'CI',
      devise: j['devise'] as String? ?? 'XOF',
      logo: j['logo'] as bool? ?? false,
      monRole: j['monRole'] == null ? null : RoleMembre.fromCode(j['monRole'] as String?),
      abonnement: Abonnement(
        plan: _plan(a['plan'] as Map<String, dynamic>),
        statut: StatutAbonnement.fromCode(a['statut'] as String?),
        acces: AccesOrganisation.fromCode(a['acces'] as String?),
        motifRestriction: a['motifRestriction'] as String?,
        essaiFinLe: parseDate(a['essaiFinLe']),
        abonnementFinLe: parseDate(a['abonnementFinLe']),
        joursRestants: (a['joursRestants'] as num?)?.toInt(),
        biens: (a['biens'] as num?)?.toInt() ?? 0,
        lots: (a['lots'] as num?)?.toInt() ?? 0,
        membres: (a['membres'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  static MembreEquipe _membre(Map<String, dynamic> j) => MembreEquipe(
        id: j['id'] as int,
        utilisateurId: j['utilisateurId'] as int,
        email: j['email'] as String?,
        telephone: j['telephone'] as String?,
        prenom: j['prenom'] as String?,
        nom: j['nom'] as String?,
        role: RoleMembre.fromCode(j['role'] as String?),
        actif: j['actif'] as bool? ?? true,
        ajouteLe: parseDate(j['ajouteLe']),
        derniereConnexion: parseDate(j['derniereConnexion']),
        motDePasseTemporaire: j['motDePasseTemporaire'] as String?,
      );
}
