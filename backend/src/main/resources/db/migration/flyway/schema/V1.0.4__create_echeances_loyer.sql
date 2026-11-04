CREATE TABLE IF NOT EXISTS echeances_loyer (
    id              BIGSERIAL PRIMARY KEY,
    bail_id         BIGINT         NOT NULL REFERENCES baux (id),
    -- Premier jour du mois concerné.
    periode         DATE           NOT NULL,
    date_echeance   DATE           NOT NULL,
    montant_du      NUMERIC(19, 2) NOT NULL,
    montant_paye    NUMERIC(19, 2) NOT NULL DEFAULT 0,
    statut          VARCHAR(30)    NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by      VARCHAR(100),
    updated_by      VARCHAR(100),
    -- La génération est idempotente : un seul loyer par bail et par mois.
    CONSTRAINT uk_echeances_bail_periode UNIQUE (bail_id, periode),
    CONSTRAINT chk_echeances_statut CHECK (statut IN ('A_PAYER', 'PARTIEL', 'PAYEE', 'ANNULEE'))
);

CREATE INDEX IF NOT EXISTS idx_echeances_statut ON echeances_loyer (statut);
CREATE INDEX IF NOT EXISTS idx_echeances_date_echeance ON echeances_loyer (date_echeance);
