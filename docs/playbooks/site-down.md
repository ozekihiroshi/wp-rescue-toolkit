# Site Down Playbook

This playbook explains how to perform a safe first-response review when a WordPress site is down, unstable, returning HTTP errors, or showing a white screen.

Use this before changing plugins, themes, WordPress core, database settings, or server configuration.

## When to use this playbook

Use this playbook when:

- The WordPress site does not load.
- The site shows a white screen.
- The site returns HTTP 500, 502, 503, or 504 errors.
- The site shows “Error establishing a database connection.”
- The admin dashboard cannot be accessed.
- The frontend works but `/wp-admin` fails.
- The site fails after a plugin, theme, PHP, or WordPress update.
- The site redirects unexpectedly.
- The site works intermittently.
- A client reports that the site is “down” but the exact failure mode is unclear.

## Goal

The goal is to identify the failure area before making changes.

This playbook helps answer:

- Is the site reachable from outside?
- Is the failure HTTP, DNS, SSL, PHP, WordPress, database, or server-related?
- Is this a full outage or partial outage?
- Is the WordPress document root present?
- Is `wp-config.php` present?
- Are backups or restore materials available?
- Is there a recent change that likely caused the outage?
- Is it safe to proceed with repair steps?

This playbook does not automatically fix the site.

## Do not do first

Do not start with these actions:

- Do not delete plugins.
- Do not delete themes.
- Do not restore an old backup immediately.
- Do not overwrite `wp-config.php`.
- Do not update WordPress core on a broken live site.
- Do not update all plugins at once.
- Do not change PHP versions without rollback planning.
- Do not run database repair before confirming backup status.
- Do not clear or delete files before recording evidence.
- Do not assume the problem is WordPress before checking public status.

## First checks

Start with external/public status if possible.

If you are using the companion site status checker from the security triage toolkit, run:

```bash
python3 scripts/check_site_status.py https://example.com/
```

Then run non-destructive WordPress checks on the server.

```bash
./bin/wp-backup-check.sh /path/to/wordpress
./bin/wp-restore-readiness-check.sh /path/to/wordpress
./bin/wp-rescue-check.sh /path/to/wordpress
./bin/wp-site-audit.sh /path/to/wordpress
```

If WP-CLI may help and the site files are present:

```bash
./bin/wp-cli-readiness-check.sh /path/to/wordpress
```

If performance or database size may be involved:

```bash
./bin/wp-db-size-check.sh /path/to/wordpress
```

## Recommended report output

Save reports before making changes.

```bash
mkdir -p reports

./bin/wp-backup-check.sh /path/to/wordpress \
  > reports/backup-check.txt

./bin/wp-restore-readiness-check.sh /path/to/wordpress \
  > reports/restore-readiness-check.txt

./bin/wp-rescue-check.sh /path/to/wordpress \
  > reports/rescue-check.txt

./bin/wp-site-audit.sh /path/to/wordpress \
  > reports/site-audit.txt

./bin/wp-cli-readiness-check.sh /path/to/wordpress \
  > reports/wp-cli-readiness-check.txt
```

## Classify the outage

Before fixing, classify the failure.

| Symptom | Likely area |
| --- | --- |
| DNS does not resolve | DNS/domain |
| SSL certificate error | SSL/TLS |
| HTTP 404 | routing, document root, web server, WordPress rewrite |
| HTTP 500 | PHP fatal error, WordPress/plugin/theme error, server config |
| HTTP 502/504 | upstream timeout, PHP-FPM, proxy, server resource issue |
| Database connection error | DB credentials, DB service, DB host, network, permissions |
| White screen | PHP fatal error, plugin/theme/core issue |
| Frontend works, admin fails | plugin/theme/admin-specific error, auth, memory, security plugin |
| Admin works, frontend fails | theme, cache, routing, frontend plugin |
| Redirect loop | SSL/proxy config, siteurl/home mismatch, cache, plugin |
| Intermittent outage | resource exhaustion, database instability, cache/proxy issue |

This classification helps avoid random changes.

## Check recent changes

Ask or confirm:

- Was WordPress core updated?
- Were plugins updated?
- Was the theme updated?
- Was PHP version changed?
- Was MySQL/MariaDB changed?
- Was the server migrated?
- Was DNS changed?
- Was SSL renewed or replaced?
- Was a cache/CDN/proxy setting changed?
- Was a security plugin configured?
- Was a backup restored?

Recent changes often narrow the cause.

## WordPress file checks

Important files and directories:

- `wp-config.php`
- `wp-content/`
- `wp-content/plugins/`
- `wp-content/themes/`
- `wp-content/uploads/`
- `index.php`
- `wp-admin/`
- `wp-includes/`
- `.htaccess` for Apache environments

Missing or damaged files may indicate:

- incomplete migration
- failed update
- accidental deletion
- wrong document root
- malware cleanup side effects
- deployment mistake

## Database connection error

If the site shows “Error establishing a database connection,” check:

- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `DB_HOST`
- database service status
- database server reachability
- database user permissions
- table prefix
- recent database password changes
- hosting control panel database status

Do not overwrite `wp-config.php` until the current file is backed up.

