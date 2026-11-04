CREATE TABLE IF NOT EXISTS baux (
    id                 BIGSERIAL PRIMARY KEY,
    reference          VARCHAR(30) UNIQUE,
    appartement_id     BIGINT         NOT NULL REFERENCES appartements (id),
    locataire_id       BIGINT         NOT NULL REFERENCES locataires (id),
    date_debut         DATE           NOT NULL,
    date_fin           DATE,
    loyer_mensuel      NUMERIC(19, 2) NOT NULL,
    charges            NUMERIC(19, 2) NOT NULL DEFAULT 0,
    depot_garantie     NUMERIC(19, 2) NOT NULL DEFAULT 0,
    jour_echeance      INTEGER        NOT NULL DEFAULT 5,
    statut             VARCHAR(30)    NOT NULL,
    date_resiliation   DATE,
    motif_resiliation  TEXT,
    resilie_par        VARCHAR(100),
    created_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by         VARCHAR(100),
    updated_by         VARCHAR(100),
    CONSTRAINT chk_baux_statut CHECK (statut IN ('ACTIF', 'RESILIE')),
    CONSTRAINT chk_baux_jour_echeance CHECK (jour_echeance BETWEEN 1 AND 28)
);

-- Un logement n'a jamais deux baux actifs en même temps : garde-fou en base
-- de la règle vérifiée par le use case de création.
CREATE UNIQUE INDEX IF NOT EXISTS uk_baux_appartement_actif
    ON baux (appartement_id) WHERE statut = 'ACTIF';
CREATE INDEX IF NOT EXISTS idx_baux_locataire ON baux (locataire_id);
