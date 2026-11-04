CREATE TABLE IF NOT EXISTS appartements (
    id              BIGSERIAL PRIMARY KEY,
    immeuble_id     BIGINT        NOT NULL REFERENCES immeubles (id),
    reference       VARCHAR(50)   NOT NULL,
    etage           INTEGER,
    type            VARCHAR(30)   NOT NULL,
    superficie      NUMERIC(10, 2),
    nombre_pieces   INTEGER,
    loyer_mensuel   NUMERIC(19, 2) NOT NULL,
    charges         NUMERIC(19, 2) NOT NULL DEFAULT 0,
    statut          VARCHAR(30)   NOT NULL,
    description     TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by      VARCHAR(100),
    updated_by      VARCHAR(100),
    -- Deux logements d'un même immeuble ne portent jamais la même référence.
    CONSTRAINT uk_appartements_immeuble_reference UNIQUE (immeuble_id, reference),
    CONSTRAINT chk_appartements_statut CHECK (statut IN ('LIBRE', 'OCCUPE', 'EN_TRAVAUX'))
);

CREATE INDEX IF NOT EXISTS idx_appartements_immeuble ON appartements (immeuble_id);
CREATE INDEX IF NOT EXISTS idx_appartements_statut ON appartements (statut);
