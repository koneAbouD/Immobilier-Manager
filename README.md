# Immobilier Manager

Gestion locative : immeubles, logements, locataires, baux, loyers et maintenances.
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
cd backend && JAVA_HOME=$(/usr/libexec/java_home -v 21.0.8) mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

```bash
cd mobile && flutter run
```

- Le profil `dev` charge un jeu de démonstration (2 immeubles, 6 logements, 3 locataires).
- Compte de démonstration : voir `users` dans `keycloak/realm-immobilier-manager.json` (rôles ADMIN + GESTIONNAIRE).
- Swagger : http://localhost:8082/swagger-ui.html
- Sur un vrai téléphone Android : `adb reverse tcp:8082 tcp:8082`, ou `flutter run --dart-define=DEV_HOST=<ip-du-mac>`.
- Compiler avec le **JDK 21.0.8** : le 21.0.10 déclenche un bug de Lombok (même contrainte que VTC Manager).

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
- **Échéances de loyer** : une par bail et par mois, émises à la signature (rattrapage depuis la date de début) puis chaque nuit par un scheduler idempotent. Le statut (`A_PAYER`, `PARTIEL`, `PAYEE`, `ANNULEE`) se déduit toujours des montants.
- **Paiements** : partiels autorisés, plafonnés au reste dû. Un paiement ne se supprime jamais : il s'annule avec motif et auteur.
- **Résiliation** : libère le logement ; le mois de résiliation et les impayés antérieurs restent dus, les loyers des mois suivants sont annulés.
- **Maintenances** : `SIGNALEE → PLANIFIEE → EN_COURS → TERMINEE`, ou `ANNULEE` (motif obligatoire). Une intervention close ne change plus d'état.
- **Piste d'audit** : `created_by` / `updated_by` sur toutes les tables, alimentés depuis le jeton Keycloak (`system` pour le scheduler).

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

API (toutes sous `/api`, rôle ADMIN ou GESTIONNAIRE) :

| Ressource | Endpoints |
|---|---|
| Auth | `POST /auth/login`, `/auth/refresh`, `/auth/logout` |
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

- Quittances PDF et envoi WhatsApp (patterns existants dans VTC Manager : `recu`, `envoi_pdf_whatsapp`).
- Code d'accès / biométrie et notifications push en réutilisant `packages/tmk_pin` et `tmk_push` de VTC Manager (à extraire dans un dépôt partagé).
- Dépenses et rentabilité par immeuble (coûts de maintenance vs loyers encaissés).
- Révision annuelle des loyers, documents (bail signé, pièces d'identité) sur MinIO.
- `compose.prod.yml` et CI GitHub Actions sur le modèle de VTC Manager.
