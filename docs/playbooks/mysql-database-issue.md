# MySQL Database Issue Playbook

This playbook explains how to perform a safe first-pass review of WordPress MySQL database issues.

Use this when a WordPress site has database-related errors, slow admin screens, large database size, failed backups, slow queries, or plugin-related table growth.

## When to use this playbook

Use this playbook when:

- WordPress admin pages are slow.
- The frontend is slow and database load may be involved.
- Backups or migrations are slow because the database is large.
- MySQL errors appear in logs.
- A client reports database connection issues.
- `wp_options`, `wp_postmeta`, WooCommerce, or plugin tables may be large.
- Database cleanup or optimization is requested.
- A client asks for WordPress MySQL performance review.
- phpMyAdmin shows many large or unknown tables.
- WP-CLI is needed for database inspection.

## Goal

The goal is to identify likely database risk areas without making destructive changes.

This playbook helps answer:

- Is the database accessible?
- Is WP-CLI available?
- How large is the database?
- Which tables are largest?
- Is `wp_options` or autoload data large?
- Is `wp_postmeta` unusually large?
- Are there large plugin-created tables?
- Are there many transients, revisions, or auto-drafts?
- Is cleanup safe, or is more investigation needed?

This playbook does not delete or optimize database tables.

## Do not do first

Do not start with these actions:

- Do not delete large tables just because they are large.
- Do not empty plugin tables without identifying the owning plugin.
- Do not run database optimization before creating a backup.
- Do not remove autoloaded options without checking what created them.
- Do not delete WooCommerce, membership, LMS, booking, or form plugin data blindly.
- Do not restore an old database over a live site without impact review.
- Do not run SQL commands copied from the internet without understanding the target tables.

## First checks

Start by confirming backup and WP-CLI readiness.

```bash
./bin/wp-backup-check.sh /path/to/wordpress
./bin/wp-cli-readiness-check.sh /path/to/wordpress
```

If WP-CLI is available, run:

```bash
./bin/wp-db-size-check.sh /path/to/wordpress
```

If the site is also generally slow, run:

```bash
./bin/wp-performance-audit.sh /path/to/wordpress
```

## Recommended report output

Save reports for later review.

```bash
mkdir -p reports

./bin/wp-backup-check.sh /path/to/wordpress \
  > reports/backup-check.txt

./bin/wp-cli-readiness-check.sh /path/to/wordpress \
  > reports/wp-cli-readiness-check.txt

./bin/wp-db-size-check.sh /path/to/wordpress \
  > reports/db-size-check.txt

./bin/wp-performance-audit.sh /path/to/wordpress \
  > reports/performance-audit.txt
```

## What to look for

### Database size

Large database size may affect:

- backup time
- restore time
- migration time
- admin performance
- search performance
- WooCommerce screens
- hosting resource usage

A large database is not automatically a problem.  
The key question is which tables are large and why.

### Large core tables

Common large WordPress tables include:

| Table | Common reason for growth |
| --- | --- |
| `wp_posts` | posts, pages, attachments, revisions, orders |
| `wp_postmeta` | custom fields, WooCommerce metadata, page builder data |
| `wp_options` | site settings, plugin settings, transients, autoloaded data |
| `wp_comments` | comments, reviews, spam, WooCommerce notes |
| `wp_commentmeta` | comment metadata |
| `wp_usermeta` | user metadata, membership data |
| `wp_actionscheduler_*` | WooCommerce and scheduled actions |

Adjust the table prefix if the site does not use `wp_`.

### Autoloaded options

Autoloaded options are loaded on many WordPress requests.

Large autoloaded data can slow down the site, especially:

- frontend requests
- admin requests
- AJAX requests
- logged-in user pages

Check:

- total autoloaded option size
- largest autoloaded options
- unknown plugin-created options
- old cache/transient options

Do not delete autoloaded options unless you understand what created them.

### Postmeta growth

`wp_postmeta` often grows because of:

- WooCommerce products and orders
- page builders
- SEO plugins
- custom fields
- LMS plugins
- booking plugins
- repeated imports
- old plugin data

Large `postmeta` can affect admin screens, searches, filters, and migrations.

### Plugin-created tables

Many plugins create their own tables.

Common examples:

- WooCommerce
- Action Scheduler
- form plugins
- security plugins
- analytics/statistics plugins
- backup plugins
- LMS plugins
- booking plugins
- membership plugins

Do not remove plugin tables unless:

1. The owning plugin is identified.
2. The plugin is no longer used.
3. A verified backup exists.
4. The client accepts the risk.
5. A staging test has been completed when possible.

## Manual SQL examples

If WP-CLI is not available but safe database access exists, these read-only SQL queries can help.

