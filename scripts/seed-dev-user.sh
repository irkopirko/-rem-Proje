#!/usr/bin/env bash
# Creates the dev login account in Supabase (Auth + profiles row via app register flow).
# Run from project root: bash scripts/seed-dev-user.sh

set -euo pipefail

PROJECT_URL="https://zmnbzmltemejqmgvbwou.supabase.co"
ANON_KEY="sb_publishable_Ej2uzr54nnCenw7VwDoMYQ_kQUaBEDb"
EMAIL="iremcelikk2@hotmail.com"
PASSWORD="123Remi*"
NAME="İrem Çelik"

echo "Signing up $EMAIL ..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$PROJECT_URL/auth/v1/signup" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"data\":{\"name\":\"$NAME\"}}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo "HTTP $HTTP_CODE"

if [[ "$HTTP_CODE" == "200" ]] || echo "$BODY" | grep -qi "already registered"; then
  echo "Done. Login with: $EMAIL / $PASSWORD"
else
  echo "Sign-up did not succeed. Open the app once — it will seed the account on launch."
  exit 1
fi