If WP-CLI is available, read-only checks may help:

```bash
wp --info --path=/path/to/wordpress
wp core version --path=/path/to/wordpress
```

If WP-CLI cannot connect to the database, the error message may help identify the DB problem.

## White screen or HTTP 500

Common causes:

- plugin fatal error
- theme fatal error
- PHP version incompatibility
- memory limit exhaustion
- missing PHP extension
- corrupted WordPress core file
- syntax error in custom code
- failed update
- `.htaccess` or rewrite issue
- permission issue

Safe next checks:

1. Confirm backup readiness.
2. Check server/PHP error logs if accessible.
3. Check `wp-content/debug.log` if present.
4. Identify recent plugin/theme updates.
5. Check PHP version.
6. Check whether the admin or frontend behaves differently.
7. Consider staging or controlled plugin isolation.

Do not rename the plugins directory until backup status and impact are understood.

## Redirect loop

Common causes:

- `siteurl` and `home` mismatch
- HTTP/HTTPS mismatch
- reverse proxy or load balancer header issue
- WordPress Address or Site Address mismatch
- cache plugin redirect setting
- security plugin redirect setting
- CDN SSL mode mismatch
- `.htaccess` redirect loop
- nginx rewrite issue

If WP-CLI is available, read-only checks may help:

```bash
wp option get siteurl --path=/path/to/wordpress
wp option get home --path=/path/to/wordpress
```

Do not run search-replace or update URLs until backup status is confirmed.

## Plugin or theme failure suspicion

If the outage started after plugin/theme changes:

Recommended approach:

1. Confirm backup.
2. Identify the recent change.
3. Check logs.
4. Confirm whether admin is accessible.
5. Prefer staging if available.
6. Disable only the suspected plugin/theme if needed.
7. Record exactly what changed.

Avoid disabling many plugins at once unless the site is already completely down and the client accepts the approach.

## Server or hosting issue suspicion

The issue may not be WordPress-specific.

Check:

- disk usage
- memory pressure
- CPU load
- PHP-FPM or Apache status
- nginx/Apache logs
- database service status
- SSL certificate status
- reverse proxy status
- CDN status
- firewall/security group rules
- recent OS or package updates

If multiple sites on the same server are down, suspect server or hosting infrastructure first.

## Safe next actions

### If backup readiness is acceptable

Recommended next steps:

1. Save reports.
2. Create a fresh backup of the current state if possible.
3. Identify likely failure area.
4. Review recent changes.
5. Make one small controlled change at a time.
6. Validate frontend and admin.
7. Record before/after results.

### If backup readiness is not acceptable

Recommended next steps:

1. Do not make destructive changes.
2. Ask client or hosting provider for backups.
3. Check hosting panel backups.
4. Check server snapshots.
5. Check backup plugin directories.
6. Create a current-state backup if possible.
7. Document the risk clearly.

### If database connection appears to be the issue

Recommended next steps:

1. Preserve `wp-config.php`.
2. Confirm database service status.
3. Confirm credentials.
4. Confirm DB host and network access.
5. Confirm user permissions.
6. Avoid restoring database until backup impact is understood.

### If PHP/plugin/theme fatal error appears likely

Recommended next steps:

1. Check error logs.
2. Identify the likely plugin/theme.
3. Confirm backup.
4. Use staging when possible.
5. Disable the smallest possible component.
6. Avoid mass updates on the broken live site.

## Client-facing summary

Example when the cause is still unknown:

```text
I will start with a non-destructive WordPress outage review. First I will check public availability, then confirm backup and restore readiness, review WordPress files and configuration, and identify whether the issue is likely DNS, SSL, PHP, WordPress, plugin/theme, database, or server-related before making changes.
```

Example when backup is missing:

```text
The initial review indicates that the site is down, but I do not yet see a confirmed backup or restore point. Before making destructive changes such as plugin removal, database repair, or restore, I recommend confirming hosting backups, server snapshots, or creating a current-state backup.
```

Example when a plugin/theme issue is likely:

```text
The symptoms suggest a possible plugin or theme-related failure. I recommend confirming backup status first, then isolating the likely component in a controlled way rather than updating or disabling many plugins at once.
```

## Related scripts

- `bin/wp-backup-check.sh`
- `bin/wp-restore-readiness-check.sh`
- `bin/wp-rescue-check.sh`
- `bin/wp-site-audit.sh`
- `bin/wp-cli-readiness-check.sh`
- `bin/wp-db-size-check.sh`
- `bin/wp-malware-triage.sh`

## Related documents

- `docs/wordpress-response-playbook.md`
- `docs/playbooks/backup-restore-readiness.md`
- `docs/playbooks/wp-cli-readiness.md`
- `docs/playbooks/mysql-database-issue.md`
- `docs/playbooks/slow-site-performance.md`
- `docs/wp-emergency-response-workflow.md`
- `docs/wp-backup-restore.md`

## Important limitation

This playbook is for first-response triage.

It does not guarantee full recovery and does not replace server administration, DNS management, SSL troubleshooting, malware forensics, or application debugging. It is designed to reduce risk and organize the first steps before changes are made.
