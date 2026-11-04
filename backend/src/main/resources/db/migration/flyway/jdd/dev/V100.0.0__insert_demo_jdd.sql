-- Jeu de démonstration (profil dev uniquement). Les baux ne sont pas insérés
-- ici : signés via l'API, ils émettent leurs échéances comme en réel.
INSERT INTO immeubles (nom, adresse, commune, ville, nombre_etages, annee_construction, description, created_by)
VALUES ('Résidence Les Palmiers', 'Rue des Jardins, lot 12', 'Cocody', 'Abidjan', 4, 2015, 'Immeuble résidentiel avec parking', 'system'),
       ('Immeuble Plateau Center', 'Avenue Chardy', 'Plateau', 'Abidjan', 6, 2010, 'Bureaux et commerces en rez-de-chaussée', 'system')
ON CONFLICT DO NOTHING;

INSERT INTO appartements (immeuble_id, reference, etage, type, superficie, nombre_pieces, loyer_mensuel, charges, statut, created_by)
SELECT i.id, a.reference, a.etage, a.type, a.superficie, a.pieces, a.loyer, a.charges, a.statut, 'system'
FROM immeubles i
JOIN (VALUES
    ('Résidence Les Palmiers', 'A01', 0, 'T2', 55.00, 2, 150000.00, 10000.00, 'LIBRE'),
    ('Résidence Les Palmiers', 'A02', 0, 'T3', 75.00, 3, 220000.00, 15000.00, 'LIBRE'),
    ('Résidence Les Palmiers', 'B11', 1, 'STUDIO', 30.00, 1, 90000.00, 5000.00, 'LIBRE'),
    ('Résidence Les Palmiers', 'B12', 1, 'T4', 95.00, 4, 300000.00, 20000.00, 'EN_TRAVAUX'),
    ('Immeuble Plateau Center', 'RDC-1', 0, 'MAGASIN', 60.00, 1, 400000.00, 25000.00, 'LIBRE'),
    ('Immeuble Plateau Center', 'E3-B', 3, 'BUREAU', 80.00, 3, 350000.00, 30000.00, 'LIBRE')
) AS a(immeuble, reference, etage, type, superficie, pieces, loyer, charges, statut) ON a.immeuble = i.nom
ON CONFLICT DO NOTHING;

INSERT INTO locataires (nom, prenom, telephone, email, type_piece, numero_piece, profession, created_by)
VALUES ('Kouassi', 'Aya', '0707010203', 'aya.kouassi@example.com', 'CNI', 'CI0012345', 'Comptable', 'system'),
       ('Traoré', 'Moussa', '0505040506', NULL, 'PASSEPORT', '20AB12345', 'Commerçant', 'system'),
       ('Bamba', 'Fatou', '0101070809', 'fatou.bamba@example.com', 'CNI', 'CI0098765', 'Enseignante', 'system')
ON CONFLICT DO NOTHING;
