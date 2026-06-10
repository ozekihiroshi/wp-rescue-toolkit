#!/usr/bin/env bash
set -u

# WordPress Restore Readiness Check
# This script checks whether a WordPress site appears ready for restore planning.
# It is read-only and does not modify files, databases, plugins, themes, or WordPress settings.

TARGET_DIR="${1:-.}"

echo "============================================================"
echo " WordPress Restore Readiness Check"
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
echo "1. WordPress root and core material"
echo "------------------------------------------------------------"

HAS_WP_CONFIG=0
HAS_WP_CONTENT=0
HAS_UPLOADS=0
HAS_PLUGINS=0
HAS_THEMES=0
HAS_CORE=0

if [ -f "wp-config.php" ]; then
  HAS_WP_CONFIG=1
  print_status "OK" "wp-config.php found"
else
  print_status "MISS" "wp-config.php not found"
fi

if [ -d "wp-content" ]; then
  HAS_WP_CONTENT=1
  print_status "OK" "wp-content directory found"
else
  print_status "MISS" "wp-content directory not found"
fi

if [ -d "wp-content/uploads" ]; then
  HAS_UPLOADS=1
  print_status "OK" "uploads found - size: $(get_size "wp-content/uploads")"
else
  print_status "MISS" "uploads directory not found"
fi

if [ -d "wp-content/plugins" ]; then
  HAS_PLUGINS=1
  print_status "OK" "plugins found - count: $(count_items "wp-content/plugins"), size: $(get_size "wp-content/plugins")"
else
  print_status "MISS" "plugins directory not found"
fi

if [ -d "wp-content/themes" ]; then
  HAS_THEMES=1
  print_status "OK" "themes found - count: $(count_items "wp-content/themes"), size: $(get_size "wp-content/themes")"
else
  print_status "MISS" "themes directory not found"
fi

if [ -f "wp-load.php" ] || [ -f "wp-settings.php" ]; then
  HAS_CORE=1
  print_status "OK" "WordPress core files found"
else
  print_status "WARN" "WordPress core files were not clearly detected"
fi

echo
echo "------------------------------------------------------------"
echo "2. Database backup candidates"
echo "------------------------------------------------------------"

SQL_FILES="$(find . \
  -path "./wp-content/cache" -prune -o \
  -path "./wp-content/uploads/cache" -prune -o \
  -type f \( \
    -name "*.sql" -o \
    -name "*.sql.gz" -o \
    -name "*.sql.zip" -o \
    -name "*.dump" \
  \) -print 2>/dev/null | head -n 20)"

HAS_DB_DUMP=0

if [ -n "$SQL_FILES" ]; then
  HAS_DB_DUMP=1
  print_status "OK" "Database dump candidate(s) found:"
  echo "$SQL_FILES" | while read -r file; do
    echo "       - $file ($(get_size "$file"))"
  done
else
  print_status "WARN" "No database dump candidate found under target"
fi

echo
echo "------------------------------------------------------------"
echo "3. Backup archive candidates"
echo "------------------------------------------------------------"

ARCHIVE_FILES="$(find . \
  -path "./wp-content/cache" -prune -o \
  -path "./wp-content/uploads/cache" -prune -o \
  -type f \( \
    -name "*.zip" -o \
    -name "*.tar" -o \
    -name "*.tar.gz" -o \
    -name "*.tgz" \
  \) -print 2>/dev/null | head -n 20)"

HAS_ARCHIVE=0

if [ -n "$ARCHIVE_FILES" ]; then
  HAS_ARCHIVE=1
  print_status "OK" "Backup/archive candidate(s) found:"
  echo "$ARCHIVE_FILES" | while read -r file; do
    echo "       - $file ($(get_size "$file"))"
  done
else
  print_status "INFO" "No .zip / .tar / .tar.gz / .tgz archive candidates found under target"
fi

echo
echo "------------------------------------------------------------"
echo "4. Backup plugin directory candidates"
echo "------------------------------------------------------------"

BACKUP_DIR_CANDIDATES=(
  "wp-content/updraft"
  "wp-content/ai1wm-backups"
  "wp-content/wpvividbackups"
  "wp-content/backupwordpress"
  "wp-content/backups"
  "wp-content/backup"
  "wp-content/uploads/backups"
  "wp-content/uploads/backup"
  "backups"
  "backup"
)

HAS_BACKUP_DIR=0

for dir in "${BACKUP_DIR_CANDIDATES[@]}"; do
  if [ -d "$dir" ]; then
    HAS_BACKUP_DIR=1
    print_status "OK" "Backup directory candidate found: $dir - size: $(get_size "$dir")"
  fi
done

if [ "$HAS_BACKUP_DIR" -eq 0 ]; then
  print_status "INFO" "No common backup plugin directory candidates found"
fi

echo
echo "------------------------------------------------------------"
echo "5. Environment clues"
echo "------------------------------------------------------------"

if command_exists php; then
  print_status "INFO" "PHP: $(php -v 2>/dev/null | head -n 1)"
else
  print_status "WARN" "php command not found"
fi

if command_exists mysql; then
  print_status "INFO" "MySQL/MariaDB client: $(mysql --version 2>/dev/null)"
else
  print_status "INFO" "mysql client command not found"
fi

