# Migration and Update Readiness Playbook

This playbook explains how to perform a safe first-response review before WordPress migration, hosting move, PHP version change, WordPress core update, plugin update, or theme update.

Use this before changing a live WordPress site or moving it to another server.

## When to use this playbook

Use this playbook when:

- A WordPress site will be moved to another server.
- A hosting migration is planned.
- PHP version will be upgraded.
- MySQL or MariaDB version will be changed.
- WordPress core will be updated.
- plugins or themes will be updated.
- a site will be moved from HTTP to HTTPS.
- a domain or URL will change.
- a staging environment will be created.
- a client asks whether the site is safe to update.
- a client asks whether the site is safe to migrate.
- an old WordPress site needs modernization.

## Goal

The goal is to identify migration and update risks before making changes.

This playbook helps answer:

- Is the current WordPress installation valid?
- Are backup and restore materials available?
- Is the database restorable?
- Is WP-CLI available for deeper checks?
- Are plugins, themes, or PHP versions likely to cause compatibility problems?
- Is the database large or hard to migrate?
- Are uploads large?
- Is the site dynamic or transaction-sensitive?
- Will URL replacement be needed?
- Is staging recommended before production changes?

This playbook does not perform migration or update work automatically.

## Do not do first

Do not start with these actions:

- Do not update WordPress core on a live site without backup.
- Do not update all plugins at once.
- Do not change PHP version without checking compatibility.
- Do not migrate only files and forget the database.
- Do not restore an old database over a live dynamic site.
- Do not run search-replace without a database backup.
- Do not delete old plugins or themes without checking usage.
- Do not assume a backup plugin archive is complete.
- Do not assume the target server matches the source server.
- Do not skip staging for high-risk sites.

## First checks

Start with backup, restore, performance, and WP-CLI readiness.

```bash
./bin/wp-backup-check.sh /path/to/wordpress
./bin/wp-restore-readiness-check.sh /path/to/wordpress
./bin/wp-performance-audit.sh /path/to/wordpress
./bin/wp-cli-readiness-check.sh /path/to/wordpress
```

If WP-CLI is available, check database size.

```bash
./bin/wp-db-size-check.sh /path/to/wordpress
```

If malware or suspicious files are also a concern, run malware triage before migration.

```bash
./bin/wp-malware-triage.sh /path/to/wordpress
```

## Recommended report output

Save reports before planning migration or update work.

```bash
mkdir -p reports

./bin/wp-backup-check.sh /path/to/wordpress \
  > reports/backup-check.txt

./bin/wp-restore-readiness-check.sh /path/to/wordpress \
  > reports/restore-readiness-check.txt

./bin/wp-performance-audit.sh /path/to/wordpress \
  > reports/performance-audit.txt

./bin/wp-cli-readiness-check.sh /path/to/wordpress \
  > reports/wp-cli-readiness-check.txt

./bin/wp-db-size-check.sh /path/to/wordpress \
  > reports/db-size-check.txt
```

## Migration readiness checklist

Before migration, confirm:

- [ ] source WordPress document root is known
- [ ] `wp-config.php` is available
- [ ] database credentials are available
- [ ] database export is possible
- [ ] file backup is possible
- [ ] uploads are included
- [ ] plugins are included
- [ ] themes are included
- [ ] custom code is identified
- [ ] target PHP version is known
- [ ] target MySQL/MariaDB version is known
- [ ] target web server type is known
- [ ] SSL/TLS plan is clear
- [ ] DNS cutover plan is clear
- [ ] URL replacement plan is clear
- [ ] rollback plan is clear
- [ ] staging test is considered

## Update readiness checklist

Before WordPress, plugin, theme, or PHP updates, confirm:

- [ ] current backup exists
- [ ] restore method is known
- [ ] WordPress version is known
- [ ] PHP version is known
- [ ] MySQL/MariaDB version is known
- [ ] active theme is known
- [ ] active plugins are known
- [ ] business-critical plugins are identified
- [ ] WooCommerce or payment features are identified
- [ ] membership, LMS, booking, or form features are identified
- [ ] custom theme or custom plugin code is identified
- [ ] staging environment is available or considered
- [ ] update order is planned
- [ ] rollback plan is prepared

## Main risk areas

| Area | Migration/update risk |
| --- | --- |
| Database | large DB, failed export/import, serialized data, table prefix issues |
| Uploads | large media directory, missing uploads, slow transfer |
| Plugins | outdated plugins, abandoned plugins, PHP incompatibility |
| Theme | custom theme changes, old premium theme, page builder dependency |
| PHP | old code incompatible with newer PHP |
| MySQL/MariaDB | version differences, charset/collation issues |
| Cache | stale cache, object cache drop-in, CDN/proxy behavior |
| Domain/URL | serialized URL data, mixed content, redirect loops |
| Dynamic data | orders, users, bookings, payments, form submissions |
| Security | migrating infected files, outdated vulnerable components |
| DNS/SSL | cutover delay, certificate mismatch, HTTPS redirect problems |

## Dynamic site caution

Be especially careful with:

- WooCommerce stores
- membership sites
- LMS sites
- booking sites
- donation sites
- payment sites
- forums or communities
- sites with frequent form submissions
- sites with user-generated content

For these sites, migration timing matters.

If the database changes after export, the target site may miss:

- orders
- users
- bookings
- payments
- form submissions
- subscription changes
- course progress
- comments or reviews

Plan maintenance windows or data freeze periods when needed.

## URL replacement caution

