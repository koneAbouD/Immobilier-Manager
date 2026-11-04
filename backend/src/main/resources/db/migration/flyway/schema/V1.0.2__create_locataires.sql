CREATE TABLE IF NOT EXISTS locataires (
    id                        BIGSERIAL PRIMARY KEY,
    nom                       VARCHAR(100) NOT NULL,
    prenom                    VARCHAR(100) NOT NULL,
    telephone                 VARCHAR(30)  NOT NULL,
    email                     VARCHAR(150),
    type_piece                VARCHAR(30),
    numero_piece              VARCHAR(50),
    profession                VARCHAR(100),
    date_naissance            DATE,
    adresse                   VARCHAR(255),
    contact_urgence_nom       VARCHAR(150),
    contact_urgence_telephone VARCHAR(30),
    created_at                TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by                VARCHAR(100),
    updated_by                VARCHAR(100),
    CONSTRAINT uk_locataires_telephone UNIQUE (telephone)
);
