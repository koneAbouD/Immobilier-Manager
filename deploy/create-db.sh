#!/bin/sh
# Crée le rôle et la base d'Immobilier Manager dans le conteneur Postgres (timescaledb).
# Lit DB_NAME / DB_USERNAME / DB_PASSWORD depuis le .env voisin. Idempotent.
# Usage : ./create-db.sh [nom_du_conteneur]   (défaut : timescaledb)
set -eu

cd "$(dirname "$0")"
CONTAINER="${1:-timescaledb}"

set -a; . ./.env; set +a

# Superutilisateur défini à la création du conteneur (POSTGRES_USER, sinon postgres)
SUPERUSER="$(docker exec "$CONTAINER" printenv POSTGRES_USER 2>/dev/null || true)"
SUPERUSER="${SUPERUSER:-postgres}"

docker exec -i "$CONTAINER" psql -U "$SUPERUSER" -d postgres -v ON_ERROR_STOP=1 \
  -v user="$DB_USERNAME" -v pw="$DB_PASSWORD" -v db="$DB_NAME" <<'SQL'
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'user', :'pw')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'user') \gexec
-- Réaligne le mot de passe si le rôle existait déjà
ALTER ROLE :"user" WITH LOGIN PASSWORD :'pw';

SELECT format('CREATE DATABASE %I OWNER %I', :'db', :'user')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'db') \gexec

\c :"db"
-- Flyway crée les tables dans public : le rôle applicatif doit en être propriétaire
ALTER SCHEMA public OWNER TO :"user";
SQL

echo "Base '$DB_NAME' prête pour le rôle '$DB_USERNAME' dans le conteneur '$CONTAINER'."
