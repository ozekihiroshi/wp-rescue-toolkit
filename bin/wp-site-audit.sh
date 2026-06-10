#!/usr/bin/env bash
set -u

TIMEOUT=15
INSECURE=0
TARGET_INPUT=""

OK_COUNT=0
WARN_COUNT=0
INFO_COUNT=0
FAIL_COUNT=0

print_usage() {
  cat <<'USAGE'
Usage:
  wp-site-audit.sh [options] <domain-or-url>

Options:
  --timeout N     HTTP timeout in seconds. Default: 15
  --insecure      Allow insecure TLS connections for testing
  -h, --help      Show this help

Examples:
  ./bin/wp-site-audit.sh example.com
  ./bin/wp-site-audit.sh https://example.com
  ./bin/wp-site-audit.sh --timeout 30 https://example.com

Purpose:
  Basic external WordPress site audit.
  This script checks HTTP/HTTPS behavior, response time, security headers,
  common WordPress endpoints, and basic HTML metadata.

Safety:
  This script is non-destructive.
  It does not log in, modify files, change WordPress settings, or scan private files.
USAGE
}

ok() {
  OK_COUNT=$((OK_COUNT + 1))
  printf '[OK] %s\n' "$1"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  printf '[WARN] %s\n' "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '[FAIL] %s\n' "$1"
}

info() {
  INFO_COUNT=$((INFO_COUNT + 1))
  printf '[INFO] %s\n' "$1"
}

section() {
  printf '\n## %s\n' "$1"
}

need_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1" >&2
    exit 2
  fi
}

normalize_target() {
  local input="$1"

  if printf '%s' "$input" | grep -Eq '^https?://'; then
    TARGET_URL="$input"
  else
    TARGET_URL="https://$input"
  fi

  TARGET_URL="${TARGET_URL%/}"
  TARGET_HOST="$(printf '%s' "$TARGET_URL" | sed -E 's#^https?://([^/:]+).*#\1#')"

  HTTP_URL="http://$TARGET_HOST"
  HTTPS_URL="https://$TARGET_HOST"
}

curl_base_args() {
  local args=(-sS --max-time "$TIMEOUT" -A "wp-rescue-toolkit/0.1")
  if [ "$INSECURE" -eq 1 ]; then
    args+=(-k)
  fi
  printf '%s\n' "${args[@]}"
}

curl_head_status() {
  local url="$1"
  local args
  mapfile -t args < <(curl_base_args)

  curl "${args[@]}" -o /dev/null -I \
    -w '%{http_code} %{time_total} %{url_effective} %{num_redirects}\n' \
    "$url" 2>/dev/null || true
}

curl_get_capture() {
  local url="$1"
  local header_file="$2"
  local body_file="$3"
  local meta_file="$4"
  local args
  mapfile -t args < <(curl_base_args)

  curl "${args[@]}" \
    -D "$header_file" \
    -o "$body_file" \
    -w '%{http_code} %{time_total} %{size_download} %{url_effective} %{num_redirects}\n' \
    "$url" > "$meta_file" 2>/dev/null || true
}

get_header() {
  local header_name="$1"
  local header_file="$2"

  grep -i "^${header_name}:" "$header_file" 2>/dev/null | tail -n 1 | sed -E "s/^${header_name}:[[:space:]]*//I"
}

has_header() {
  local header_name="$1"
  local header_file="$2"

  grep -qi "^${header_name}:" "$header_file" 2>/dev/null
}

html_has_pattern() {
  local pattern="$1"
  local body_file="$2"

  grep -Eiq "$pattern" "$body_file" 2>/dev/null
}

check_endpoint() {
  local label="$1"
  local path="$2"
  local expected_note="$3"
  local url="${HTTPS_URL}${path}"
  local result status time effective redirects

  result="$(curl_head_status "$url")"
  status="$(printf '%s' "$result" | awk '{print $1}')"
  time="$(printf '%s' "$result" | awk '{print $2}')"
  effective="$(printf '%s' "$result" | awk '{print $3}')"
  redirects="$(printf '%s' "$result" | awk '{print $4}')"

  if [ "$status" = "000" ] || [ "$status" = "" ]; then
    info "$label: no HTTP response from $path"
    return
  fi

  case "$path" in
    /xmlrpc.php)
      if [ "$status" = "200" ] || [ "$status" = "405" ]; then
        warn "$label is reachable: HTTP $status (${time}s). Review if XML-RPC is needed."
      elif [ "$status" = "403" ] || [ "$status" = "404" ]; then
        ok "$label is restricted or not found: HTTP $status"
      else
        info "$label returned HTTP $status (${time}s)"
      fi
      ;;
    /wp-login.php)
      if [ "$status" = "200" ]; then
        info "$label is reachable: HTTP $status. This is common, but may need rate limiting."
      elif [ "$status" = "403" ] || [ "$status" = "404" ]; then
        ok "$label is restricted or not found: HTTP $status"
      else
        info "$label returned HTTP $status (${time}s)"
      fi
      ;;
    /readme.html|/wp-admin/install.php)
      if [ "$status" = "200" ]; then
        warn "$label is publicly reachable: HTTP $status. $expected_note"
      elif [ "$status" = "403" ] || [ "$status" = "404" ]; then
        ok "$label is restricted or not found: HTTP $status"
      else
        info "$label returned HTTP $status (${time}s)"
      fi
      ;;
    /wp-json/)
      if [ "$status" = "200" ]; then
        ok "$label is reachable: HTTP $status"
      elif [ "$status" = "401" ] || [ "$status" = "403" ]; then
        info "$label is restricted: HTTP $status"
      else
        info "$label returned HTTP $status (${time}s)"
      fi
      ;;
    *)
      info "$label returned HTTP $status (${time}s, redirects: $redirects, effective: $effective)"
      ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --timeout)
      if [ "${2:-}" = "" ]; then
        echo "ERROR: --timeout requires a number" >&2
        exit 2
      fi
      TIMEOUT="$2"
      shift 2
      ;;
    --insecure)
      INSECURE=1
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    -*)
      echo "ERROR: Unknown option: $1" >&2
      print_usage
      exit 2
      ;;
    *)
      TARGET_INPUT="$1"
      shift
      ;;
  esac
