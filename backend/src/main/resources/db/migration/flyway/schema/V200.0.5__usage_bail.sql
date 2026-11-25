-- Régime du bail (habitation ou professionnel) : il fixe le modèle de contrat.
-- Les baux existants reprennent le régime que leur contrat affichait déjà,
-- déduit de la nature du local.
ALTER TABLE baux ADD COLUMN IF NOT EXISTS usage_bail VARCHAR(20);

UPDATE baux b
SET usage_bail = CASE WHEN a.type = 'APPARTEMENT' THEN 'HABITATION' ELSE 'PROFESSIONNEL' END
FROM appartements a
WHERE a.id = b.appartement_id
  AND b.usage_bail IS NULL;

UPDATE baux SET usage_bail = 'HABITATION' WHERE usage_bail IS NULL;

ALTER TABLE baux ALTER COLUMN usage_bail SET DEFAULT 'HABITATION';
ALTER TABLE baux ALTER COLUMN usage_bail SET NOT NULL;
