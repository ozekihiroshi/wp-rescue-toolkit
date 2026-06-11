#!/usr/bin/env bash
set -u

# WordPress WP-CLI Readiness Check
# This script checks whether the current server/environment appears ready to use WP-CLI.
# It does not install WP-CLI and does not modify files, databases, plugins, themes, or WordPress settings.

TARGET_DIR="${1:-.}"

echo "============================================================"
echo " WordPress WP-CLI Readiness Check"
echo "============================================================"
echo "Target: $TARGET_DIR"
echo "Date:   $(date)"
echo

if [ ! -d "$TARGET_DIR" ]; then
  echo "[ERROR] Target directory does not exist: $TARGET_DIR"
  exit 1
fi

cd "$TARGET_DIR" || exit 1

print_status() {
  local status="$1"
  local message="$2"

  case "$status" in
    OK)   echo "[OK]   $message" ;;
    WARN) echo "[WARN] $message" ;;
    INFO) echo "[INFO] $message" ;;
    MISS) echo "[MISS] $message" ;;
    HIGH) echo "[HIGH] $message" ;;
    *)    echo "[$status] $message" ;;
  esac
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_writable_dir() {
  local dir="$1"
  [ -d "$dir" ] && [ -w "$dir" ]
}

echo "------------------------------------------------------------"
echo "1. WordPress root check"
echo "------------------------------------------------------------"

if [ -f "wp-config.php" ]; then
  print_status "OK" "wp-config.php found"
else
  print_status "MISS" "wp-config.php not found"
fi

if [ -d "wp-content" ]; then
  print_status "OK" "wp-content directory found"
else
  print_status "MISS" "wp-content directory not found"
fi

if [ -f "wp-load.php" ] || [ -f "wp-settings.php" ]; then
  print_status "OK" "WordPress core files found"
else
  print_status "WARN" "WordPress core files were not clearly detected"
fi

echo
echo "------------------------------------------------------------"
echo "2. Existing WP-CLI check"
echo "------------------------------------------------------------"

if command_exists wp; then
  print_status "OK" "wp command found: $(command -v wp)"

  if wp --info >/dev/null 2>&1; then
    print_status "INFO" "WP-CLI info:"
    wp --info 2>/dev/null | sed 's/^/       /'
  else
    print_status "WARN" "wp command exists, but wp --info failed"
  fi

  if [ -f "wp-config.php" ] && wp core version >/dev/null 2>&1; then
    print_status "OK" "WP-CLI can read this WordPress install"
    print_status "INFO" "WordPress version: $(wp core version 2>/dev/null)"
  elif [ -f "wp-config.php" ] && wp core version --allow-root >/dev/null 2>&1; then
    print_status "OK" "WP-CLI can read this WordPress install with --allow-root"
    print_status "INFO" "WordPress version: $(wp core version --allow-root 2>/dev/null)"
  else
    print_status "WARN" "WP-CLI is installed, but it could not read this WordPress install from the current path"
  fi
else
  print_status "MISS" "wp command not found"
fi

echo
echo "------------------------------------------------------------"
echo "3. PHP runtime readiness"
echo "------------------------------------------------------------"

if command_exists php; then
  PHP_VERSION_LINE="$(php -v 2>/dev/null | head -n 1)"
  print_status "OK" "php command found"
  print_status "INFO" "PHP: $PHP_VERSION_LINE"

  PHP_MAJOR="$(php -r 'echo PHP_MAJOR_VERSION;' 2>/dev/null || echo 0)"
  PHP_MINOR="$(php -r 'echo PHP_MINOR_VERSION;' 2>/dev/null || echo 0)"

  if [ "$PHP_MAJOR" -gt 7 ] || { [ "$PHP_MAJOR" -eq 7 ] && [ "$PHP_MINOR" -ge 4 ]; }; then
    print_status "OK" "PHP version is likely suitable for current WP-CLI releases"
  elif [ "$PHP_MAJOR" -eq 7 ] && [ "$PHP_MINOR" -ge 2 ]; then
    print_status "WARN" "PHP is old. A recent WP-CLI may not support this PHP version; use a compatible WP-CLI release or test carefully"
  else
    print_status "HIGH" "PHP is very old for modern WP-CLI usage"
  fi
else
  print_status "HIGH" "php command not found; WP-CLI cannot run without PHP CLI"
fi

echo
echo "------------------------------------------------------------"
echo "4. Download tool readiness"
echo "------------------------------------------------------------"

if command_exists curl; then
  print_status "OK" "curl found: $(command -v curl)"
else
  print_status "WARN" "curl not found"
fi

if command_exists wget; then
  print_status "OK" "wget found: $(command -v wget)"
else
  print_status "WARN" "wget not found"
fi

if ! command_exists curl && ! command_exists wget; then
  print_status "HIGH" "Neither curl nor wget was found; downloading wp-cli.phar may require another method"
fi

