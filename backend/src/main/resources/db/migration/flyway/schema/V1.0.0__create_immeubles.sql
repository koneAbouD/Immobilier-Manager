CREATE TABLE IF NOT EXISTS immeubles (
    id                 BIGSERIAL PRIMARY KEY,
    nom                VARCHAR(150) NOT NULL UNIQUE,
    adresse            VARCHAR(255),
    commune            VARCHAR(100),
    ville              VARCHAR(100),
    nombre_etages      INTEGER,
    annee_construction INTEGER,
    description        TEXT,
    created_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by         VARCHAR(100),
    updated_by         VARCHAR(100)
);
