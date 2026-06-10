#!/usr/bin/env bash
set -u

# WordPress Basic Performance Audit
# This script checks common WordPress performance-related indicators.
# It does not modify files, databases, plugins, themes, or WordPress settings.

TARGET_DIR="${1:-.}"

echo "============================================================"
echo " WordPress Basic Performance Audit"
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
    *)    echo "[$status] $message" ;;
  esac
}

get_size() {
  local path="$1"
  if [ -e "$path" ]; then
    du -sh "$path" 2>/dev/null | awk '{print $1}'
  else
    echo "-"
  fi
}

count_items() {
  local path="$1"
  if [ -d "$path" ]; then
    find "$path" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
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
echo "2. Server and runtime basics"
echo "------------------------------------------------------------"

if command_exists php; then
  PHP_VERSION="$(php -v 2>/dev/null | head -n 1)"
  print_status "INFO" "PHP: $PHP_VERSION"
else
  print_status "WARN" "php command not found"
fi

if command_exists mysql; then
  MYSQL_VERSION="$(mysql --version 2>/dev/null)"
  print_status "INFO" "MySQL/MariaDB client: $MYSQL_VERSION"
else
  print_status "INFO" "mysql client command not found"
fi

if command_exists wp; then
  print_status "OK" "WP-CLI found"
else
  print_status "INFO" "WP-CLI not found; WordPress and DB-specific checks will be limited"
fi

echo
echo "------------------------------------------------------------"
echo "3. Disk and directory size"
echo "------------------------------------------------------------"

print_status "INFO" "Current filesystem usage:"
df -h . 2>/dev/null | sed 's/^/       /'

echo
print_status "INFO" "wp-content size: $(get_size "wp-content")"
print_status "INFO" "uploads size:    $(get_size "wp-content/uploads")"
print_status "INFO" "plugins size:    $(get_size "wp-content/plugins")"
print_status "INFO" "themes size:     $(get_size "wp-content/themes")"

echo
echo "------------------------------------------------------------"
echo "4. Plugin and theme inventory"
echo "------------------------------------------------------------"

PLUGIN_COUNT="$(count_items "wp-content/plugins")"
THEME_COUNT="$(count_items "wp-content/themes")"

print_status "INFO" "plugins count: $PLUGIN_COUNT"
print_status "INFO" "themes count:  $THEME_COUNT"

if [ "$PLUGIN_COUNT" -gt 30 ]; then
  print_status "WARN" "Plugin count is relatively high; review unused or overlapping plugins"
elif [ "$PLUGIN_COUNT" -gt 0 ]; then
  print_status "OK" "Plugin count is within a moderate range"
else
  print_status "INFO" "No plugins detected or plugins directory missing"
fi

echo
echo "------------------------------------------------------------"
echo "5. Cache-related indicators"
echo "------------------------------------------------------------"

if [ -f "wp-content/object-cache.php" ]; then
  print_status "OK" "object-cache.php found; persistent object cache may be enabled"
else
  print_status "INFO" "object-cache.php not found"
fi

if [ -f "wp-content/advanced-cache.php" ]; then
  print_status "OK" "advanced-cache.php found; page cache drop-in may be enabled"
else
  print_status "INFO" "advanced-cache.php not found"
fi

CACHE_PLUGIN_CANDIDATES=(
  "wp-content/plugins/wp-super-cache"
  "wp-content/plugins/w3-total-cache"
  "wp-content/plugins/wp-rocket"
  "wp-content/plugins/litespeed-cache"
  "wp-content/plugins/autoptimize"
  "wp-content/plugins/redis-cache"
  "wp-content/plugins/sg-cachepress"
  "wp-content/plugins/breeze"
  "wp-content/plugins/wp-fastest-cache"
)

FOUND_CACHE_PLUGIN=0

for dir in "${CACHE_PLUGIN_CANDIDATES[@]}"; do
  if [ -d "$dir" ]; then
    FOUND_CACHE_PLUGIN=1
    print_status "OK" "Cache/performance plugin candidate found: $dir"
  fi
done

if [ "$FOUND_CACHE_PLUGIN" -eq 0 ]; then
  print_status "INFO" "No common cache/performance plugin candidates found"
fi

echo
echo "------------------------------------------------------------"
echo "6. Debug and log indicators"
echo "------------------------------------------------------------"

DEBUG_LOG="wp-content/debug.log"

if [ -f "$DEBUG_LOG" ]; then
  print_status "WARN" "debug.log found - size: $(get_size "$DEBUG_LOG")"
  print_status "INFO" "Large debug logs may indicate repeated PHP warnings/notices or hidden errors"
else
  print_status "OK" "debug.log not found"
fi

if [ -f "wp-config.php" ]; then
  if grep -q "WP_DEBUG.*true" wp-config.php; then
    print_status "WARN" "WP_DEBUG appears to be enabled in wp-config.php"
  else
    print_status "INFO" "WP_DEBUG does not appear to be explicitly enabled"
  fi

  if grep -q "WP_CACHE.*true" wp-config.php; then
    print_status "OK" "WP_CACHE appears to be enabled in wp-config.php"
  else
    print_status "INFO" "WP_CACHE does not appear to be explicitly enabled"
  fi
else
  print_status "INFO" "Skipping wp-config.php debug/cache checks because wp-config.php is missing"
fi

echo
echo "------------------------------------------------------------"
echo "7. Uploads directory indicators"
echo "------------------------------------------------------------"

if [ -d "wp-content/uploads" ]; then
  LARGE_FILES=$(find "wp-content/uploads" -type f -size +10M 2>/dev/null | head -n 10)

  if [ -n "$LARGE_FILES" ]; then
    print_status "WARN" "Large files over 10MB found in uploads:"
    echo "$LARGE_FILES" | while read -r file; do
      echo "       - $file ($(get_size "$file"))"
    done
  else
    print_status "OK" "No files over 10MB found in uploads sample check"
  fi
else
  print_status "INFO" "uploads directory not found; skipping large file check"
fi

echo
echo "------------------------------------------------------------"
echo "8. Optional WP-CLI checks"
echo "------------------------------------------------------------"

if command_exists wp && [ -f "wp-config.php" ]; then
  if wp core version >/dev/null 2>&1; then
    WP_VERSION="$(wp core version 2>/dev/null)"
    print_status "INFO" "WordPress version: $WP_VERSION"
  else
    print_status "WARN" "WP-CLI is available but WordPress core version could not be read"
  fi

  if wp plugin list --status=active --field=name >/dev/null 2>&1; then
    ACTIVE_PLUGIN_COUNT="$(wp plugin list --status=active --field=name 2>/dev/null | wc -l | tr -d ' ')"
    print_status "INFO" "Active plugins count via WP-CLI: $ACTIVE_PLUGIN_COUNT"
  else
    print_status "INFO" "Active plugin list could not be read via WP-CLI"
  fi

  if wp db size --human-readable >/dev/null 2>&1; then
    DB_SIZE="$(wp db size --human-readable 2>/dev/null | tail -n 1)"
    print_status "INFO" "Database size via WP-CLI: $DB_SIZE"
  else
    print_status "INFO" "Database size could not be read via WP-CLI"
  fi
else
  print_status "INFO" "Skipping WP-CLI checks"
fi

echo
echo "------------------------------------------------------------"
echo "9. Performance review notes"
echo "------------------------------------------------------------"

print_status "INFO" "Common next checks:"
echo "       - Review slow plugins and unused plugins"
echo "       - Check page cache and object cache configuration"
echo "       - Review image size and uploads growth"
echo "       - Check PHP memory_limit and max_execution_time"
echo "       - Review database size, autoloaded options, and postmeta growth"
echo "       - Check server CPU, memory, disk I/O, and web server logs"
echo "       - Test frontend speed with browser-based tools separately"

echo
echo "------------------------------------------------------------"
echo "10. Safety notes"
echo "------------------------------------------------------------"

print_status "WARN" "This script is a lightweight audit and does not benchmark real page speed."
print_status "WARN" "Do not delete plugins, cache files, logs, or uploads without a verified backup."
print_status "WARN" "For production sites, confirm impact on staging before optimization changes."

echo
echo "============================================================"
echo " Performance audit completed"
echo "============================================================"
