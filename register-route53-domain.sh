#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-1"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing command: $1"
    exit 1
  }
}

ask_required() {
  local label="$1"
  local value=""
  while [[ -z "$value" ]]; do
    read -r -p "$label: " value
  done
  printf '%s' "$value"
}

ask_default() {
  local label="$1"
  local default="$2"
  local value=""
  read -r -p "$label [$default]: " value
  printf '%s' "${value:-$default}"
}

ask_yes_no_default() {
  local label="$1"
  local default="$2"
  local value=""
  read -r -p "$label [$default]: " value
  value="${value:-$default}"

  case "$value" in
    y|Y|yes|YES|Yes|true|TRUE) printf 'true' ;;
    *) printf 'false' ;;
  esac
}

need_cmd aws
need_cmd python3

echo "=== AWS Route 53 Domain Register ==="
echo "region: $REGION"
echo

PROFILE="$(ask_required 'AWS profile')"
DOMAIN="$(ask_required 'domain name 例: example.jp')"

# ざっくり推定。co.jp みたいなやつは必要なら手入力で上書き。
DEFAULT_TLD="${DOMAIN##*.}"
TLD="$(ask_default 'TLD for price check 例: jp / com' "$DEFAULT_TLD")"

YEARS="$(ask_default 'duration years' '1')"
AUTO_RENEW="$(ask_yes_no_default 'auto renew? y/n' 'y')"

echo
echo "=== AWS account check ==="
aws sts get-caller-identity \
  --profile "$PROFILE" \
  --output table

echo
echo "=== domain availability check ==="
AVAILABILITY="$(
  aws route53domains check-domain-availability \
    --region "$REGION" \
    --profile "$PROFILE" \
    --domain-name "$DOMAIN" \
    --query 'Availability' \
    --output text
)"

echo "availability: $AVAILABILITY"

if [[ "$AVAILABILITY" != "AVAILABLE" ]]; then
  echo "not available. stop."
  exit 1
fi

echo
echo "=== price check ==="
aws route53domains list-prices \
  --region "$REGION" \
  --profile "$PROFILE" \
  --tld "$TLD" \
  --query 'Prices[0].{
    TLD:Name,
    Registration:RegistrationPrice,
    Renewal:RenewalPrice,
    Transfer:TransferPrice,
    Restoration:RestorationPrice
  }' \
  --output table

echo
echo "=== contact info ==="
CONTACT_TYPE="$(ask_default 'contact type PERSON or COMPANY' 'PERSON')"

FIRST_NAME="$(ask_required 'first name')"
LAST_NAME="$(ask_required 'last name')"

ORG_NAME=""
if [[ "$CONTACT_TYPE" == "COMPANY" ]]; then
  ORG_NAME="$(ask_required 'organization name')"
fi

ADDRESS1="$(ask_required 'address line 1')"
CITY="$(ask_default 'city' 'Tokyo')"
STATE="$(ask_default 'state / prefecture (ISO 3166-2:JP code, e.g., JP-13)' 'JP-13')"
COUNTRY_CODE="$(ask_default 'country code' 'JP')"
ZIP_CODE="$(ask_required 'zip code')"

PHONE_NUMBER="$(ask_required 'phone number (例: +81.9012345678)')"
EMAIL="$(ask_required 'email')"

PRIVACY_PROTECT="$(ask_yes_no_default 'privacy protect? y/n' 'y')"

JSON_FILE="./register-domain-${DOMAIN}.json"

export DOMAIN
export YEARS
export AUTO_RENEW
export CONTACT_TYPE
export FIRST_NAME
export LAST_NAME
export ORG_NAME
export ADDRESS1
export CITY
export STATE
export COUNTRY_CODE
export ZIP_CODE
export PHONE_NUMBER
export EMAIL
export PRIVACY_PROTECT

python3 > "$JSON_FILE" <<'PY'
import json
import os

contact = {
    "FirstName": os.environ["FIRST_NAME"],
    "LastName": os.environ["LAST_NAME"],
    "ContactType": os.environ["CONTACT_TYPE"],
    "AddressLine1": os.environ["ADDRESS1"],
    "City": os.environ["CITY"],
    "State": os.environ["STATE"],
    "CountryCode": os.environ["COUNTRY_CODE"],
    "ZipCode": os.environ["ZIP_CODE"],
    "PhoneNumber": os.environ["PHONE_NUMBER"],
    "Email": os.environ["EMAIL"],
}

if os.environ.get("ORG_NAME"):
    contact["OrganizationName"] = os.environ["ORG_NAME"]

payload = {
    "DomainName": os.environ["DOMAIN"],
    "DurationInYears": int(os.environ["YEARS"]),
    "AutoRenew": os.environ["AUTO_RENEW"] == "true",
    "AdminContact": contact,
    "RegistrantContact": contact,
    "TechContact": contact,
    "PrivacyProtectAdminContact": os.environ["PRIVACY_PROTECT"] == "true",
    "PrivacyProtectRegistrantContact": os.environ["PRIVACY_PROTECT"] == "true",
    "PrivacyProtectTechContact": os.environ["PRIVACY_PROTECT"] == "true",
}

print(json.dumps(payload, ensure_ascii=False, indent=2))
PY

echo
echo "=== generated json ==="
cat "$JSON_FILE"

echo
echo -e "\033[31mこれは課金コマンド。登録すると料金が発生する。\033[0m"

while true; do
  read -r -p "register domain '$DOMAIN'? [yes/no]: " CONFIRM
  case "$CONFIRM" in
    yes|YES|Yes)
      break
      ;;
    no|NO|No)
      echo "cancelled."
      exit 0
      ;;
    *)
      echo "Invalid input. Please type 'yes' or 'no'."
      ;;
  esac
done

echo
echo "=== register domain ==="
aws route53domains register-domain \
  --region "$REGION" \
  --profile "$PROFILE" \
  --cli-input-json "file://${JSON_FILE}"

echo
echo "done. OperationId が出ていたら、これで確認:"
echo "aws route53domains get-operation-detail --region $REGION --profile $PROFILE --operation-id <OperationId>"