echo
echo "------------------------------------------------------------"
echo "5. PHAR and PHP extension clues"
echo "------------------------------------------------------------"

if command_exists php; then
  if php -m 2>/dev/null | grep -qi '^phar$'; then
    print_status "OK" "PHP phar extension appears enabled"
  else
    print_status "WARN" "PHP phar extension was not detected"
  fi

  if php -m 2>/dev/null | grep -qi '^mysqli$'; then
    print_status "OK" "PHP mysqli extension appears enabled"
  else
    print_status "INFO" "PHP mysqli extension was not detected in CLI modules"
  fi

  if php -m 2>/dev/null | grep -qi '^pdo_mysql$'; then
    print_status "OK" "PHP pdo_mysql extension appears enabled"
  else
    print_status "INFO" "PHP pdo_mysql extension was not detected in CLI modules"
  fi

  if php -r 'exit(ini_get("phar.readonly") ? 0 : 1);' 2>/dev/null; then
    print_status "INFO" "phar.readonly is enabled. This usually does not prevent running wp-cli.phar"
  else
    print_status "INFO" "phar.readonly appears disabled"
  fi
fi

echo
echo "------------------------------------------------------------"
echo "6. User and permission readiness"
echo "------------------------------------------------------------"

print_status "INFO" "Current user: $(whoami)"
print_status "INFO" "Current directory: $(pwd)"

if command_exists sudo; then
  print_status "INFO" "sudo command exists"
  if sudo -n true >/dev/null 2>&1; then
    print_status "OK" "Current user appears to have passwordless sudo"
  else
    print_status "INFO" "Passwordless sudo is not available or requires a password"
  fi
else
  print_status "INFO" "sudo command not found"
fi

INSTALL_PATHS=(
  "/usr/local/bin"
  "$HOME/bin"
  "$HOME/.local/bin"
)

for dir in "${INSTALL_PATHS[@]}"; do
  if is_writable_dir "$dir"; then
    print_status "OK" "Writable install candidate: $dir"
  elif [ -d "$dir" ]; then
    print_status "INFO" "Install candidate exists but is not writable by current user: $dir"
  else
    print_status "INFO" "Install candidate does not exist: $dir"
  fi
done

echo
echo "------------------------------------------------------------"
echo "7. Database client readiness"
echo "------------------------------------------------------------"

if command_exists mysql; then
  print_status "OK" "mysql client found"
  print_status "INFO" "$(mysql --version 2>/dev/null)"
else
  print_status "WARN" "mysql client not found"
fi

if [ -f "wp-config.php" ]; then
  for key in "DB_NAME" "DB_USER" "DB_PASSWORD" "DB_HOST" "table_prefix"; do
    if grep -q "$key" wp-config.php; then
      print_status "OK" "$key appears in wp-config.php"
    else
      print_status "WARN" "$key not found in wp-config.php"
    fi
  done
fi

echo
echo "------------------------------------------------------------"
echo "8. Recommended install approaches"
echo "------------------------------------------------------------"

echo "Option A: user-local wp-cli.phar, safer without sudo"
echo
cat <<'CMD'
mkdir -p "$HOME/bin"
curl -L -o "$HOME/bin/wp" https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x "$HOME/bin/wp"
"$HOME/bin/wp" --info
CMD

echo
echo "Option B: system-wide install, requires sudo"
echo
cat <<'CMD'
curl -L -o wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
php wp-cli.phar --info
sudo mv wp-cli.phar /usr/local/bin/wp
sudo chmod +x /usr/local/bin/wp
wp --info
CMD

echo
echo "For older PHP environments, test compatibility before system-wide installation."

echo
echo "------------------------------------------------------------"
echo "9. Readiness summary"
echo "------------------------------------------------------------"

if command_exists wp; then
  print_status "OK" "WP-CLI already exists. Next step: confirm it works inside the target WordPress path"
else
  if command_exists php && { command_exists curl || command_exists wget; }; then
    print_status "OK" "Basic conditions for trying a user-local WP-CLI install appear present"
  else
    print_status "WARN" "Basic conditions for WP-CLI installation are incomplete"
  fi
fi

if command_exists php; then
  if [ "${PHP_MAJOR:-0}" -eq 7 ] && [ "${PHP_MINOR:-0}" -le 2 ]; then
    print_status "WARN" "Because this server uses old PHP, avoid assuming the latest WP-CLI will work without testing"
  fi
fi

echo
echo "------------------------------------------------------------"
echo "10. Safety notes"
echo "------------------------------------------------------------"

print_status "WARN" "This script does not install WP-CLI."
print_status "WARN" "Do not run database-changing WP-CLI commands on production without a verified backup."
print_status "WARN" "Start with read-only commands such as wp --info, wp core version, wp plugin list, and wp db size."
print_status "WARN" "On old servers, prefer a user-local test before a system-wide install."

echo
echo "============================================================"
echo " WP-CLI readiness check completed"
echo "============================================================"
