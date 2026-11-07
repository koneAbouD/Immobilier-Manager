-- Photos d'un bien, rangées dans le stockage objet ; la base n'en garde que
-- la clé et les métadonnées.
CREATE TABLE IF NOT EXISTS photos_bien (
    id          BIGSERIAL PRIMARY KEY,
    immeuble_id BIGINT       NOT NULL REFERENCES immeubles (id) ON DELETE CASCADE,
    cle         VARCHAR(255) NOT NULL,
    nom         VARCHAR(255),
    type        VARCHAR(100) NOT NULL,
    taille      BIGINT       NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by  VARCHAR(100),
    updated_by  VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_photos_bien_immeuble ON photos_bien (immeuble_id);
