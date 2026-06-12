# Slow Site Performance Playbook

This playbook explains how to perform a safe first-pass review of a slow WordPress site.

Use this when a WordPress frontend, admin dashboard, login page, WooCommerce screen, or editor page is slow and you need to identify likely causes before making changes.

## When to use this playbook

Use this playbook when:

- WordPress frontend pages are slow.
- WordPress admin pages are slow.
- Login or dashboard pages are slow.
- WooCommerce product, order, or checkout pages are slow.
- Backups, imports, exports, or migrations are slow.
- A client reports that the site became slow after plugin/theme changes.
- Cache appears misconfigured.
- `wp-content/uploads` is large.
- plugins or themes may be excessive.
- the database may be large or inefficient.
- hosting resources may be insufficient.

## Goal

The goal is to identify likely performance bottlenecks without making destructive changes.

This playbook helps answer:

- Is the site structurally a valid WordPress installation?
- Is backup readiness acceptable before optimization?
- Are there many plugins or themes?
- Is there a cache configuration problem?
- Is `WP_DEBUG` or `debug.log` causing overhead?
- Are uploads, plugins, themes, or logs unusually large?
- Is WP-CLI available for deeper checks?
- Is the database likely involved?
- Should the next step be hosting review, plugin review, DB review, or frontend optimization?

This playbook does not perform automatic optimization.

## Do not do first

Do not start with these actions:

- Do not update all plugins at once.
- Do not delete plugins without checking whether they are active or business-critical.
- Do not switch themes on a live site without a rollback plan.
- Do not clear all cache layers without understanding what cache exists.
- Do not optimize the database without a backup.
- Do not delete uploads or generated images blindly.
- Do not assume every slow WordPress site is a database problem.
- Do not assume every slow WordPress site is a hosting problem.

## First checks

Start with backup and general performance checks.

```bash
./bin/wp-backup-check.sh /path/to/wordpress
./bin/wp-performance-audit.sh /path/to/wordpress
```

If database involvement is suspected, check WP-CLI and database size.

```bash
./bin/wp-cli-readiness-check.sh /path/to/wordpress
./bin/wp-db-size-check.sh /path/to/wordpress
```

If malware or suspicious redirects are also reported, run malware triage separately.

```bash
./bin/wp-malware-triage.sh /path/to/wordpress
```

## Recommended report output

Save reports before making changes.

```bash
mkdir -p reports

./bin/wp-backup-check.sh /path/to/wordpress \
  > reports/backup-check.txt

./bin/wp-performance-audit.sh /path/to/wordpress \
  > reports/performance-audit.txt

./bin/wp-cli-readiness-check.sh /path/to/wordpress \
  > reports/wp-cli-readiness-check.txt

./bin/wp-db-size-check.sh /path/to/wordpress \
  > reports/db-size-check.txt
```

## Main performance areas

A slow WordPress site usually falls into one or more of these areas:

| Area | Examples |
| --- | --- |
| Hosting resources | CPU, memory, disk I/O, shared hosting limits |
| PHP runtime | old PHP version, low memory limit, slow PHP-FPM/Apache setup |
| Plugins | too many plugins, heavy page builders, security scans, statistics plugins |
| Theme | heavy theme, page builder dependency, unoptimized templates |
| Database | large tables, large autoload options, large postmeta, slow queries |
| Cache | no page cache, broken object cache, stale cache configuration |
| Media | large uploads, uncompressed images, excessive thumbnails |
| External calls | third-party APIs, fonts, ads, analytics, payment services |
| Logs/debug | large `debug.log`, enabled `WP_DEBUG`, verbose plugin logging |
| Malware | injected scripts, suspicious redirects, hidden admin users, spam pages |

The first-pass goal is to narrow the likely area, not to fix everything at once.

## How to read the results

### Good signs

Good signs include:

- backup readiness is acceptable
- plugin count is reasonable
- theme count is reasonable
- uploads size is reasonable
- no large `debug.log`
- `WP_DEBUG` is not enabled on production
- cache plugin or cache drop-in is present
- WP-CLI is available
- database size is reasonable
- no unusually large autoloaded options

These do not prove that the site is optimized, but they reduce the likelihood of common WordPress performance problems.

### Warning signs

Warning signs include:

- no visible backup before optimization
- many active plugins
- many unused themes
- large uploads directory
- large plugins or themes directory
- no obvious cache layer
- `WP_CACHE` enabled but no clear cache plugin/drop-in
- `debug.log` is large
- `WP_DEBUG` appears enabled
- WP-CLI is not available
- database size is large
- `wp_options` or autoload data is large
- `wp_postmeta` is very large
- many revisions, transients, or action scheduler rows

Warnings indicate where to investigate next.

### High-risk signs

High-risk signs include:

- production site has no backup
- WooCommerce checkout is slow
- membership or booking pages are slow
- database is very large on shared hosting
- database cleanup requested without backup
- suspicious redirects or malware symptoms
- many unknown plugins
- old PHP or old WordPress core
- failed backups due to timeout or size
- client asks for immediate changes on a live site without staging

High-risk cases should be handled with staging, backup confirmation, and smaller change sets.

## Plugin and theme review

Plugin count alone is not the problem.  
The important question is what the plugins do.

Pay special attention to:

- page builders
- WooCommerce extensions
- security plugins
- backup plugins
- analytics/statistics plugins
- related posts plugins
- image optimization plugins
- form plugins
- LMS plugins
- membership plugins
- booking plugins
- abandoned plugins
- duplicate functionality plugins

Theme review should check:

- active theme
- parent/child theme relationship
- many unused themes
- bundled page builder dependencies
- custom code in theme files
- old premium theme versions

Do not delete inactive themes or plugins until backup and ownership are confirmed.

## Cache review

Check whether the site has:

- page cache
- object cache
- browser cache
- CDN cache
- server-level cache
- plugin-level cache

Common files to notice:

- `wp-content/advanced-cache.php`
- `wp-content/object-cache.php`

Possible issues:

- `WP_CACHE` enabled but no working cache plugin
- cache plugin installed but disabled
- object cache drop-in left behind after Redis/Memcached removal
- cache not excluding cart, checkout, or account pages
- cache cleared too often
- multiple cache plugins conflicting

Do not install a new cache plugin before understanding the existing cache layers.

## Database-related performance

If database involvement is suspected, use the MySQL database playbook.

Common database-related causes:

- large `wp_options`
- large autoloaded options
- large `wp_postmeta`
- WooCommerce order metadata
- Action Scheduler backlog
- old plugin tables
- statistics/log tables
- repeated imports
- excessive revisions
- many transients

Use:

```bash
./bin/wp-db-size-check.sh /path/to/wordpress
```

Then continue with:

```text
docs/playbooks/mysql-database-issue.md
```

## Media and uploads

Large uploads can affect:

- backups
- migrations
- disk usage
- image delivery
- thumbnail generation
- admin media library performance

Check:

- total uploads size
- very large files
- old backup archives stored under uploads
- duplicate generated images
- uncompressed originals
- video files stored locally
- PDF or downloadable file growth

Do not delete media files unless usage and backup are confirmed.

## Hosting and server review

Some performance issues are not WordPress-specific.

Check:

- disk usage
- memory pressure
- CPU load
- PHP version
- PHP memory limit
- PHP execution time
- Apache/nginx configuration
- database server location
- database service health
- SSL/TLS and redirect chain
- CDN or reverse proxy configuration

If the site is on shared hosting, performance may be limited by hosting constraints.

## Safe next actions

### If plugin/theme overhead looks likely

Recommended next steps:

1. Confirm backup.
2. List active plugins.
3. Identify heavy or duplicate plugins.
4. Check recent plugin/theme changes.
5. Test deactivation only on staging when possible.
6. Disable one plugin at a time only with approval.
7. Record before/after behavior.

### If database overhead looks likely

Recommended next steps:

1. Confirm database backup.
2. Run database size check.
3. Identify largest tables.
4. Review autoloaded options.
5. Review `wp_postmeta`.
6. Identify plugin-created tables.
7. Plan cleanup carefully.

### If cache issue looks likely

Recommended next steps:

1. Identify all cache layers.
2. Check cache plugin status.
3. Check `WP_CACHE`.
4. Check cache drop-ins.
5. Review CDN/server cache if applicable.
6. Clear cache in a controlled way.
7. Avoid installing multiple cache plugins.

### If media size looks likely

Recommended next steps:

1. Confirm backup.
2. Identify largest uploads.
3. Check whether large files are used.
4. Review image optimization options.
5. Avoid deleting originals without approval.
6. Consider offloading large media if appropriate.

### If hosting limits look likely

Recommended next steps:

1. Collect WordPress-level evidence.
2. Check disk, CPU, memory, and PHP limits.
3. Compare admin vs frontend behavior.
4. Check database host response if possible.
5. Recommend hosting or server changes only with evidence.

## Client-facing summary

Example before work:

```text
I will start with a non-destructive WordPress performance review. I will check backup readiness, plugin/theme footprint, cache indicators, debug/log settings, uploads size, WP-CLI availability, and database size before recommending changes. This helps avoid risky trial-and-error changes on the live site.
```

Example after finding likely database involvement:

```text
The initial performance review suggests that database size or table growth may be contributing to the slowdown. The next step is to review the largest tables, autoloaded options, and plugin-created tables before making cleanup or optimization changes.
```

Example after finding likely plugin/cache involvement:

```text
The initial review suggests that plugin load or cache configuration may be contributing to the slowdown. I recommend confirming backups first, then reviewing active plugins and cache layers in a controlled way rather than disabling multiple plugins at once.
```

## Related scripts

- `bin/wp-backup-check.sh`
- `bin/wp-performance-audit.sh`
- `bin/wp-cli-readiness-check.sh`
- `bin/wp-db-size-check.sh`
- `bin/wp-restore-readiness-check.sh`
- `bin/wp-site-audit.sh`

## Related documents

- `docs/wordpress-response-playbook.md`
- `docs/playbooks/mysql-database-issue.md`
- `docs/wp-performance-audit.md`
- `docs/wp-backup-restore.md`
- `docs/wp-emergency-response-workflow.md`

## Important limitation

This playbook is for first-pass WordPress performance triage.

It does not replace full application profiling, browser performance analysis, server monitoring, database slow query analysis, or CDN/network diagnostics. It is designed to identify likely WordPress performance risk areas safely before making changes.
