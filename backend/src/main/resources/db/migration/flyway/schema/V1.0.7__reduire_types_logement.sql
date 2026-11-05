-- Les types se limitent désormais à APPARTEMENT, MAGASIN et BUREAU : les
-- anciennes typologies d'habitation (STUDIO, T2, VILLA…) deviennent APPARTEMENT,
-- leur taille restant portée par nombre_pieces.
UPDATE appartements
SET type = 'APPARTEMENT', updated_at = NOW(), updated_by = 'system'
WHERE type NOT IN ('APPARTEMENT', 'MAGASIN', 'BUREAU');
