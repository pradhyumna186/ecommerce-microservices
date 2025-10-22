#!/usr/bin/env bash
set -euo pipefail

# Simple end-to-end API test runner for the E-commerce microservices via API Gateway
# Requirements: curl, jq

BASE=${BASE:-http://localhost:8088}
CT="Content-Type: application/json"

command -v curl >/dev/null 2>&1 || { echo "curl is required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 1; }

pass_count=0
fail_count=0
artifacts_dir=${ARTIFACTS_DIR:-/tmp/e2e-api}
mkdir -p "$artifacts_dir"

say() { printf "\n== %s ==\n" "$*"; }
ok()  { echo "[PASS] $*"; pass_count=$((pass_count+1)); }
ko()  { echo "[FAIL] $*"; fail_count=$((fail_count+1)); }

# call METHOD URL [JSON_BODY]
call() {
  local method="$1" url="$2" body="${3:-}"
  local resp_file
  # On macOS/BSD mktemp requires template to end with XXXXXX
  resp_file=$(mktemp "$artifacts_dir/resp.XXXXXX")
  if [[ -n "$body" ]]; then
    http_code=$(curl -sS -o "$resp_file" -w "%{http_code}" -H "$CT" -X "$method" --data "$body" "$url") || http_code=000
  else
    http_code=$(curl -sS -o "$resp_file" -w "%{http_code}" -X "$method" "$url") || http_code=000
  fi
  echo "# $method $url" > "${resp_file}.meta"
  echo "$body" >> "${resp_file}.meta" || true
  printf "%s" "$resp_file"
  echo " $http_code"
}

expect_success() {
  local resp_file="$1" http_code="$2" label="$3"
  if [[ "$http_code" != "200" && "$http_code" != "201" ]]; then
    ko "$label (http $http_code)"; jq . "$resp_file" || cat "$resp_file"; return 1
  fi
  # Most endpoints return { success: true }
  local succ
  succ=$(jq -r 'if has("success") then .success else true end' "$resp_file" 2>/dev/null || echo false)
  if [[ "$succ" != "true" ]]; then
    ko "$label (success=false)"; jq . "$resp_file" || cat "$resp_file"; return 1
  fi
  ok "$label"; return 0
}

extract() { jq -r "$1" "$2"; }

# 1) Users
EMAIL="e2e.$(date +%s)@example.com"
say "Create User"
U_BODY=$(jq -n --arg fn "E2E" --arg ln "User" --arg em "$EMAIL" --arg pw "Password123" --arg cpw "Password123" --arg ph "+15550001111" '{firstName:$fn,lastName:$ln,email:$em,password:$pw,confirmPassword:$cpw,phoneNumber:$ph}')
read -r U_FILE U_CODE < <(call POST "$BASE/api/users/register" "$U_BODY")
expect_success "$U_FILE" "$U_CODE" "Create User" || true
USER_ID=$(extract .data.id "$U_FILE")

say "Get User By ID"
read -r _FILE _CODE < <(call GET "$BASE/api/users/$USER_ID")
expect_success "$_FILE" "$_CODE" "Get User By ID" || true

say "List Users"
read -r _FILE _CODE < <(call GET "$BASE/api/users")
expect_success "$_FILE" "$_CODE" "List Users" || true

say "Update User"
U_UP=$(jq -n --arg fn "E2EUpdated" --arg ln "User" --arg em "$EMAIL" --arg pw "Password123" --arg cpw "Password123" --arg ph "+15550002222" '{firstName:$fn,lastName:$ln,email:$em,password:$pw,confirmPassword:$cpw,phoneNumber:$ph}')
read -r _FILE _CODE < <(call PUT "$BASE/api/users/$USER_ID" "$U_UP")
expect_success "$_FILE" "$_CODE" "Update User" || true

# 2) Categories
say "Create Category"
C_BODY=$(jq -n '{name:"E2E Accessories",description:"E2E category"}')
read -r C_FILE C_CODE < <(call POST "$BASE/api/categories" "$C_BODY")
expect_success "$C_FILE" "$C_CODE" "Create Category" || true
CAT_ID=$(extract .data.id "$C_FILE")

say "Get Category By ID"
read -r _FILE _CODE < <(call GET "$BASE/api/categories/$CAT_ID")
expect_success "$_FILE" "$_CODE" "Get Category By ID" || true

say "List Categories"
read -r _FILE _CODE < <(call GET "$BASE/api/categories")
expect_success "$_FILE" "$_CODE" "List Categories" || true

# 3) Products
say "Create Product"
P_BODY=$(jq -n --arg n "E2E Mouse" --arg d "Wireless mouse" --arg img "https://example.com/mouse.png" --argjson price 49.99 --argjson stock 100 --argjson cat "$CAT_ID" '{name:$n,description:$d,price:$price,stockQuantity:$stock,imageUrl:$img,categoryId:($cat|tonumber)}')
read -r P_FILE P_CODE < <(call POST "$BASE/api/products" "$P_BODY")
expect_success "$P_FILE" "$P_CODE" "Create Product" || true
PROD_ID=$(extract .data.id "$P_FILE")

say "Get Product By ID"
read -r _FILE _CODE < <(call GET "$BASE/api/products/$PROD_ID")
expect_success "$_FILE" "$_CODE" "Get Product By ID" || true

say "List Products"
read -r _FILE _CODE < <(call GET "$BASE/api/products?page=0&size=5&sortBy=id&sortDir=asc")
expect_success "$_FILE" "$_CODE" "List Products" || true

say "Check Availability"
read -r _FILE _CODE < <(call GET "$BASE/api/products/$PROD_ID/availability?quantity=2")
expect_success "$_FILE" "$_CODE" "Check Availability" || true

say "Update Stock"
read -r _FILE _CODE < <(call PATCH "$BASE/api/products/$PROD_ID/stock?stock=150")
expect_success "$_FILE" "$_CODE" "Update Stock" || true

say "Update Product"
P_UP=$(jq -n --arg n "E2E Mouse Pro" --arg d "Ergonomic wireless mouse" --arg img "https://example.com/mouse-pro.png" --argjson price 59.99 --argjson stock 120 --argjson cat "$CAT_ID" '{name:$n,description:$d,price:$price,stockQuantity:$stock,imageUrl:$img,categoryId:($cat|tonumber)}')
read -r _FILE _CODE < <(call PUT "$BASE/api/products/$PROD_ID" "$P_UP")
expect_success "$_FILE" "$_CODE" "Update Product" || true

# 4) Orders
say "Create Order"
O_BODY=$(jq -n --argjson uid "$USER_ID" --argjson pid "$PROD_ID" '{userId:$uid,orderItems:[{productId:$pid,quantity:2}],shippingAddress:"742 Evergreen Terrace",billingAddress:"742 Evergreen Terrace"}')
read -r O_FILE O_CODE < <(call POST "$BASE/api/orders" "$O_BODY")
expect_success "$O_FILE" "$O_CODE" "Create Order" || true
ORDER_ID=$(extract .data.id "$O_FILE")

say "Get Order By ID"
read -r _FILE _CODE < <(call GET "$BASE/api/orders/$ORDER_ID")
expect_success "$_FILE" "$_CODE" "Get Order By ID" || true

say "List Orders"
read -r _FILE _CODE < <(call GET "$BASE/api/orders")
expect_success "$_FILE" "$_CODE" "List Orders" || true

say "List Orders By User"
read -r _FILE _CODE < <(call GET "$BASE/api/orders/user/$USER_ID?page=0&size=5&sortBy=createdAt&sortDir=desc")
expect_success "$_FILE" "$_CODE" "List Orders By User" || true

say "Update Order Status"
read -r _FILE _CODE < <(call PATCH "$BASE/api/orders/$ORDER_ID/status?status=CONFIRMED")
expect_success "$_FILE" "$_CODE" "Update Order Status" || true

say "Cancel Order"
read -r _FILE _CODE < <(call PATCH "$BASE/api/orders/$ORDER_ID/cancel")
expect_success "$_FILE" "$_CODE" "Cancel Order" || true

# 5) Cleanup
say "Delete Product"
read -r _FILE _CODE < <(call DELETE "$BASE/api/products/$PROD_ID")
expect_success "$_FILE" "$_CODE" "Delete Product" || true

say "Delete User"
read -r _FILE _CODE < <(call DELETE "$BASE/api/users/$USER_ID")
expect_success "$_FILE" "$_CODE" "Delete User" || true

echo
echo "Summary: PASS=$pass_count FAIL=$fail_count"
[[ "$fail_count" -eq 0 ]]