Use them carefully. Confirm the target database first.

```sql
-- Top 20 tables by size
SELECT
  table_name,
  ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb,
  table_rows
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY (data_length + index_length) DESC
LIMIT 20;
```

```sql
-- Largest autoloaded options
SELECT
  option_name,
  ROUND(LENGTH(option_value) / 1024, 2) AS size_kb
FROM wp_options
WHERE autoload = 'yes'
ORDER BY LENGTH(option_value) DESC
LIMIT 20;
```

```sql
-- Total autoloaded option size
SELECT
  ROUND(SUM(LENGTH(option_value)) / 1024 / 1024, 2) AS autoload_mb
FROM wp_options
WHERE autoload = 'yes';
```

```sql
-- Count post revisions
SELECT COUNT(*) AS revisions
FROM wp_posts
WHERE post_type = 'revision';
```

```sql
-- Count transient-like options
SELECT COUNT(*) AS transient_like_options
FROM wp_options
WHERE option_name LIKE '_transient_%'
   OR option_name LIKE '_site_transient_%';
```

Replace `wp_` with the actual table prefix.

## How to read results

### Good signs

Good signs include:

- backup exists or can be created
- WP-CLI is available
- database size is reasonable for the site
- largest tables are expected
- no unusually large autoloaded options
- no unknown large plugin tables
- no signs of runaway logs or statistics tables

### Warning signs

Warning signs include:

- WP-CLI is not available
- no database backup is visible
- `wp_options` is large
- autoloaded options are large
- `wp_postmeta` is much larger than expected
- unknown plugin tables are large
- many transients or revisions
- backups are failing because of database size
- phpMyAdmin shows many old plugin tables

### High-risk signs

High-risk signs include:

- no backup before database cleanup
- WooCommerce or payment-related data
- membership, LMS, booking, or subscription data
- unknown tables with business-critical data
- very large database on shared hosting
- suspected malware and database injection
- client asks to “clean database” without knowing what can be removed

## Safe next actions

### If the issue is large database size

Recommended next steps:

1. Confirm backup.
2. Identify top tables by size.
3. Identify whether large tables are core or plugin-created.
4. Confirm active plugins.
5. Review whether large data is still needed.
6. Test cleanup on staging.
7. Apply small changes only after approval.

### If the issue is slow admin pages

Recommended next steps:

1. Check active plugin count.
2. Review `wp_options` and autoload data.
3. Review `wp_postmeta` size.
4. Check WooCommerce/action scheduler tables if relevant.
5. Check PHP errors and debug logs.
6. Review hosting CPU/memory if available.

### If the issue is failed backup or migration

Recommended next steps:

1. Check database size.
2. Identify largest tables.
3. Check whether logs/statistics tables can be excluded safely.
4. Confirm file backup separately.
5. Try a staging export/import.
6. Avoid deleting production data just to make migration easier.

### If the issue is database connection error

Recommended next steps:

1. Check `wp-config.php`.
2. Confirm `DB_NAME`, `DB_USER`, `DB_PASSWORD`, and `DB_HOST`.
3. Confirm database service is running.
4. Confirm network access to the database host.
5. Confirm credentials with hosting provider or control panel.
6. Do not overwrite `wp-config.php` without backup.

## Client-facing summary

Example for a database size review:

```text
I will start with a non-destructive WordPress MySQL review. First I will confirm backup readiness and WP-CLI/database access. Then I will identify the largest tables, review autoloaded options, check postmeta and plugin-created tables, and provide safe cleanup or optimization recommendations before making changes.
```

Example after finding missing backup:

```text
I found that database review is possible, but I do not see a confirmed database backup yet. Before optimizing or cleaning any tables, I recommend creating or confirming a full database backup. Large WordPress tables can contain important plugin, order, membership, or form data, so cleanup should be handled carefully.
```

Example after finding large plugin tables:

```text
The database appears to have large plugin-related tables. The next step is to identify which plugin owns those tables and whether the data is still needed. I do not recommend deleting those tables until backup and plugin usage are confirmed.
```

## Related scripts

- `bin/wp-backup-check.sh`
- `bin/wp-cli-readiness-check.sh`
- `bin/wp-db-size-check.sh`
- `bin/wp-performance-audit.sh`
- `bin/wp-restore-readiness-check.sh`

## Related documents

- `docs/wordpress-response-playbook.md`
- `docs/wp-backup-restore.md`
- `docs/wp-performance-audit.md`
- `docs/wp-emergency-response-workflow.md`

## Important limitation

This playbook is for first-pass database review.

It does not replace full SQL tuning, application profiling, slow query log analysis, or forensic database investigation. It is designed to make WordPress MySQL troubleshooting safer and easier to explain.
