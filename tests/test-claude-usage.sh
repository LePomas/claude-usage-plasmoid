#!/usr/bin/env bash
# Regression tests for contents/scripts/claude-usage.
# Injects a mock curl via PATH — no real network calls.
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/contents/scripts/claude-usage"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin"

PASS=0; FAIL=0

check() {
  local name="$1" want="$2" got="$3"
  if [[ "$got" == *"$want"* ]]; then
    printf 'PASS: %s\n' "$name"; ((PASS++)) || true
  else
    printf 'FAIL: %s\n  want: *%s*\n  got:  %s\n' "$name" "$want" "$got"; ((FAIL++)) || true
  fi
}

mk_cred() {
  local at="${1:-tok}" rt="${2:-rt}"
  cat > "$T/creds.json" <<JSON
{"claudeAiOauth":{"accessToken":"$at","refreshToken":"$rt","expiresAt":9999999999000}}
JSON
}

# Stateless mock: reads MOCK_USAGE_{BODY,CODE} / MOCK_TOKEN_{BODY,CODE}.
# Finds the URL by scanning all args for one starting with https://.
write_curl_static() {
  cat > "$T/bin/curl" <<'EOF'
#!/usr/bin/env bash
url=""; for a; do [[ "$a" == https://* ]] && url="$a" && break; done
if   [[ "$url" == *"oauth/usage"* ]]; then printf '%s\n%s' "${MOCK_USAGE_BODY:-}" "${MOCK_USAGE_CODE:-200}"
elif [[ "$url" == *"oauth/token"* ]]; then printf '%s\n%s' "${MOCK_TOKEN_BODY:-}" "${MOCK_TOKEN_CODE:-200}"
fi
EOF
  chmod +x "$T/bin/curl"
}

# Stateful: first usage call → 401, second → 200; token call → 200.
write_curl_401_then_ok() {
  rm -f "$T/usage_n"
  cat > "$T/bin/curl" <<CURL
#!/usr/bin/env bash
url=""; for a; do [[ "\$a" == https://* ]] && url="\$a" && break; done
if [[ "\$url" == *"oauth/usage"* ]]; then
  n=\$( [ -f "$T/usage_n" ] && cat "$T/usage_n" || echo 0 )
  echo \$((n+1)) > "$T/usage_n"
  if [ "\$n" -eq 0 ]; then printf '{}\n401'
  else printf '{"limits":[{"kind":"session","percent":5,"severity":"normal","resets_at":"2099-01-01T00:00:00Z"}]}\n200'; fi
elif [[ "\$url" == *"oauth/token"* ]]; then
  printf '{"access_token":"new_tok","expires_in":3600}\n200'
fi
CURL
  chmod +x "$T/bin/curl"
}

run() { CLAUDE_CRED="$T/creds.json" PATH="$T/bin:$PATH" bash "$SCRIPT" 2>/dev/null; }

# 1. Happy path — 200 with limits
write_curl_static; mk_cred
got=$(MOCK_USAGE_CODE=200 MOCK_USAGE_BODY='{"limits":[{"kind":"session","percent":4,"severity":"normal","resets_at":"2099-01-01T00:00:00Z"}]}' run)
check "200 ok returns limits" '"limits"' "$got"

# 2. Missing credentials file
rm -f "$T/creds.json"
check "missing creds gives error" '"error"' "$(run)"

# 3. Missing access token
printf '{"claudeAiOauth":{"refreshToken":"rt","expiresAt":9999}}' > "$T/creds.json"
check "no access token gives error" '"error"' "$(run)"

# 4. 401 → successful token refresh → 200
write_curl_401_then_ok; mk_cred "expired_tok"
check "401 refresh succeeds returns limits" '"limits"' "$(run)"

# 5. 401 + no refresh token → login expired
write_curl_static
printf '{"claudeAiOauth":{"accessToken":"bad","expiresAt":9999}}' > "$T/creds.json"
got=$(MOCK_USAGE_CODE=401 MOCK_USAGE_BODY='{}' run)
check "401 no refresh token gives login expired" "login expired" "$got"

# 6. 401 + refresh returns 400 → login expired
write_curl_static; mk_cred "bad" "bad_rt"
got=$(MOCK_USAGE_CODE=401 MOCK_USAGE_BODY='{}' MOCK_TOKEN_CODE=400 MOCK_TOKEN_BODY='{"error":"invalid_grant"}' run)
check "401 refresh fails gives login expired" "login expired" "$got"

# 7. HTTP 500 → error with code
write_curl_static; mk_cred
got=$(MOCK_USAGE_CODE=500 MOCK_USAGE_BODY='{}' run)
check "500 error mentions http code" "http 500" "$got"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
