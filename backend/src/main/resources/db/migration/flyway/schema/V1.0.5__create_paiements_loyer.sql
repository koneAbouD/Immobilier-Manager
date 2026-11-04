CREATE TABLE IF NOT EXISTS paiements_loyer (
    id                BIGSERIAL PRIMARY KEY,
    echeance_id       BIGINT         NOT NULL REFERENCES echeances_loyer (id),
    montant           NUMERIC(19, 2) NOT NULL,
    date_paiement     DATE           NOT NULL,
    mode_paiement     VARCHAR(30)    NOT NULL,
    reference         VARCHAR(100),
    commentaire       TEXT,
    annule            BOOLEAN        NOT NULL DEFAULT FALSE,
    motif_annulation  TEXT,
    annule_par        VARCHAR(100),
    annule_le         TIMESTAMP,
    created_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by        VARCHAR(100),
    updated_by        VARCHAR(100),
    CONSTRAINT chk_paiements_montant_positif CHECK (montant > 0),
    CONSTRAINT chk_paiements_mode CHECK (mode_paiement IN ('ESPECES', 'MOBILE_MONEY', 'VIREMENT', 'CHEQUE'))
);

CREATE INDEX IF NOT EXISTS idx_paiements_echeance ON paiements_loyer (echeance_id);
CREATE INDEX IF NOT EXISTS idx_paiements_date ON paiements_loyer (date_paiement);
