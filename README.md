# Immobilier Manager

Gestion locative **en SaaS multi-organisation** : chaque agence, bailleur ou gestionnaire
crée son espace en libre-service et y gère immeubles, logements, locataires, baux, loyers
et maintenances, cloisonnés des autres organisations.
Architecture reprise de **VTC Manager** (même entreprise, mêmes conventions).

| Brique | Techno | Port local |
|---|---|---|
| `backend/` | Spring Boot 3.3 / Java 21, architecture hexagonale, PostgreSQL + Flyway | 8082 |
| `mobile/` | Flutter + Riverpod, clean architecture par feature | — |
| Keycloak | realm `immobilier-manager` importé au démarrage | 8180 |
| PostgreSQL | base `immobilier_manager` (+ base `keycloak`) | 5434 |

Les ports sont volontairement distincts de VTC Manager (5432 / 8080 / 8081) pour que les deux projets tournent en parallèle.

## Démarrage local

```bash
docker compose up -d
```

```bash
./keycloak/configurer-compte-service.sh
```

(une fois, sur un realm déjà importé : active le compte de service du backend qui crée les
comptes à l'inscription, ajoute le rôle `SUPER_ADMIN`. `SUPER_ADMIN_USER=<identifiant>`
donne ce rôle à un compte.)

```bash
cd backend && JAVA_HOME=$(/usr/libexec/java_home -v 21.0.8) mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

```bash
cd mobile && flutter run
```

- Le profil `dev` charge un jeu de démonstration (2 immeubles, 6 logements, 3 locataires), rattaché à l'organisation historique « TMK ».
- Compte de démonstration : voir `users` dans `keycloak/realm-immobilier-manager.json` ; il devient propriétaire de « TMK » à sa première connexion, et `SUPER_ADMIN` (back-office plateforme).
- Nouvelle organisation : bouton « Créer un compte » de l'écran de connexion (`POST /api/auth/inscription`).
- Swagger : http://localhost:8082/swagger-ui.html
- Sur un vrai téléphone Android : `adb reverse tcp:8082 tcp:8082`, ou `flutter run --dart-define=DEV_HOST=<ip-du-mac>`.
- Compiler avec le **JDK 21.0.8** : le 21.0.10 déclenche un bug de Lombok (même contrainte que VTC Manager).

## SaaS multi-organisation

```
Organisation 1──* Membre *──1 Utilisateur (compte Keycloak, peut servir plusieurs organisations)
     │
     └──* toutes les données métier (organisation_id)
