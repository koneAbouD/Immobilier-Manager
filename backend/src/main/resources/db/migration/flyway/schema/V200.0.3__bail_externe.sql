-- Bail externe : le recouvrement des loyers est assuré par une autre entité
-- (agence, mandataire…). L'application n'émet aucun loyer pour ces baux.
ALTER TABLE baux ADD COLUMN IF NOT EXISTS externe BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE baux ADD COLUMN IF NOT EXISTS gestionnaire_externe VARCHAR(150);