if command_exists wp; then
  print_status "OK" "WP-CLI found"

  if [ -f "wp-config.php" ] && wp core version >/dev/null 2>&1; then
    print_status "INFO" "WordPress version: $(wp core version 2>/dev/null)"
  else
    print_status "INFO" "WP-CLI found, but WordPress version could not be read from this path"
  fi
else
  print_status "INFO" "WP-CLI not found"
fi

echo
print_status "INFO" "Current filesystem usage:"
df -h . 2>/dev/null | sed 's/^/       /'

echo
echo "------------------------------------------------------------"
echo "6. wp-config.php restore details"
echo "------------------------------------------------------------"

if [ -f "wp-config.php" ]; then
  for key in "DB_NAME" "DB_USER" "DB_PASSWORD" "DB_HOST" "table_prefix"; do
    if grep -q "$key" wp-config.php; then
      print_status "OK" "$key appears in wp-config.php"
    else
      print_status "WARN" "$key not found in wp-config.php"
    fi
  done
else
  print_status "WARN" "wp-config.php is missing; database connection details may need to be recovered separately"
fi

echo
echo "------------------------------------------------------------"
echo "7. Dynamic-site risk indicators"
echo "------------------------------------------------------------"

DYNAMIC_PLUGIN_CANDIDATES=(
  "wp-content/plugins/woocommerce"
  "wp-content/plugins/easy-digital-downloads"
  "wp-content/plugins/memberpress"
  "wp-content/plugins/paid-memberships-pro"
  "wp-content/plugins/learnpress"
  "wp-content/plugins/lifterlms"
  "wp-content/plugins/tutor"
  "wp-content/plugins/booking"
  "wp-content/plugins/bookly-responsive-appointment-booking-tool"
  "wp-content/plugins/contact-form-7"
  "wp-content/plugins/gravityforms"
  "wp-content/plugins/wpforms"
)

FOUND_DYNAMIC_PLUGIN=0

for dir in "${DYNAMIC_PLUGIN_CANDIDATES[@]}"; do
  if [ -d "$dir" ]; then
    FOUND_DYNAMIC_PLUGIN=1
    print_status "WARN" "Dynamic/data-sensitive plugin candidate found: $dir"
  fi
done

if [ "$FOUND_DYNAMIC_PLUGIN" -eq 0 ]; then
  print_status "INFO" "No common dynamic-site plugin candidates detected by directory name"
else
  print_status "HIGH" "Database restore timing must be reviewed carefully for orders, users, bookings, forms, or payments"
fi

echo
echo "------------------------------------------------------------"
echo "8. Restore readiness summary"
echo "------------------------------------------------------------"

SCORE=0

[ "$HAS_WP_CONFIG" -eq 1 ] && SCORE=$((SCORE + 1))
[ "$HAS_WP_CONTENT" -eq 1 ] && SCORE=$((SCORE + 1))
[ "$HAS_UPLOADS" -eq 1 ] && SCORE=$((SCORE + 1))
[ "$HAS_PLUGINS" -eq 1 ] && SCORE=$((SCORE + 1))
[ "$HAS_THEMES" -eq 1 ] && SCORE=$((SCORE + 1))
[ "$HAS_DB_DUMP" -eq 1 ] && SCORE=$((SCORE + 2))
[ "$HAS_ARCHIVE" -eq 1 ] && SCORE=$((SCORE + 1))
[ "$HAS_BACKUP_DIR" -eq 1 ] && SCORE=$((SCORE + 1))

print_status "INFO" "Restore readiness score: $SCORE / 9"

if [ "$SCORE" -ge 7 ]; then
  print_status "OK" "Restore materials look relatively complete for planning purposes"
elif [ "$SCORE" -ge 4 ]; then
  print_status "WARN" "Restore materials look partial; review missing items before proceeding"
else
  print_status "HIGH" "Restore readiness appears weak; avoid destructive changes until backup sources are confirmed"
fi

if [ "$HAS_DB_DUMP" -eq 0 ]; then
  print_status "HIGH" "No database dump candidate was detected. WordPress content/settings/users may not be restorable from files alone."
fi

if [ "$HAS_UPLOADS" -eq 0 ]; then
  print_status "WARN" "Uploads directory missing. Media files may be incomplete after restore."
fi

if [ "$HAS_WP_CONFIG" -eq 0 ]; then
  print_status "WARN" "wp-config.php missing. Database credentials and table prefix may need manual recovery."
fi

echo
echo "------------------------------------------------------------"
echo "9. Recommended next steps"
echo "------------------------------------------------------------"

echo "       - Confirm backup date and time"
echo "       - Confirm whether database and file backups match"
echo "       - Confirm target PHP and MySQL/MariaDB versions"
echo "       - Confirm whether the site is dynamic or transaction-sensitive"
echo "       - Create a fresh backup of the current state before overwriting anything"
echo "       - Test restore on staging whenever possible"
echo "       - Plan domain/search-replace work if migrating"
echo "       - Do not restore an old database over a live dynamic site without impact review"

echo
echo "------------------------------------------------------------"
echo "10. Safety notes"
echo "------------------------------------------------------------"

print_status "WARN" "This script does not perform a restore."
print_status "WARN" "This script does not prove that any backup is valid."
print_status "WARN" "A real restore should be tested on staging before production whenever possible."
print_status "WARN" "For WooCommerce, membership, booking, LMS, or payment sites, database restore timing is critical."

echo
echo "============================================================"
echo " Restore readiness check completed"
echo "============================================================"
