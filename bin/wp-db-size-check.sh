#!/usr/bin/env bash
set -u

# WordPress Database Size Check
# This script checks WordPress database size indicators using WP-CLI when available.
# It is read-only and does not modify the database, files, plugins, themes, or WordPress settings.

TARGET_DIR="${1:-.}"

echo "============================================================"
echo " WordPress Database Size Check"
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

run_wp() {
  wp "$@" --allow-root 2>/dev/null || wp "$@" 2>/dev/null
}

echo "------------------------------------------------------------"
echo "1. WordPress root and tool availability"
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

if command_exists wp; then
  print_status "OK" "WP-CLI found"
else
  print_status "WARN" "WP-CLI not found"
  echo
  print_status "INFO" "This script needs WP-CLI for database-specific checks."
  print_status "INFO" "Install or run WP-CLI on the server/container, or use the manual SQL examples in the notes below."
  echo
  echo "============================================================"
  echo " Database size check completed with limited results"
  echo "============================================================"
  exit 0
fi

if [ ! -f "wp-config.php" ]; then
  print_status "WARN" "wp-config.php is missing; WP-CLI database checks may not work from this path"
fi

echo
echo "------------------------------------------------------------"
echo "2. WordPress and database basics"
echo "------------------------------------------------------------"

if run_wp core version >/dev/null; then
  print_status "INFO" "WordPress version: $(run_wp core version)"
else
  print_status "WARN" "Could not read WordPress version via WP-CLI"
fi

if run_wp db size --human-readable >/dev/null; then
  print_status "INFO" "Database size:"
  run_wp db size --human-readable | sed 's/^/       /'
else
  print_status "WARN" "Could not read database size via WP-CLI"
fi

if run_wp config get DB_NAME >/dev/null; then
  print_status "INFO" "Database name: $(run_wp config get DB_NAME)"
else
  print_status "INFO" "Could not read DB_NAME via WP-CLI"
fi

if run_wp config get table_prefix >/dev/null; then
  TABLE_PREFIX="$(run_wp config get table_prefix)"
  print_status "INFO" "Table prefix: $TABLE_PREFIX"
else
  TABLE_PREFIX="wp_"
  print_status "WARN" "Could not read table_prefix via WP-CLI; using wp_ in example queries only"
fi

echo
echo "------------------------------------------------------------"
echo "3. Table size overview"
echo "------------------------------------------------------------"

TABLE_STATUS_QUERY="
SELECT
  table_name AS table_name,
  ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb,
  table_rows AS approx_rows
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY (data_length + index_length) DESC
LIMIT 20;
"

if run_wp db query "$TABLE_STATUS_QUERY" >/dev/null; then
  run_wp db query "$TABLE_STATUS_QUERY" | sed 's/^/       /'
else
  print_status "WARN" "Could not query table size overview"
fi

echo
echo "------------------------------------------------------------"
echo "4. Common large WordPress tables"
echo "------------------------------------------------------------"

COMMON_TABLES=(
  "posts"
  "postmeta"
  "options"
  "users"
  "usermeta"
  "comments"
  "commentmeta"
  "terms"
  "termmeta"
  "term_relationships"
  "term_taxonomy"
)

for suffix in "${COMMON_TABLES[@]}"; do
  table="${TABLE_PREFIX}${suffix}"
  COUNT_QUERY="SELECT COUNT(*) AS count FROM ${table};"

  if run_wp db query "$COUNT_QUERY" >/dev/null; then
    count="$(run_wp db query "$COUNT_QUERY" --skip-column-names 2>/dev/null | tail -n 1)"
    print_status "INFO" "${table}: ${count} rows"
  else
    print_status "INFO" "${table}: not found or not readable"
  fi
done

echo
echo "------------------------------------------------------------"
echo "5. Autoloaded options review"
echo "------------------------------------------------------------"

OPTIONS_TABLE="${TABLE_PREFIX}options"

AUTOLOAD_COUNT_QUERY="
SELECT COUNT(*) AS autoload_count
FROM ${OPTIONS_TABLE}
WHERE autoload = 'yes';
"

AUTOLOAD_SIZE_QUERY="
SELECT
  ROUND(SUM(LENGTH(option_value)) / 1024 / 1024, 2) AS autoload_mb
FROM ${OPTIONS_TABLE}
WHERE autoload = 'yes';
"

LARGEST_AUTOLOAD_QUERY="
SELECT
  option_name,
  ROUND(LENGTH(option_value) / 1024, 2) AS size_kb
FROM ${OPTIONS_TABLE}
WHERE autoload = 'yes'
ORDER BY LENGTH(option_value) DESC
LIMIT 20;
"

if run_wp db query "$AUTOLOAD_COUNT_QUERY" >/dev/null; then
  print_status "INFO" "Autoloaded options count:"
  run_wp db query "$AUTOLOAD_COUNT_QUERY" | sed 's/^/       /'
else
  print_status "INFO" "Autoloaded options count could not be checked"
fi

if run_wp db query "$AUTOLOAD_SIZE_QUERY" >/dev/null; then
  print_status "INFO" "Autoloaded options total size:"
  run_wp db query "$AUTOLOAD_SIZE_QUERY" | sed 's/^/       /'
else
  print_status "INFO" "Autoloaded options size could not be checked"
fi