```

- **Inscription en libre-service** : identifiant de connexion = **numéro de téléphone** (forme canonique : `07 07 12 34 56`, `+225 0707123456`… ouvrent le même compte), e-mail facultatif. Crée le compte Keycloak (API d'administration), l'organisation en **essai gratuit de 30 jours** (formule Professionnel) et l'adhésion de propriétaire, puis ouvre la session. En cas d'échec en base, le compte Keycloak est supprimé (compensation).
- **Organisation de travail** : en-tête `X-Organisation-Id` sur chaque requête (le mobile le pose seul ; facultatif si l'utilisateur n'a qu'une organisation). `ContexteOrganisationFilter` vérifie l'adhésion, l'état de l'abonnement et pose le rôle.
- **Rôles par organisation** (emboîtés) : `PROPRIETAIRE` ⊃ `ADMIN` (équipe, réglages) ⊃ `GESTIONNAIRE` (écriture métier) ⊃ `LECTEUR` (consultation). Les rôles Keycloak ne donnent aucun droit métier ; seul `SUPER_ADMIN` ouvre `/api/plateforme`.
- **Cloisonnement**, en quatre couches :
  1. Hibernate `@TenantId` (`AbstractTenantEntity`) : filtre toutes les requêtes HQL/Criteria, renseigne `organisation_id` à l'insertion ;
  2. `FiltreOrganisationJpaRepository` : `findById` passe par ce filtre (Hibernate 6.5 ne filtre pas le chargement par clé) ;
  3. `GardeOrganisation` (`@PostLoad`) : toute entité d'une autre organisation chargée par un autre chemin est rejetée (404) ;
  4. en base : `organisation_id NOT NULL` et **clés étrangères composites** `(id, organisation_id)`.
  Hors contexte, l'organisation vaut `-1` : tables vides, insertions impossibles (on échoue fermé). Le seul SQL natif (résumé des locataires) filtre explicitement.
- **Abonnement** (`PlanAbonnement`) : Gratuit 5 lots / 1 utilisateur, Essentiel 50 / 3, Professionnel 300 / 10, Entreprise illimité. Dépasser une limite → **402** `LIMITE_LOTS_ATTEINTE` / `LIMITE_MEMBRES_ATTEINTE`. Essai échu, abonnement échu ou suspendu → **lecture seule** (402 sur toute écriture) ; résilié → accès bloqué (403). Tarifs et limites dans `PlanAbonnement`.
- **Identité du bailleur** (contrats, quittances) = l'organisation : nom, représentant, coordonnées, ville, **logo** (remplace `app.bailleur.*`).
- **Numérotation par organisation** (`BAIL-00001`…), via `compteurs_organisation` (incrément atomique).
- **Fichiers** rangés sous `organisations/{id}/…` dans MinIO.
- **Planificateur** : émet les loyers organisation par organisation, chacune dans son contexte et sa transaction.
- **Migration** `V200.0.0` : les données existantes rejoignent l'organisation historique « TMK » ; les comptes qui avaient les rôles Keycloak `ADMIN` / `GESTIONNAIRE` y sont rattachés à leur première connexion (le premier `ADMIN` en devient propriétaire). Numérotée V200 pour passer après le jeu de démonstration V100 : **les migrations de schéma suivantes continuent en V200.x**.

## Modèle métier

```
Immeuble 1──* Appartement 1──* Bail *──1 Locataire
                  │              │
                  │              └──* EcheanceLoyer 1──* PaiementLoyer
                  └──* Maintenance (ou parties communes de l'immeuble)
```

Règles clés :

- **Le bail porte le loyer exigible**, pas le logement : modifier le loyer affiché d'un logement ne réécrit pas les baux en cours.
- **Un seul bail actif par logement** (vérifié par le use case et par un index unique partiel en base). Le statut `OCCUPE` d'un logement est posé et levé par les baux uniquement.
- **Échéances de loyer** : une par bail et par mois, à partir du **premier mois facturé** = max(mois suivant l'enregistrement du bail, mois de début + mois d'avance) — rien de rétroactif, les mois réglés d'avance ne sont pas facturés ; la caution reste un dépôt restituable. Le premier mois est stocké sur le bail et modifiable. Émission chaque nuit par un scheduler idempotent (le mois courant à partir du 25). Le statut (`A_PAYER`, `PARTIEL`, `PAYEE`, `ANNULEE`) se déduit toujours des montants.
- **Paiements** : partiels autorisés, plafonnés au reste dû. Un paiement ne se supprime jamais : il s'annule avec motif et auteur.
- **Résiliation** : libère le logement ; le mois de résiliation et les impayés antérieurs restent dus, les loyers des mois suivants sont annulés.
- **Maintenances** : `SIGNALEE → PLANIFIEE → EN_COURS → TERMINEE`, ou `ANNULEE` (motif obligatoire). Une intervention close ne change plus d'état.
- **Piste d'audit** : `created_by` / `updated_by` sur toutes les tables, alimentés depuis le jeton Keycloak (`system` pour le scheduler).

Mobile : après la connexion, `PorteOrganisation` charge `/api/moi`, retient l'organisation (ou la fait choisir) ; chaque ouverture de session et chaque changement d'organisation **redémarre le conteneur Riverpod** (`Redemarrage`), pour qu'aucune donnée d'une organisation ou d'un compte ne reste en cache. Lecteurs et organisations en lecture seule ne voient pas les boutons d'ajout / modification (`DroitsEcriture`).

## Backend — organisation

```
com.tmk.immobilier
├── application            ← cœur métier, sans dépendance au framework web ni à JPA
│   ├── domain/<module>    ← modèles + règles (Bail.resilier, EcheanceLoyer.enregistrerPaiement…)
│   ├── ports/             ← interfaces : persistence, auth, security
│   ├── usecases/<module>  ← un use case = une classe POJO, câblée dans UseCaseBeanConfiguration
│   └── exception/         ← RegleMetierException (409 + code), ResourceNotFound (404)…
├── infrastructure
│   ├── persistence/postgresql/{entities,jpa,mapper,adapter}
│   ├── keycloak/          ← login / refresh / logout proxifiés (le mobile ne parle qu'au backend)
│   ├── config/            ← sécurité, auditing JPA, OpenAPI, câblage des use cases
│   └── scheduler/         ← émission quotidienne des loyers
└── interfaces/rest/<module>/{Controller, dto, mapper}
```

Migrations : `src/main/resources/db/migration/flyway/{schema, jdd/reference, jdd/dev}`.
Une migration appliquée ne se modifie jamais : on corrige par une nouvelle. Hibernate est en `ddl-auto: validate`.

API (toutes sous `/api` ; lecture à partir de LECTEUR, écriture à partir de GESTIONNAIRE) :

| Ressource | Endpoints |
|---|---|
| Auth (public) | `POST /auth/inscription`, `/auth/login`, `/auth/refresh`, `/auth/logout`, `GET /auth/plans` |
| Mon compte | `GET /moi` (organisations accessibles), `PUT /moi/mot-de-passe` |
| Organisation | `GET/PUT /organisation`, `GET/POST/DELETE /organisation/logo` |
| Équipe (ADMIN) | `GET/POST /organisation/membres`, `PATCH/DELETE /organisation/membres/{id}`, `POST …/{id}/propriete` |
| Plateforme (SUPER_ADMIN) | `GET /plateforme/organisations`, `PUT /plateforme/organisations/{id}/abonnement` |
| Immeubles | `GET /immeubles`, `/immeubles/page`, CRUD `/immeubles/{id}` |
| Logements | `GET /appartements/page?immeubleId&statut&recherche`, CRUD |
| Locataires | `GET /locataires/page`, CRUD |
| Baux | `GET /baux/page`, `POST /baux`, `PUT /baux/{id}`, `PATCH /baux/{id}/resilier` |
| Loyers | `GET /loyers/echeances/page?periode=2026-10&aEncaisser&enRetard`, `POST /loyers/echeances/generer`, `POST /loyers/echeances/{id}/paiements`, `GET /loyers/paiements/page`, `PATCH /loyers/paiements/{id}/annuler` |
| Maintenances | `GET /maintenances/page`, CRUD, `PATCH …/demarrer`, `…/terminer`, `…/annuler` |
| Tableau de bord | `GET /tableau-bord?periode=2026-10` |

Erreurs : format `ApiError` unique (`status`, `error` = code stable, `message` lisible tel quel par l'utilisateur, `details`).

## Mobile — organisation

```
lib/
├── core/        ← ApiClient (bearer + refresh unique sur 401), guard() exception → Failure,
│                  PagedListView (scroll infini), SelectionPage, champs de formulaire, thème TMK
├── features/<module>/
│   ├── domain/      ← entités, énumérations (code API + libellé + couleur), repository abstrait
│   ├── data/        ← datasource REST, modèle JSON, repository_impl
│   └── presentation/← providers Riverpod, pages, widgets
└── screens/home_screen.dart ← navigation : Accueil · Biens · Locations · Loyers · Travaux
```

Différence assumée avec VTC Manager : pas de couche `domain/usecases` côté mobile (les use cases y étaient de simples relais vers le repository) ; les notifiers appellent directement le repository.

## Tests

```bash
cd backend && JAVA_HOME=$(/usr/libexec/java_home -v 21.0.8) mvn test
```

```bash
cd mobile && flutter test
```

## Prochaines étapes suggérées

- Paiement en ligne des abonnements (Mobile Money / carte) branché sur `PUT /plateforme/organisations/{id}/abonnement`.
- E-mails transactionnels (bienvenue, invitation, mot de passe oublié) via le SMTP de Keycloak.
- Défense en profondeur supplémentaire : Row-Level Security PostgreSQL sur `organisation_id`.
- Export des données d'une organisation (portabilité) et suppression de compte.

- Quittances PDF et envoi WhatsApp (patterns existants dans VTC Manager : `recu`, `envoi_pdf_whatsapp`).
- Code d'accès / biométrie et notifications push en réutilisant `packages/tmk_pin` et `tmk_push` de VTC Manager (à extraire dans un dépôt partagé).
- Dépenses et rentabilité par immeuble (coûts de maintenance vs loyers encaissés).
- Révision annuelle des loyers, documents (bail signé, pièces d'identité) sur MinIO.
- `compose.prod.yml` et CI GitHub Actions sur le modèle de VTC Manager.
