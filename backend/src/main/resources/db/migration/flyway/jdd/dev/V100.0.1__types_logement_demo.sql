-- Le jeu de démo V100.0.0 insère encore d'anciennes typologies (T2, STUDIO…),
-- après le passage de V1.0.7 : on les ramène aux trois types actuels.
UPDATE appartements
SET type = 'APPARTEMENT'
WHERE type NOT IN ('APPARTEMENT', 'MAGASIN', 'BUREAU');