if run_wp db query "$LARGEST_AUTOLOAD_QUERY" >/dev/null; then
  print_status "INFO" "Largest autoloaded options:"
  run_wp db query "$LARGEST_AUTOLOAD_QUERY" | sed 's/^/       /'
else
  print_status "INFO" "Largest autoloaded options could not be checked"
fi

echo
echo "------------------------------------------------------------"
echo "6. Transient and revision indicators"
echo "------------------------------------------------------------"

TRANSIENT_QUERY="
SELECT COUNT(*) AS transient_like_options
FROM ${OPTIONS_TABLE}
WHERE option_name LIKE '_transient_%'
   OR option_name LIKE '_site_transient_%';
"

if run_wp db query "$TRANSIENT_QUERY" >/dev/null; then
  print_status "INFO" "Transient-like option count:"
  run_wp db query "$TRANSIENT_QUERY" | sed 's/^/       /'
else
  print_status "INFO" "Transient count could not be checked"
fi

POSTS_TABLE="${TABLE_PREFIX}posts"

REVISION_QUERY="
SELECT COUNT(*) AS revisions
FROM ${POSTS_TABLE}
WHERE post_type = 'revision';
"

AUTO_DRAFT_QUERY="
SELECT COUNT(*) AS auto_drafts
FROM ${POSTS_TABLE}
WHERE post_status = 'auto-draft';
"

if run_wp db query "$REVISION_QUERY" >/dev/null; then
  print_status "INFO" "Post revisions count:"
  run_wp db query "$REVISION_QUERY" | sed 's/^/       /'
else
  print_status "INFO" "Post revisions could not be checked"
fi

if run_wp db query "$AUTO_DRAFT_QUERY" >/dev/null; then
  print_status "INFO" "Auto-draft count:"
  run_wp db query "$AUTO_DRAFT_QUERY" | sed 's/^/       /'
else
  print_status "INFO" "Auto-drafts could not be checked"
fi

echo
echo "------------------------------------------------------------"
echo "7. WooCommerce and plugin table indicators"
echo "------------------------------------------------------------"

PLUGIN_TABLE_QUERY="
SELECT
  table_name AS table_name,
  ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb,
  table_rows AS approx_rows
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name NOT IN (
    '${TABLE_PREFIX}posts',
    '${TABLE_PREFIX}postmeta',
    '${TABLE_PREFIX}options',
    '${TABLE_PREFIX}users',
    '${TABLE_PREFIX}usermeta',
    '${TABLE_PREFIX}comments',
    '${TABLE_PREFIX}commentmeta',
    '${TABLE_PREFIX}terms',
    '${TABLE_PREFIX}termmeta',
    '${TABLE_PREFIX}term_relationships',
    '${TABLE_PREFIX}term_taxonomy',
    '${TABLE_PREFIX}links'
  )
ORDER BY (data_length + index_length) DESC
LIMIT 30;
"

if run_wp db query "$PLUGIN_TABLE_QUERY" >/dev/null; then
  print_status "INFO" "Largest non-core/plugin-related tables:"
  run_wp db query "$PLUGIN_TABLE_QUERY" | sed 's/^/       /'
else
  print_status "INFO" "Plugin-related table overview could not be checked"
fi

echo
echo "------------------------------------------------------------"
echo "8. Review notes"
echo "------------------------------------------------------------"

print_status "INFO" "Large WordPress databases commonly grow in:"
echo "       - ${TABLE_PREFIX}postmeta"
echo "       - ${TABLE_PREFIX}options"
echo "       - ${TABLE_PREFIX}comments / ${TABLE_PREFIX}commentmeta"
echo "       - WooCommerce order and action scheduler tables"
echo "       - Form plugin tables"
echo "       - Security plugin log tables"
echo "       - Backup or statistics plugin tables"

echo
print_status "INFO" "High autoloaded option size can slow every WordPress request."
print_status "INFO" "Large postmeta tables can slow admin screens, searches, WooCommerce, and migrations."
print_status "INFO" "Large logs or plugin tables should not be deleted without identifying the owning plugin."

echo
echo "------------------------------------------------------------"
echo "9. Safety notes"
echo "------------------------------------------------------------"

print_status "WARN" "This script is read-only."
print_status "WARN" "Do not delete database tables only because they are large."
print_status "WARN" "Confirm the owning plugin and create a verified backup before database cleanup."
print_status "WARN" "For WooCommerce, membership, LMS, booking, or payment sites, database cleanup can affect business data."

echo
echo "------------------------------------------------------------"
echo "10. Manual SQL examples"
echo "------------------------------------------------------------"

echo "Use these only when you have safe database access and understand the target database:"
echo
cat <<SQL
-- Top 20 tables by size
SELECT
  table_name,
  ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb,
  table_rows
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY (data_length + index_length) DESC
LIMIT 20;

-- Largest autoloaded options
SELECT
  option_name,
  ROUND(LENGTH(option_value) / 1024, 2) AS size_kb
FROM ${TABLE_PREFIX}options
WHERE autoload = 'yes'
ORDER BY LENGTH(option_value) DESC
LIMIT 20;

-- Count revisions
SELECT COUNT(*) AS revisions
FROM ${TABLE_PREFIX}posts
WHERE post_type = 'revision';
SQL

echo
echo "============================================================"
echo " Database size check completed"
echo "============================================================"
