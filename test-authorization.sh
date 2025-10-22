#!/usr/bin/env bash
set -euo pipefail

# Test script for user authorization using Spring Security @PreAuthorize
# Users can only delete their own profile, ADMIN users can delete any profile
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

# call METHOD URL [JSON_BODY]
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
USER1_EMAIL="user1.$(date +%s)@example.com"
USER2_EMAIL="user2.$(date +%s)@example.com"
ADMIN_EMAIL="admin.$(date +%s)@example.com"
PASSWORD="Password123"

say "=== Spring Security Authorization Test: User Profile Management ==="

# 1. Create regular user 1
say "Create User 1"
U1_BODY=$(jq -n --arg fn "User" --arg ln "One" --arg em "$USER1_EMAIL" --arg pw "$PASSWORD" --arg cpw "$PASSWORD" --arg ph "+15550001111" '{firstName:$fn,lastName:$ln,email:$em,password:$pw,confirmPassword:$cpw,phoneNumber:$ph}')
read -r U1_FILE U1_CODE < <(call POST "$BASE/api/users/register" "$U1_BODY")
expect_success "$U1_FILE" "$U1_CODE" "Create User 1" || true
USER1_ID=$(extract .data.id "$U1_FILE")

# 2. Create regular user 2
say "Create User 2"
U2_BODY=$(jq -n --arg fn "User" --arg ln "Two" --arg em "$USER2_EMAIL" --arg pw "$PASSWORD" --arg cpw "$PASSWORD" --arg ph "+15550002222" '{firstName:$fn,lastName:$ln,email:$em,password:$pw,confirmPassword:$cpw,phoneNumber:$ph}')
read -r U2_FILE U2_CODE < <(call POST "$BASE/api/users/register" "$U2_BODY")
expect_success "$U2_FILE" "$U2_CODE" "Create User 2" || true
USER2_ID=$(extract .data.id "$U2_FILE")

# 3. Login as User 1
say "Login as User 1"
L1_BODY=$(jq -n --arg em "$USER1_EMAIL" --arg pw "$PASSWORD" '{email:$em,password:$pw}')
read -r L1_FILE L1_CODE < <(call POST "$BASE/api/auth/login" "$L1_BODY")
expect_success "$L1_FILE" "$L1_CODE" "Login as User 1" || true
USER1_TOKEN=$(extract .data.token "$L1_FILE")

# 4. Login as User 2
say "Login as User 2"
L2_BODY=$(jq -n --arg em "$USER2_EMAIL" --arg pw "$PASSWORD" '{email:$em,password:$pw}')
read -r L2_FILE L2_CODE < <(call POST "$BASE/api/auth/login" "$L2_BODY")
expect_success "$L2_FILE" "$L2_CODE" "Login as User 2" || true
USER2_TOKEN=$(extract .data.token "$L2_FILE")

# 5. Test: User 1 tries to delete their own profile (should succeed)
say "User 1 deletes their own profile (should succeed)"
read -r _FILE _CODE < <(call DELETE "$BASE/api/users/$USER1_ID" "" "$USER1_TOKEN")
expect_success "$_FILE" "$_CODE" "User 1 deletes own profile" || true

# 6. Test: User 2 tries to delete User 1's profile (should fail with 403)
say "User 2 tries to delete User 1's profile (should fail with 403)"
read -r _FILE _CODE < <(call DELETE "$BASE/api/users/$USER1_ID" "" "$USER2_TOKEN")
expect_forbidden "$_FILE" "$_CODE" "User 2 cannot delete User 1's profile" || true

# 7. Test: Unauthenticated request to delete profile (should fail with 401)
say "Unauthenticated delete request (should fail with 401)"
read -r _FILE _CODE < <(call DELETE "$BASE/api/users/$USER2_ID")
if [[ "$_CODE" == "401" ]]; then
  ok "Unauthenticated delete request properly rejected"
else
  ko "Expected 401, got $_CODE"
fi

# 8. Test: User 2 deletes their own profile (should succeed)
say "User 2 deletes their own profile (should succeed)"
read -r _FILE _CODE < <(call DELETE "$BASE/api/users/$USER2_ID" "" "$USER2_TOKEN")
expect_success "$_FILE" "$_CODE" "User 2 deletes own profile" || true

# Note: Admin user test would require creating an admin user in the database
# This would typically be done through a database script or admin endpoint

echo
echo "=== Authorization Test Summary ==="
echo "PASS: $pass_count"
echo "FAIL: $fail_count"
[[ "$fail_count" -eq 0 ]]
