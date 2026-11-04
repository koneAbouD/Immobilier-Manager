CREATE TABLE IF NOT EXISTS maintenances (
    id                BIGSERIAL PRIMARY KEY,
    immeuble_id       BIGINT       NOT NULL REFERENCES immeubles (id),
    -- Facultatif : une intervention peut porter sur les parties communes.
    appartement_id    BIGINT REFERENCES appartements (id),
    titre             VARCHAR(150) NOT NULL,
    description       TEXT,
    categorie         VARCHAR(30)  NOT NULL,
    priorite          VARCHAR(30)  NOT NULL,
    statut            VARCHAR(30)  NOT NULL,
    date_signalement  DATE         NOT NULL,
    date_prevue       DATE,
    date_realisation  DATE,
    prestataire       VARCHAR(150),
    cout_estime       NUMERIC(19, 2),
    cout_reel         NUMERIC(19, 2),
    motif_annulation  TEXT,
    annule_par        VARCHAR(100),
    annule_le         TIMESTAMP,
    created_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by        VARCHAR(100),
    updated_by        VARCHAR(100),
    CONSTRAINT chk_maintenances_statut CHECK (statut IN ('SIGNALEE', 'PLANIFIEE', 'EN_COURS', 'TERMINEE', 'ANNULEE')),
    CONSTRAINT chk_maintenances_priorite CHECK (priorite IN ('BASSE', 'NORMALE', 'HAUTE', 'URGENTE'))
);

CREATE INDEX IF NOT EXISTS idx_maintenances_immeuble ON maintenances (immeuble_id);
CREATE INDEX IF NOT EXISTS idx_maintenances_statut ON maintenances (statut);
