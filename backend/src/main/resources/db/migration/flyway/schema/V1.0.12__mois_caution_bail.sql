-- Caution exprimée en mois de loyer : le dépôt de garantie en découle
-- (mois × loyer mensuel). Nulle pour les baux saisis avec un montant libre.
ALTER TABLE baux ADD COLUMN IF NOT EXISTS mois_caution INTEGER;
ALTER TABLE baux ADD CONSTRAINT chk_baux_mois_caution CHECK (mois_caution IS NULL OR mois_caution BETWEEN 0 AND 24);
