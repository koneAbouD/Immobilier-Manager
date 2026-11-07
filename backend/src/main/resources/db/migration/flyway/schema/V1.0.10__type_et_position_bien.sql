-- Nature du bien (immeuble, cour basse, terrain) et position GPS relevée sur
-- place ; les biens existants sont des immeubles.
ALTER TABLE immeubles
    ADD COLUMN IF NOT EXISTS type_bien VARCHAR(30) NOT NULL DEFAULT 'IMMEUBLE',
    ADD COLUMN IF NOT EXISTS latitude  NUMERIC(9, 6),
    ADD COLUMN IF NOT EXISTS longitude NUMERIC(9, 6);

ALTER TABLE immeubles
    ADD CONSTRAINT chk_immeubles_type_bien CHECK (type_bien IN ('IMMEUBLE', 'COUR_BASSE', 'TERRAIN'));
