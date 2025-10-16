#!/usr/bin/env bash
set -euo pipefail

# ---- CONFIG ----
BASE_URL="${BASE_URL:-http://192.168.86.129/SecretServer}"   # no trailing slash; must include /SecretServer
USERNAME="${USERNAME:-kcjones}"
PASSWORD="${PASSWORD:-Cora0410}"
SECRET_ID="${SECRET_ID:-2}"

# Optional: jq pretty-print if available
JQ="$(command -v jq || true)"

say() { printf '%s\n' "$*" >&2; }

# ---- 1) Get OAuth token ----
say ">> Getting token from ${BASE_URL}/oauth2/token as ${USERNAME}"
TOK_JSON="$(curl -sS -X POST \
  -d "grant_type=password" \
  -d "username=${USERNAME}" \
  -d "password=${PASSWORD}" \
  "${BASE_URL}/oauth2/token")" || { say "!! token request failed"; exit 2; }

ACCESS_TOKEN="$(printf '%s' "$TOK_JSON" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')"
if [[ -z "${ACCESS_TOKEN}" ]]; then
  say "!! no access_token in response:"
  [[ -n "$JQ" ]] && printf '%s\n' "$TOK_JSON" | jq . || printf '%s\n' "$TOK_JSON"
  exit 3
fi
say ">> Token acquired (len=$(printf '%s' "$ACCESS_TOKEN" | wc -c | tr -d ' '))"

# ---- 2) Try secret read via REST ----
API_URL="${BASE_URL}/api/v1/secrets/${SECRET_ID}"
say ">> GET ${API_URL}"
HTTP_CODE=0
RESP="$(curl -sS -w '\n%{http_code}' -H "Authorization: Bearer ${ACCESS_TOKEN}" -H 'Accept: application/json' "${API_URL}")" || true
BODY="${RESP%$'\n'*}"
HTTP_CODE="${RESP##*$'\n'}"

say ">> HTTP ${HTTP_CODE}"
if [[ -n "$JQ" ]]; then
  printf '%s\n' "$BODY" | jq . || printf '%s\n' "$BODY"
else
  printf '%s\n' "$BODY"
fi

# Exit non-zero on obvious failures
case "$HTTP_CODE" in
  200) exit 0 ;;
  401|403|404|500) exit 10 ;;
  *) exit 1 ;;
esac

