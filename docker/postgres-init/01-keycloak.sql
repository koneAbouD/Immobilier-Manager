-- Base dédiée à Keycloak, créée au premier démarrage du conteneur PostgreSQL.
CREATE USER keycloak WITH PASSWORD 'keycloak';
CREATE DATABASE keycloak OWNER keycloak;
