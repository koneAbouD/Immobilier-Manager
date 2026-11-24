-- Mois d'avance : loyers réglés à la signature, distincts de la caution
-- (dépôt restituable). Le premier mois facturé en découle :
--   max(mois de création + 1, mois de début + mois d'avance).
ALTER TABLE baux ADD COLUMN IF NOT EXISTS mois_avance INTEGER NOT NULL DEFAULT 0;
ALTER TABLE baux ADD CONSTRAINT chk_baux_mois_avance CHECK (mois_avance BETWEEN 0 AND 24);

ALTER TABLE baux ADD COLUMN IF NOT EXISTS premier_mois_facture DATE;

-- Baux existants : leurs loyers déjà émis restent tels quels, la facturation
-- reprend donc au premier mois déjà émis. Sans loyer émis, la nouvelle règle
-- s'applique à partir de la date de création.
UPDATE baux b
SET premier_mois_facture = COALESCE(
        (SELECT MIN(e.periode) FROM echeances_loyer e WHERE e.bail_id = b.id),
        GREATEST(
            (date_trunc('month', COALESCE(b.created_at, NOW())) + INTERVAL '1 month')::date,
            date_trunc('month', b.date_debut)::date))
WHERE premier_mois_facture IS NULL;

ALTER TABLE baux ALTER COLUMN premier_mois_facture SET NOT NULL;
ALTER TABLE baux ADD CONSTRAINT chk_baux_premier_mois_facture
    CHECK (EXTRACT(DAY FROM premier_mois_facture) = 1
           AND premier_mois_facture >= date_trunc('month', date_debut)::date);
