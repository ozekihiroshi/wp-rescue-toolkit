#!/usr/bin/env bash
set -u

# WordPress Backup Readiness Check
# This script checks whether essential WordPress backup/restore materials appear to exist.
# It does not modify files, databases, or WordPress settings.

TARGET_DIR="${1:-.}"

echo "============================================================"
echo " WordPress Backup Readiness Check"
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
echo "2. Essential content directories"
echo "------------------------------------------------------------"

for dir in "wp-content/uploads" "wp-content/plugins" "wp-content/themes"; do
  if [ -d "$dir" ]; then
    print_status "OK" "$dir found - size: $(get_size "$dir")"
  else
    print_status "MISS" "$dir not found"
  fi
done

echo
echo "------------------------------------------------------------"
echo "3. Content inventory"
echo "------------------------------------------------------------"

print_status "INFO" "plugins count: $(count_items "wp-content/plugins")"
print_status "INFO" "themes count:  $(count_items "wp-content/themes")"
print_status "INFO" "uploads size:  $(get_size "wp-content/uploads")"
print_status "INFO" "wp-content size: $(get_size "wp-content")"

echo
echo "------------------------------------------------------------"
echo "4. Backup directory candidates"
echo "------------------------------------------------------------"

BACKUP_DIR_CANDIDATES=(
  "backup"
  "backups"
  "wp-backup"
  "wp-backups"
  "wp-content/backup"
  "wp-content/backups"
  "wp-content/updraft"
  "wp-content/ai1wm-backups"
  "wp-content/backupwordpress"
  "wp-content/wpvividbackups"
  "wp-content/uploads/backup"
  "wp-content/uploads/backups"
)

FOUND_BACKUP_DIR=0

for dir in "${BACKUP_DIR_CANDIDATES[@]}"; do
  if [ -d "$dir" ]; then
    FOUND_BACKUP_DIR=1
    print_status "OK" "Backup directory candidate found: $dir - size: $(get_size "$dir")"
  fi
done

if [ "$FOUND_BACKUP_DIR" -eq 0 ]; then
  print_status "WARN" "No common backup directory candidates found"
fi

echo
echo "------------------------------------------------------------"
echo "5. Database dump candidates"
echo "------------------------------------------------------------"

SQL_FILES=$(find . \
  -path "./wp-content/cache" -prune -o \
  -path "./wp-content/uploads/cache" -prune -o \
  -type f \( \
    -name "*.sql" -o \
    -name "*.sql.gz" -o \
    -name "*.sql.zip" -o \
    -name "*.dump" \
  \) -print 2>/dev/null | head -n 20)

if [ -n "$SQL_FILES" ]; then
  print_status "OK" "Database dump candidate(s) found:"
  echo "$SQL_FILES" | while read -r file; do
    echo "       - $file ($(get_size "$file"))"
  done
else
  print_status "WARN" "No .sql / .sql.gz / .sql.zip / .dump files found under target"
fi

echo
echo "------------------------------------------------------------"
echo "6. wp-config.php database settings presence"
echo "------------------------------------------------------------"

if [ -f "wp-config.php" ]; then
  for key in "DB_NAME" "DB_USER" "DB_PASSWORD" "DB_HOST"; do
    if grep -q "$key" wp-config.php; then
      print_status "OK" "$key appears in wp-config.php"
    else
      print_status "WARN" "$key not found in wp-config.php"
    fi
  done
else
  print_status "WARN" "Skipping wp-config.php checks because wp-config.php is missing"
fi

echo
echo "------------------------------------------------------------"
echo "7. Restore readiness notes"
echo "------------------------------------------------------------"

print_status "INFO" "A reliable restore normally needs:"
echo "       - WordPress files or a clean WordPress core install"
echo "       - wp-content/uploads"
echo "       - wp-content/themes"
echo "       - wp-content/plugins"
echo "       - Database dump"
echo "       - wp-config.php or database connection details"
echo "       - Domain / URL replacement plan when migrating"
echo "       - PHP and MySQL/MariaDB version compatibility check"

echo
echo "------------------------------------------------------------"
echo "8. Safety notes"
echo "------------------------------------------------------------"

print_status "WARN" "This script does not prove that a backup is restorable."
print_status "WARN" "Before changing a live site, create a fresh file and database backup."
print_status "WARN" "Test restore on a staging environment whenever possible."
print_status "WARN" "Do not expose wp-config.php or database dumps in a public web directory."

echo
echo "============================================================"
echo " Backup readiness check completed"
echo "============================================================"
