-- Contrat de bail : date de la dernière génération du PDF, puis exemplaire
-- signé chargé par le gestionnaire (rangé dans le stockage objet, la base n'en
-- garde que la clé et les métadonnées).
ALTER TABLE baux
    ADD COLUMN IF NOT EXISTS contrat_genere_le    TIMESTAMP,
    ADD COLUMN IF NOT EXISTS contrat_signe_cle    VARCHAR(255),
    ADD COLUMN IF NOT EXISTS contrat_signe_nom    VARCHAR(255),
    ADD COLUMN IF NOT EXISTS contrat_signe_type   VARCHAR(100),
    ADD COLUMN IF NOT EXISTS contrat_signe_taille BIGINT,
    ADD COLUMN IF NOT EXISTS contrat_signe_le     TIMESTAMP,
    ADD COLUMN IF NOT EXISTS contrat_signe_par    VARCHAR(100);