done

if [ "$TARGET_INPUT" = "" ]; then
  echo "ERROR: target domain or URL is required." >&2
  print_usage
  exit 2
fi

need_command curl
need_command grep
need_command sed
need_command awk

normalize_target "$TARGET_INPUT"

TMP_HEADERS="$(mktemp)"
TMP_BODY="$(mktemp)"
TMP_META="$(mktemp)"
trap 'rm -f "$TMP_HEADERS" "$TMP_BODY" "$TMP_META"' EXIT

echo "=== WP Site Audit ==="
echo
echo "Target input: $TARGET_INPUT"
echo "Target host:  $TARGET_HOST"
echo "HTTPS URL:    $HTTPS_URL"
echo "Date:         $(date)"
echo

section "DNS Check"

if command -v getent >/dev/null 2>&1; then
  DNS_RESULT="$(getent hosts "$TARGET_HOST" || true)"
  if [ "$DNS_RESULT" = "" ]; then
    fail "DNS lookup failed for $TARGET_HOST"
  else
    ok "DNS resolves for $TARGET_HOST"
    printf '%s\n' "$DNS_RESULT" | sed 's/^/  /'
  fi
else
  info "getent not available. Skipping DNS check."
fi

section "HTTP to HTTPS Check"

HTTP_RESULT="$(curl_head_status "$HTTP_URL")"
HTTP_STATUS="$(printf '%s' "$HTTP_RESULT" | awk '{print $1}')"
HTTP_TIME="$(printf '%s' "$HTTP_RESULT" | awk '{print $2}')"
HTTP_EFFECTIVE="$(printf '%s' "$HTTP_RESULT" | awk '{print $3}')"
HTTP_REDIRECTS="$(printf '%s' "$HTTP_RESULT" | awk '{print $4}')"

if [ "$HTTP_STATUS" = "000" ] || [ "$HTTP_STATUS" = "" ]; then
  warn "HTTP did not return a response"
else
  info "HTTP status: $HTTP_STATUS (${HTTP_TIME}s)"
  info "HTTP effective URL: $HTTP_EFFECTIVE"

  if [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ] || [ "$HTTP_STATUS" = "307" ] || [ "$HTTP_STATUS" = "308" ]; then
    ok "HTTP returns redirect status: $HTTP_STATUS"
  else
    warn "HTTP does not return a redirect status. Review HTTP to HTTPS behavior."
  fi
fi

section "HTTPS Response Check"

curl_get_capture "$HTTPS_URL" "$TMP_HEADERS" "$TMP_BODY" "$TMP_META"

HTTPS_STATUS="$(awk '{print $1}' "$TMP_META")"
HTTPS_TIME="$(awk '{print $2}' "$TMP_META")"
HTTPS_SIZE="$(awk '{print $3}' "$TMP_META")"
HTTPS_EFFECTIVE="$(awk '{print $4}' "$TMP_META")"
HTTPS_REDIRECTS="$(awk '{print $5}' "$TMP_META")"

if [ "$HTTPS_STATUS" = "000" ] || [ "$HTTPS_STATUS" = "" ]; then
  fail "HTTPS did not return a response"
else
  if [ "$HTTPS_STATUS" -ge 200 ] && [ "$HTTPS_STATUS" -lt 400 ]; then
    ok "HTTPS returned HTTP $HTTPS_STATUS"
  else
    warn "HTTPS returned HTTP $HTTPS_STATUS"
  fi

  info "Response time: ${HTTPS_TIME}s"
  info "Downloaded size: ${HTTPS_SIZE} bytes"
  info "Effective URL: $HTTPS_EFFECTIVE"
  info "Redirect count: $HTTPS_REDIRECTS"

  TIME_MILLI="$(awk -v t="$HTTPS_TIME" 'BEGIN { printf "%d", t * 1000 }')"
  if [ "$TIME_MILLI" -gt 3000 ]; then
    warn "Response time is over 3 seconds"
  elif [ "$TIME_MILLI" -gt 1500 ]; then
    warn "Response time is over 1.5 seconds"
  else
    ok "Response time is within a basic acceptable range"
  fi

  if [ "$HTTPS_SIZE" -gt 1048576 ]; then
    warn "Homepage download size is over 1 MB"
  else
    ok "Homepage download size is under 1 MB"
  fi
