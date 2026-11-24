-- =============================================================================
-- Bascule SaaS : chaque donnée métier appartient désormais à une organisation
-- (agence, bailleur, gestionnaire de patrimoine…).
--
-- Numérotée V200 pour passer APRÈS le jeu de démonstration (V100, profil dev) :
-- sur une base neuve comme sur une base existante, les données déjà présentes
-- sont rattachées à l'organisation « historique » créée ici. Les prochaines
-- migrations de schéma continuent en V200.x.
--
-- Garanties posées en base (et pas seulement dans le code) :
--   • organisation_id NOT NULL sur toutes les tables métier ;
--   • clés étrangères composites (id, organisation_id) : un bail ne peut pas
--     pointer vers le logement ou le locataire d'une autre organisation ;
--   • unicités métier (nom de bien, téléphone de locataire, référence de bail)
--     désormais propres à chaque organisation.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. Organisations, utilisateurs et adhésions
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS organisations (
    id                 BIGSERIAL PRIMARY KEY,
    nom                VARCHAR(150) NOT NULL,
    -- Identité du bailleur imprimée sur les contrats et les quittances.
    representant       VARCHAR(150),
    email              VARCHAR(150),
    telephone          VARCHAR(30),
    adresse            VARCHAR(255),
    ville              VARCHAR(100),
    pays               VARCHAR(2)   NOT NULL DEFAULT 'CI',
    devise             VARCHAR(3)   NOT NULL DEFAULT 'XOF',
    logo_cle           VARCHAR(255),
    logo_type          VARCHAR(100),
    -- Abonnement
    plan               VARCHAR(30)  NOT NULL,
    statut_abonnement  VARCHAR(30)  NOT NULL,
    essai_fin_le       DATE,
    abonnement_fin_le  DATE,
    -- Vrai pour l'unique organisation qui reprend les données d'avant le SaaS.
    historique         BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP    NOT NULL DEFAULT NOW(),
    created_by         VARCHAR(100),
    updated_by         VARCHAR(100),
    CONSTRAINT chk_organisations_plan
        CHECK (plan IN ('GRATUIT', 'ESSENTIEL', 'PROFESSIONNEL', 'ENTREPRISE')),
    CONSTRAINT chk_organisations_statut
        CHECK (statut_abonnement IN ('ESSAI', 'ACTIF', 'SUSPENDU', 'RESILIE'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_organisations_historique ON organisations (historique) WHERE historique;
CREATE INDEX IF NOT EXISTS idx_organisations_nom ON organisations (lower(nom));

-- Compte de connexion. L'authentification reste chez Keycloak : on ne garde ici
-- que le lien (keycloak_id = claim « sub » du jeton) et l'identité affichée.
CREATE TABLE IF NOT EXISTS utilisateurs (
    id                  BIGSERIAL PRIMARY KEY,
    keycloak_id         VARCHAR(64)  NOT NULL,
    email               VARCHAR(150) NOT NULL,
    prenom              VARCHAR(100),
    nom                 VARCHAR(100),
    telephone           VARCHAR(30),
    derniere_connexion  TIMESTAMP,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    created_by          VARCHAR(100),
    updated_by          VARCHAR(100),
    CONSTRAINT uk_utilisateurs_keycloak UNIQUE (keycloak_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_utilisateurs_email ON utilisateurs (lower(email));

-- Adhésion d'un utilisateur à une organisation, avec son rôle. Un même compte
-- peut appartenir à plusieurs organisations (un gestionnaire indépendant qui
-- travaille pour deux agences, par exemple).
CREATE TABLE IF NOT EXISTS membres (
    id               BIGSERIAL PRIMARY KEY,
    organisation_id  BIGINT      NOT NULL REFERENCES organisations (id) ON DELETE CASCADE,
    utilisateur_id   BIGINT      NOT NULL REFERENCES utilisateurs (id),
    role             VARCHAR(30) NOT NULL,
    actif            BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP   NOT NULL DEFAULT NOW(),
    created_by       VARCHAR(100),
    updated_by       VARCHAR(100),
    CONSTRAINT uk_membres_organisation_utilisateur UNIQUE (organisation_id, utilisateur_id),
    CONSTRAINT chk_membres_role CHECK (role IN ('PROPRIETAIRE', 'ADMIN', 'GESTIONNAIRE', 'LECTEUR'))
);

-- Un seul propriétaire par organisation.
CREATE UNIQUE INDEX IF NOT EXISTS uk_membres_proprietaire ON membres (organisation_id) WHERE role = 'PROPRIETAIRE';
CREATE INDEX IF NOT EXISTS idx_membres_utilisateur ON membres (utilisateur_id);

-- Numérotation propre à chaque organisation (BAIL-00001…), incrémentée de façon
-- atomique (INSERT … ON CONFLICT DO UPDATE … RETURNING).
CREATE TABLE IF NOT EXISTS compteurs_organisation (
    organisation_id  BIGINT      NOT NULL REFERENCES organisations (id) ON DELETE CASCADE,
    nom              VARCHAR(30) NOT NULL,
    valeur           BIGINT      NOT NULL,
    PRIMARY KEY (organisation_id, nom)
);

-- ----------------------------------------------------------------------------
-- 2. Organisation historique : reprend les données existantes, s'il y en a.
--    Ses utilisateurs (rôles Keycloak ADMIN / GESTIONNAIRE d'avant le SaaS) y
--    sont rattachés automatiquement à leur première connexion.
-- ----------------------------------------------------------------------------

INSERT INTO organisations (nom, plan, statut_abonnement, historique, created_by, updated_by)
SELECT 'TMK', 'ENTREPRISE', 'ACTIF', TRUE, 'system', 'system'
WHERE (EXISTS (SELECT 1 FROM immeubles) OR EXISTS (SELECT 1 FROM locataires))
  AND NOT EXISTS (SELECT 1 FROM organisations WHERE historique);

-- Les références de bail existantes (BAIL-<id>) restent valables : le compteur
-- de l'organisation historique repart après la plus grande.
INSERT INTO compteurs_organisation (organisation_id, nom, valeur)
SELECT o.id, 'BAIL', coalesce((SELECT max(b.id) FROM baux b), 0)
FROM organisations o
WHERE o.historique
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. Colonne organisation_id sur toutes les tables métier
-- ----------------------------------------------------------------------------

ALTER TABLE immeubles       ADD COLUMN IF NOT EXISTS organisation_id BIGINT;
ALTER TABLE appartements    ADD COLUMN IF NOT EXISTS organisation_id BIGINT;
ALTER TABLE locataires      ADD COLUMN IF NOT EXISTS organisation_id BIGINT;
ALTER TABLE baux            ADD COLUMN IF NOT EXISTS organisation_id BIGINT;
ALTER TABLE echeances_loyer ADD COLUMN IF NOT EXISTS organisation_id BIGINT;
ALTER TABLE paiements_loyer ADD COLUMN IF NOT EXISTS organisation_id BIGINT;
ALTER TABLE maintenances    ADD COLUMN IF NOT EXISTS organisation_id BIGINT;
ALTER TABLE photos_bien     ADD COLUMN IF NOT EXISTS organisation_id BIGINT;

UPDATE immeubles       SET organisation_id = (SELECT id FROM organisations WHERE historique) WHERE organisation_id IS NULL;
UPDATE appartements    SET organisation_id = (SELECT id FROM organisations WHERE historique) WHERE organisation_id IS NULL;
UPDATE locataires      SET organisation_id = (SELECT id FROM organisations WHERE historique) WHERE organisation_id IS NULL;
UPDATE baux            SET organisation_id = (SELECT id FROM organisations WHERE historique) WHERE organisation_id IS NULL;
UPDATE echeances_loyer SET organisation_id = (SELECT id FROM organisations WHERE historique) WHERE organisation_id IS NULL;
UPDATE paiements_loyer SET organisation_id = (SELECT id FROM organisations WHERE historique) WHERE organisation_id IS NULL;
UPDATE maintenances    SET organisation_id = (SELECT id FROM organisations WHERE historique) WHERE organisation_id IS NULL;
UPDATE photos_bien     SET organisation_id = (SELECT id FROM organisations WHERE historique) WHERE organisation_id IS NULL;

ALTER TABLE immeubles       ALTER COLUMN organisation_id SET NOT NULL;
ALTER TABLE appartements    ALTER COLUMN organisation_id SET NOT NULL;
ALTER TABLE locataires      ALTER COLUMN organisation_id SET NOT NULL;
ALTER TABLE baux            ALTER COLUMN organisation_id SET NOT NULL;
ALTER TABLE echeances_loyer ALTER COLUMN organisation_id SET NOT NULL;
ALTER TABLE paiements_loyer ALTER COLUMN organisation_id SET NOT NULL;
ALTER TABLE maintenances    ALTER COLUMN organisation_id SET NOT NULL;
ALTER TABLE photos_bien     ALTER COLUMN organisation_id SET NOT NULL;

ALTER TABLE immeubles       ADD CONSTRAINT fk_immeubles_organisation       FOREIGN KEY (organisation_id) REFERENCES organisations (id);
ALTER TABLE appartements    ADD CONSTRAINT fk_appartements_organisation    FOREIGN KEY (organisation_id) REFERENCES organisations (id);
ALTER TABLE locataires      ADD CONSTRAINT fk_locataires_organisation      FOREIGN KEY (organisation_id) REFERENCES organisations (id);
ALTER TABLE baux            ADD CONSTRAINT fk_baux_organisation            FOREIGN KEY (organisation_id) REFERENCES organisations (id);
ALTER TABLE echeances_loyer ADD CONSTRAINT fk_echeances_loyer_organisation FOREIGN KEY (organisation_id) REFERENCES organisations (id);
ALTER TABLE paiements_loyer ADD CONSTRAINT fk_paiements_loyer_organisation FOREIGN KEY (organisation_id) REFERENCES organisations (id);
ALTER TABLE maintenances    ADD CONSTRAINT fk_maintenances_organisation    FOREIGN KEY (organisation_id) REFERENCES organisations (id);
ALTER TABLE photos_bien     ADD CONSTRAINT fk_photos_bien_organisation     FOREIGN KEY (organisation_id) REFERENCES organisations (id);

-- ----------------------------------------------------------------------------
-- 4. Intégrité inter-organisations : clés étrangères composites
-- ----------------------------------------------------------------------------

ALTER TABLE immeubles       ADD CONSTRAINT uk_immeubles_id_organisation       UNIQUE (id, organisation_id);
ALTER TABLE appartements    ADD CONSTRAINT uk_appartements_id_organisation    UNIQUE (id, organisation_id);
ALTER TABLE locataires      ADD CONSTRAINT uk_locataires_id_organisation      UNIQUE (id, organisation_id);
ALTER TABLE baux            ADD CONSTRAINT uk_baux_id_organisation            UNIQUE (id, organisation_id);
ALTER TABLE echeances_loyer ADD CONSTRAINT uk_echeances_loyer_id_organisation UNIQUE (id, organisation_id);

ALTER TABLE appartements
    DROP CONSTRAINT IF EXISTS appartements_immeuble_id_fkey,
    ADD CONSTRAINT fk_appartements_immeuble
        FOREIGN KEY (immeuble_id, organisation_id) REFERENCES immeubles (id, organisation_id);

ALTER TABLE baux
    DROP CONSTRAINT IF EXISTS baux_appartement_id_fkey,
    DROP CONSTRAINT IF EXISTS baux_locataire_id_fkey,
    ADD CONSTRAINT fk_baux_appartement
        FOREIGN KEY (appartement_id, organisation_id) REFERENCES appartements (id, organisation_id),
    ADD CONSTRAINT fk_baux_locataire
        FOREIGN KEY (locataire_id, organisation_id) REFERENCES locataires (id, organisation_id);

ALTER TABLE echeances_loyer
    DROP CONSTRAINT IF EXISTS echeances_loyer_bail_id_fkey,
    ADD CONSTRAINT fk_echeances_loyer_bail
        FOREIGN KEY (bail_id, organisation_id) REFERENCES baux (id, organisation_id);

ALTER TABLE paiements_loyer
    DROP CONSTRAINT IF EXISTS paiements_loyer_echeance_id_fkey,
    ADD CONSTRAINT fk_paiements_loyer_echeance
        FOREIGN KEY (echeance_id, organisation_id) REFERENCES echeances_loyer (id, organisation_id);

-- appartement_id nul (parties communes) : la clé composite n'est pas vérifiée
-- (MATCH SIMPLE), exactement comme l'ancienne clé simple.
ALTER TABLE maintenances
    DROP CONSTRAINT IF EXISTS maintenances_immeuble_id_fkey,
    DROP CONSTRAINT IF EXISTS maintenances_appartement_id_fkey,
    ADD CONSTRAINT fk_maintenances_immeuble
        FOREIGN KEY (immeuble_id, organisation_id) REFERENCES immeubles (id, organisation_id),
    ADD CONSTRAINT fk_maintenances_appartement
        FOREIGN KEY (appartement_id, organisation_id) REFERENCES appartements (id, organisation_id);

ALTER TABLE photos_bien
    DROP CONSTRAINT IF EXISTS photos_bien_immeuble_id_fkey,
    ADD CONSTRAINT fk_photos_bien_immeuble
        FOREIGN KEY (immeuble_id, organisation_id) REFERENCES immeubles (id, organisation_id) ON DELETE CASCADE;

-- ----------------------------------------------------------------------------
-- 5. Unicités métier propres à chaque organisation
-- ----------------------------------------------------------------------------

ALTER TABLE immeubles
    DROP CONSTRAINT IF EXISTS immeubles_nom_key,
    ADD CONSTRAINT uk_immeubles_organisation_nom UNIQUE (organisation_id, nom);

ALTER TABLE locataires
    DROP CONSTRAINT IF EXISTS uk_locataires_telephone,
    ADD CONSTRAINT uk_locataires_organisation_telephone UNIQUE (organisation_id, telephone);

ALTER TABLE baux
    DROP CONSTRAINT IF EXISTS baux_reference_key,
    ADD CONSTRAINT uk_baux_organisation_reference UNIQUE (organisation_id, reference);

-- ----------------------------------------------------------------------------
-- 6. Index : toute requête métier commence par filtrer sur l'organisation
-- ----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_appartements_organisation_statut ON appartements (organisation_id, statut);
CREATE INDEX IF NOT EXISTS idx_locataires_organisation_nom      ON locataires (organisation_id, nom, prenom);
CREATE INDEX IF NOT EXISTS idx_baux_organisation_statut         ON baux (organisation_id, statut);
CREATE INDEX IF NOT EXISTS idx_echeances_organisation_periode   ON echeances_loyer (organisation_id, periode);
CREATE INDEX IF NOT EXISTS idx_echeances_organisation_ouvertes  ON echeances_loyer (organisation_id, date_echeance)
    WHERE statut IN ('A_PAYER', 'PARTIEL');
CREATE INDEX IF NOT EXISTS idx_paiements_organisation_date      ON paiements_loyer (organisation_id, date_paiement);
CREATE INDEX IF NOT EXISTS idx_maintenances_organisation_statut ON maintenances (organisation_id, statut);
