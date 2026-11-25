-- Journal des modifications et suppressions (biens, locaux, locataires, travaux).
-- Libellés et auteur figés au moment de l'action : la trace reste lisible après
-- la suppression de la donnée ou le départ du membre. Pas de clé étrangère vers
-- la donnée tracée, qui peut avoir disparu.
CREATE TABLE IF NOT EXISTS journal_actions (
    id              BIGSERIAL PRIMARY KEY,
    organisation_id BIGINT       NOT NULL REFERENCES organisations (id) ON DELETE CASCADE,
    date_action     TIMESTAMP    NOT NULL,
    action          VARCHAR(20)  NOT NULL,
    type_entite     VARCHAR(20)  NOT NULL,
    entite_id       BIGINT,
    libelle         VARCHAR(255),
    contexte        VARCHAR(255),
    auteur_id       BIGINT,
    auteur_nom      VARCHAR(255),
    changements     JSONB        NOT NULL DEFAULT '[]'::jsonb,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    created_by      VARCHAR(100),
    updated_by      VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_journal_actions_organisation_date
    ON journal_actions (organisation_id, date_action DESC, id DESC);