fi

section "Security Headers"

if has_header "Strict-Transport-Security" "$TMP_HEADERS"; then
  ok "HSTS header found"
else
  warn "HSTS header not found"
fi

if has_header "X-Frame-Options" "$TMP_HEADERS"; then
  ok "X-Frame-Options header found"
else
  warn "X-Frame-Options header not found"
fi

if has_header "X-Content-Type-Options" "$TMP_HEADERS"; then
  ok "X-Content-Type-Options header found"
else
  warn "X-Content-Type-Options header not found"
fi

if has_header "Referrer-Policy" "$TMP_HEADERS"; then
  ok "Referrer-Policy header found"
else
  warn "Referrer-Policy header not found"
fi

if has_header "Content-Security-Policy" "$TMP_HEADERS"; then
  ok "Content-Security-Policy header found"
else
  info "Content-Security-Policy header not found. This is common, but can be considered for hardening."
fi

CACHE_CONTROL="$(get_header "Cache-Control" "$TMP_HEADERS")"
if [ "$CACHE_CONTROL" = "" ]; then
  warn "Cache-Control header not found"
else
  ok "Cache-Control header found: $CACHE_CONTROL"
fi

CONTENT_ENCODING="$(get_header "Content-Encoding" "$TMP_HEADERS")"
if [ "$CONTENT_ENCODING" = "" ]; then
  info "Content-Encoding header not found. Compression may be disabled or not shown for this response."
else
  ok "Content-Encoding header found: $CONTENT_ENCODING"
fi

SERVER_HEADER="$(get_header "Server" "$TMP_HEADERS")"
if [ "$SERVER_HEADER" = "" ]; then
  ok "Server header is hidden"
else
  info "Server header: $SERVER_HEADER"
fi

X_POWERED_BY="$(get_header "X-Powered-By" "$TMP_HEADERS")"
if [ "$X_POWERED_BY" = "" ]; then
  ok "X-Powered-By header is hidden"
else
  warn "X-Powered-By header is visible: $X_POWERED_BY"
fi

section "WordPress Endpoint Exposure"

check_endpoint "WordPress REST API" "/wp-json/" "REST API availability depends on site requirements."
check_endpoint "WordPress login page" "/wp-login.php" "Consider rate limiting or access control if needed."
check_endpoint "XML-RPC endpoint" "/xmlrpc.php" "Disable or restrict it if not needed."
check_endpoint "WordPress readme.html" "/readme.html" "Consider restricting or removing public readme.html."
check_endpoint "WordPress install.php" "/wp-admin/install.php" "This should not be publicly usable after installation."

section "Basic HTML / UX Metadata"

if html_has_pattern '<title>[^<]+' "$TMP_BODY"; then
  ok "HTML title tag found"
else
  warn "HTML title tag not found"
fi

if html_has_pattern '<meta[^>]+name=["'"'"']description["'"'"']' "$TMP_BODY"; then
  ok "Meta description found"
else
  warn "Meta description not found"
fi

if html_has_pattern '<meta[^>]+name=["'"'"']viewport["'"'"']' "$TMP_BODY"; then
  ok "Viewport meta tag found"
else
  warn "Viewport meta tag not found"
fi

if html_has_pattern '<html[^>]+lang=["'"'"'][^"'"'"']+' "$TMP_BODY"; then
  ok "HTML lang attribute found"
else
  warn "HTML lang attribute not found"
fi

if html_has_pattern 'wp-content|wp-includes|wp-json|wp-emoji' "$TMP_BODY"; then
  ok "WordPress indicators found in HTML"
else
  info "No obvious WordPress indicators found in homepage HTML"
fi

section "Summary"

echo "OK:    $OK_COUNT"
echo "WARN:  $WARN_COUNT"
echo "FAIL:  $FAIL_COUNT"
echo "INFO:  $INFO_COUNT"
echo

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "Result: FAIL"
  echo "One or more important checks failed."
elif [ "$WARN_COUNT" -gt 0 ]; then
  echo "Result: WARN"
  echo "The site is reachable, but some items should be reviewed."
else
  echo "Result: OK"
  echo "No obvious issue was found by this basic external audit."
fi

echo
echo "Important:"
echo "  - This is not a full performance audit."
echo "  - This is not a full security audit."
echo "  - This does not replace Lighthouse, PageSpeed Insights, WAF logs, server logs, or manual review."
echo "  - Use this as a first baseline check before deeper WordPress improvement work."
echo
echo "=== Done ==="
