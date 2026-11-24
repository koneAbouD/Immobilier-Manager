-- Connexion par numéro de téléphone : l'e-mail devient facultatif, le
-- téléphone d'un compte est unique (c'est son identifiant de connexion).
ALTER TABLE utilisateurs ALTER COLUMN email DROP NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uk_utilisateurs_telephone
    ON utilisateurs (telephone) WHERE telephone IS NOT NULL;
