#!/usr/bin/env bash
# Met à niveau un realm DÉJÀ importé pour le SaaS (l'import du JSON n'a lieu
# qu'au premier démarrage de Keycloak) :
#   • active le compte de service du client backend et lui donne les rôles
#     realm-management manage-users / view-users / query-users (création des
#     comptes à l'inscription et à l'invitation) ;
#   • crée le rôle SUPER_ADMIN (back-office de la plateforme) ;
#   • ferme l'inscription libre côté Keycloak (seul le backend crée des comptes) ;
#   • rend l'e-mail facultatif dans le profil utilisateur : les comptes se
#     connectent avec leur numéro de téléphone (Keycloak ≥ 24 exige sinon un
#     e-mail et refuse la connexion : « Account is not fully set up »).
# Idempotent : peut être relancé sans risque.
#
#   ./keycloak/configurer-compte-service.sh                  # local (docker compose)
#   KC_URL=https://auth.example.com KC_ADMIN=… KC_ADMIN_PASSWORD=… ./keycloak/configurer-compte-service.sh
#
# Option : SUPER_ADMIN_USER=<identifiant> donne le rôle SUPER_ADMIN à ce compte.
set -euo pipefail

KC_CONTAINER="${KC_CONTAINER:-immobilier-manager-keycloak}"
KC_URL="${KC_URL:-http://localhost:8180}"
KC_ADMIN="${KC_ADMIN:-admin}"
KC_ADMIN_PASSWORD="${KC_ADMIN_PASSWORD:-admin}"
REALM="${REALM:-immobilier-manager}"
CLIENT_ID="${CLIENT_ID:-immobilier-manager-backend}"

if [[ -n "${KC_URL_DISTANT:-}" || "$KC_URL" != http://localhost:* ]]; then
  KCADM=(kcadm.sh)
else
  KCADM=(docker exec -i "$KC_CONTAINER" /opt/keycloak/bin/kcadm.sh)
  KC_URL="http://localhost:8180"
fi

"${KCADM[@]}" config credentials --server "$KC_URL" --realm master --user "$KC_ADMIN" --password "$KC_ADMIN_PASSWORD" >/dev/null

CID=$("${KCADM[@]}" get clients -r "$REALM" -q clientId="$CLIENT_ID" --fields id --format csv --noquotes)
[[ -n "$CID" ]] || { echo "Client $CLIENT_ID introuvable dans le realm $REALM" >&2; exit 1; }

"${KCADM[@]}" update "clients/$CID" -r "$REALM" -s serviceAccountsEnabled=true
"${KCADM[@]}" add-roles -r "$REALM" --uusername "service-account-$CLIENT_ID" \
  --cclientid realm-management --rolename manage-users --rolename view-users --rolename query-users
echo "✔ Compte de service de $CLIENT_ID : manage-users, view-users, query-users"

"${KCADM[@]}" get "roles/SUPER_ADMIN" -r "$REALM" >/dev/null 2>&1 \
  || "${KCADM[@]}" create roles -r "$REALM" -s name=SUPER_ADMIN \
       -s 'description=Éditeur de la plateforme : suivi des organisations et des abonnements'
echo "✔ Rôle SUPER_ADMIN"

"${KCADM[@]}" update "realms/$REALM" -s registrationAllowed=false -s loginWithEmailAllowed=true -s duplicateEmailsAllowed=false
echo "✔ Inscription libre fermée côté Keycloak, connexion par e-mail autorisée"

PROFIL=$("${KCADM[@]}" get users/profile -r "$REALM")
echo "$PROFIL" | python3 -c '
import json, sys
profil = json.load(sys.stdin)
for attribut in profil.get("attributes", []):
    if attribut.get("name") == "email":
        attribut.pop("required", None)
json.dump(profil, sys.stdout)
' | "${KCADM[@]}" update users/profile -r "$REALM" -f - >/dev/null
echo "✔ E-mail facultatif (connexion par numéro de téléphone)"

if [[ -n "${SUPER_ADMIN_USER:-}" ]]; then
  "${KCADM[@]}" add-roles -r "$REALM" --uusername "$SUPER_ADMIN_USER" --rolename SUPER_ADMIN
  echo "✔ SUPER_ADMIN donné à $SUPER_ADMIN_USER"
fi
