#!/usr/bin/env bash
set -euo pipefail

# Test script for admin authorization using Spring Security @PreAuthorize
# Tests that admin users can access all user resources
# Requirements: curl, jq

BASE=${BASE:-http://localhost:8088}
CT="Content-Type: application/json"

command -v curl >/dev/null 2>&1 || { echo "curl is required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 1; }

pass_count=0
fail_count=0

say() { printf "\n== %s ==\n" "$*"; }
ok()  { echo "[PASS] $*"; pass_count=$((pass_count+1)); }
ko()  { echo "[FAIL] $*"; fail_count=$((fail_count+1)); }

# call METHOD URL [JSON_BODY] [TOKEN]
call() {
  local method="$1" url="$2" body="${3:-}" token="${4:-}"
  local resp_file
  resp_file=$(mktemp)
  
  if [[ -n "$body" ]]; then
    if [[ -n "$token" ]]; then
      http_code=$(curl -sS -o "$resp_file" -w "%{http_code}" -H "$CT" -H "Authorization: Bearer $token" -X "$method" --data "$body" "$url") || http_code=000
    else
      http_code=$(curl -sS -o "$resp_file" -w "%{http_code}" -H "$CT" -X "$method" --data "$body" "$url") || http_code=000
    fi
  else
    if [[ -n "$token" ]]; then
      http_code=$(curl -sS -o "$resp_file" -w "%{http_code}" -H "Authorization: Bearer $token" -X "$method" "$url") || http_code=000
    else
      http_code=$(curl -sS -o "$resp_file" -w "%{http_code}" -X "$method" "$url") || http_code=000
    fi
  fi
  
  printf "%s" "$resp_file"
  echo " $http_code"
}

expect_success() {
  local resp_file="$1" http_code="$2" label="$3"
  if [[ "$http_code" != "200" && "$http_code" != "201" ]]; then
    ko "$label (http $http_code)"; jq . "$resp_file" || cat "$resp_file"; return 1
  fi
  ok "$label"; return 0
}

expect_forbidden() {
  local resp_file="$1" http_code="$2" label="$3"
  if [[ "$http_code" != "403" ]]; then
    ko "$label (expected 403, got $http_code)"; jq . "$resp_file" || cat "$resp_file"; return 1
  fi
  ok "$label"; return 0
}

extract() { jq -r "$1" "$2"; }

# Test data
USER_EMAIL="regular.$(date +%s)@example.com"
ADMIN_EMAIL="admin@example.com"
PASSWORD="Password123"
ADMIN_PASSWORD="admin123"

say "=== Spring Security Admin Authorization Test ==="

# 1. Create regular user
say "Create Regular User"
U_BODY=$(jq -n --arg fn "Regular" --arg ln "User" --arg em "$USER_EMAIL" --arg pw "$PASSWORD" --arg cpw "$PASSWORD" --arg ph "+15550001111" '{firstName:$fn,lastName:$ln,email:$em,password:$pw,confirmPassword:$cpw,phoneNumber:$ph}')
read -r U_FILE U_CODE < <(call POST "$BASE/api/users/register" "$U_BODY")
expect_success "$U_FILE" "$U_CODE" "Create Regular User" || true
USER_ID=$(extract .data.id "$U_FILE")

# 2. Login as regular user
say "Login as Regular User"
L_BODY=$(jq -n --arg em "$USER_EMAIL" --arg pw "$PASSWORD" '{email:$em,password:$pw}')
read -r L_FILE L_CODE < <(call POST "$BASE/api/auth/login" "$L_BODY")
expect_success "$L_FILE" "$L_CODE" "Login as Regular User" || true
USER_TOKEN=$(extract .data.token "$L_FILE")

# 3. Login as admin user (assuming admin user exists from create-admin-user.sql)
say "Login as Admin User"
ADMIN_BODY=$(jq -n --arg em "$ADMIN_EMAIL" --arg pw "$ADMIN_PASSWORD" '{email:$em,password:$pw}')
read -r ADMIN_FILE ADMIN_CODE < <(call POST "$BASE/api/auth/login" "$ADMIN_BODY")
expect_success "$ADMIN_FILE" "$ADMIN_CODE" "Login as Admin User" || true
ADMIN_TOKEN=$(extract .data.token "$ADMIN_FILE")

# 4. Test: Regular user tries to get all users (should fail with 403)
say "Regular user tries to get all users (should fail with 403)"
read -r _FILE _CODE < <(call GET "$BASE/api/users" "" "$USER_TOKEN")
expect_forbidden "$_FILE" "$_CODE" "Regular user cannot get all users" || true

# 5. Test: Admin user tries to get all users (should succeed)
say "Admin user gets all users (should succeed)"
read -r _FILE _CODE < <(call GET "$BASE/api/users" "" "$ADMIN_TOKEN")
expect_success "$_FILE" "$_CODE" "Admin user can get all users" || true

# 6. Test: Regular user tries to get another user's profile (should fail with 403)
say "Regular user tries to get another user's profile (should fail with 403)"
# First, get admin user's ID
ADMIN_ID=$(extract '.data[] | select(.email == "admin@example.com") | .id' "$_FILE")
if [[ -n "$ADMIN_ID" && "$ADMIN_ID" != "null" ]]; then
  read -r _FILE _CODE < <(call GET "$BASE/api/users/$ADMIN_ID" "" "$USER_TOKEN")
  expect_forbidden "$_FILE" "$_CODE" "Regular user cannot get admin's profile" || true
fi

# 7. Test: Admin user tries to get regular user's profile (should succeed)
say "Admin user gets regular user's profile (should succeed)"
read -r _FILE _CODE < <(call GET "$BASE/api/users/$USER_ID" "" "$ADMIN_TOKEN")
expect_success "$_FILE" "$_CODE" "Admin user can get regular user's profile" || true

# 8. Test: Regular user tries to update another user's profile (should fail with 403)
say "Regular user tries to update admin's profile (should fail with 403)"
if [[ -n "$ADMIN_ID" && "$ADMIN_ID" != "null" ]]; then
  UPDATE_BODY=$(jq -n --arg fn "Updated" --arg ln "Admin" --arg em "$ADMIN_EMAIL" --arg ph "+15550009999" '{firstName:$fn,lastName:$ln,email:$em,phoneNumber:$ph}')
  read -r _FILE _CODE < <(call PUT "$BASE/api/users/$ADMIN_ID" "$UPDATE_BODY" "$USER_TOKEN")
  expect_forbidden "$_FILE" "$_CODE" "Regular user cannot update admin's profile" || true
fi

# 9. Test: Admin user tries to update regular user's profile (should succeed)
say "Admin user updates regular user's profile (should succeed)"
UPDATE_BODY=$(jq -n --arg fn "Updated" --arg ln "User" --arg em "$USER_EMAIL" --arg ph "+15550008888" '{firstName:$fn,lastName:$ln,email:$em,phoneNumber:$ph}')
read -r _FILE _CODE < <(call PUT "$BASE/api/users/$USER_ID" "$UPDATE_BODY" "$ADMIN_TOKEN")
expect_success "$_FILE" "$_CODE" "Admin user can update regular user's profile" || true

# 10. Test: Regular user tries to delete another user's profile (should fail with 403)
say "Regular user tries to delete admin's profile (should fail with 403)"
if [[ -n "$ADMIN_ID" && "$ADMIN_ID" != "null" ]]; then
  read -r _FILE _CODE < <(call DELETE "$BASE/api/users/$ADMIN_ID" "" "$USER_TOKEN")
  expect_forbidden "$_FILE" "$_CODE" "Regular user cannot delete admin's profile" || true
fi

# 11. Test: Admin user tries to delete regular user's profile (should succeed)
say "Admin user deletes regular user's profile (should succeed)"
read -r _FILE _CODE < <(call DELETE "$BASE/api/users/$USER_ID" "" "$ADMIN_TOKEN")
expect_success "$_FILE" "$_CODE" "Admin user can delete regular user's profile" || true

echo
echo "=== Admin Authorization Test Summary ==="
echo "PASS: $pass_count"
echo "FAIL: $fail_count"
[[ "$fail_count" -eq 0 ]]
