-- Copie numérisée de la pièce d'identité du locataire, rangée dans le
-- stockage objet ; la base n'en garde que la clé et les métadonnées.
ALTER TABLE locataires
    ADD COLUMN IF NOT EXISTS piece_cle         VARCHAR(255),
    ADD COLUMN IF NOT EXISTS piece_nom         VARCHAR(255),
    ADD COLUMN IF NOT EXISTS piece_type        VARCHAR(100),
    ADD COLUMN IF NOT EXISTS piece_taille      BIGINT,
    ADD COLUMN IF NOT EXISTS piece_chargee_le  TIMESTAMP,
    ADD COLUMN IF NOT EXISTS piece_chargee_par VARCHAR(100);