Migration often requires URL changes.

Examples:

- `http://example.com` to `https://example.com`
- old domain to new domain
- staging domain to production domain
- subdirectory to root
- root to subdirectory

WordPress data may contain serialized values.  
Simple text replacement in SQL dumps can break serialized data.

Use WordPress-aware tools when possible.

If WP-CLI is available, `wp search-replace` may be useful, but it can be destructive.

Before using it:

1. Confirm database backup.
2. Confirm old and new URLs.
3. Run a dry run when possible.
4. Confirm table scope.
5. Avoid replacing unrelated strings.
6. Test on staging first when possible.

## PHP version update caution

PHP version changes can break old WordPress sites.

Check:

- current PHP version
- target PHP version
- WordPress core version
- active plugin compatibility
- active theme compatibility
- custom code
- deprecated PHP functions
- missing PHP extensions
- error logs after test update

Do not jump PHP versions on production without rollback planning.

## Plugin and theme update caution

Plugin and theme updates can break:

- layouts
- checkout
- forms
- page builders
- custom fields
- shortcodes
- membership access
- payment workflows
- booking flows
- API integrations

Safer update approach:

1. Backup first.
2. Update on staging.
3. Update WordPress core carefully.
4. Update plugins in small groups.
5. Update high-risk plugins one at a time.
6. Test critical workflows.
7. Record versions before and after.
8. Apply to production only after validation.

## Database migration issues

Common database migration problems:

- export timeout
- import timeout
- large tables
- charset or collation mismatch
- old MyISAM tables
- missing tables
- wrong table prefix
- serialized data breakage
- URL mismatch
- permissions problem
- plugin-created tables omitted
- large autoload options
- action scheduler backlog

Use the database playbook when needed:

```text
docs/playbooks/mysql-database-issue.md
```

## File migration issues

Common file migration problems:

- missing uploads
- missing hidden files
- wrong file ownership
- wrong file permissions
- incomplete transfer
- old cache files moved to new server
- backup archives left in public directories
- infected files migrated
- custom plugin or theme files missed
- `.htaccess` not migrated or migrated incorrectly

Check the site after migration before changing DNS.

## DNS and SSL cutover

Before DNS cutover, confirm:

- target site loads by temporary domain or hosts file
- database import succeeded
- uploads are visible
- admin login works
- permalinks work
- SSL certificate is ready
- redirects are planned
- mail sending behavior is understood
- cache/CDN behavior is understood
- old server rollback option exists

After cutover, validate:

- homepage
- key pages
- admin login
- forms
- checkout if applicable
- uploads/media
- redirects
- SSL
- canonical URL
- sitemap
- robots.txt
- error logs

## Safe next actions

### If migration readiness looks good

Recommended next steps:

1. Save reports.
2. Create fresh file and database backups.
3. Prepare staging or target environment.
4. Test restore/import.
5. Test URL replacement.
6. Validate critical workflows.
7. Plan DNS/SSL cutover.
8. Keep rollback path available.

### If update readiness looks good

Recommended next steps:

1. Save reports.
2. Create backup.
3. Update staging first if possible.
4. Update high-risk items one at a time.
5. Test critical workflows.
6. Apply production changes in a controlled window.
7. Record before/after versions.

### If readiness is weak

Recommended next steps:

1. Do not proceed directly on production.
2. Confirm backups.
3. Identify missing restore materials.
4. Check plugin/theme compatibility.
5. Create staging if possible.
6. Document risks for the client.
7. Reduce the scope of first changes.

### If malware is suspected

Recommended next steps:

1. Run malware triage first.
2. Do not migrate infected files blindly.
3. Identify clean restore options.
4. Consider replacing WordPress core with a clean copy.
5. Review plugins, themes, and uploads.
6. Rotate credentials after cleanup.

## Client-facing summary

Example before migration:

```text
I will start with a migration readiness review before moving the WordPress site. I will check backup and restore readiness, WordPress files, database size, WP-CLI availability, uploads, plugins, themes, PHP/MySQL compatibility, and URL replacement risk before changing the live site.
```

Example before updates:

```text
I will start with an update readiness review before changing WordPress core, plugins, themes, or PHP. The goal is to confirm backup status, identify high-risk plugins or custom code, and plan a safe update order with rollback options.
```

Example when readiness is weak:

```text
The initial readiness review shows that proceeding directly on production would be risky because backup, restore, compatibility, or staging information is incomplete. I recommend confirming those items before migration or updates.
```

## Related scripts

- `bin/wp-backup-check.sh`
- `bin/wp-restore-readiness-check.sh`
- `bin/wp-performance-audit.sh`
- `bin/wp-cli-readiness-check.sh`
- `bin/wp-db-size-check.sh`
- `bin/wp-site-audit.sh`
- `bin/wp-malware-triage.sh`

## Related documents

- `docs/wordpress-response-playbook.md`
- `docs/playbooks/backup-restore-readiness.md`
- `docs/playbooks/mysql-database-issue.md`
- `docs/playbooks/slow-site-performance.md`
- `docs/playbooks/wp-cli-readiness.md`
- `docs/playbooks/malware-suspicion.md`
- `docs/wp-backup-restore.md`
- `docs/wp-performance-audit.md`
- `docs/wp-emergency-response-workflow.md`

## Important limitation

This playbook is for migration and update readiness review.

It does not perform migration, update WordPress, replace URLs, change PHP versions, modify DNS, install SSL certificates, or guarantee compatibility. It is designed to organize the checks that should happen before production changes.
