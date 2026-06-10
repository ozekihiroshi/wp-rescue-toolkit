# WordPress Emergency Response Workflow

This document describes a practical first-response workflow for WordPress rescue, outage triage, malware suspicion, backup review, and post-recovery checks.

The goal is to reduce risk before making changes to a live WordPress site.

## Purpose

When a WordPress site is down, infected, slow, or unstable, it is tempting to immediately disable plugins, replace files, restore backups, or update WordPress.

In many cases, that is risky.

A safer workflow is:

1. Observe.
2. Record.
3. Confirm backup and restore options.
4. Identify the likely failure area.
5. Make the smallest safe change.
6. Validate the result.
7. Document findings and next steps.

## Scope

This workflow is useful for:

- White screen of death
- HTTP 500 errors
- Database connection errors
- Plugin or theme conflicts
- Malware suspicion
- Unexpected redirects
- Slow WordPress sites
- Failed migration
- Broken site after update
- Hosting or server handover
- Pre-recovery assessment

This workflow does not replace a full forensic investigation, penetration test, or managed incident response service.

## Related toolkit scripts

| Script | Purpose |
| --- | --- |
| `bin/wp-rescue-check.sh` | Basic WordPress rescue checks |
| `bin/wp-site-audit.sh` | General site audit checks |
| `bin/wp-malware-triage.sh` | Initial malware and suspicious file triage |
| `bin/wp-backup-check.sh` | Backup material and restore readiness check |
| `bin/wp-performance-audit.sh` | Basic performance and bottleneck indicators |

## Recommended order

### 1. Confirm the situation

Before touching the site, collect basic facts:

- What is the visible problem?
- When did it start?
- Was anything changed recently?
- Was WordPress core updated?
- Were plugins or themes updated?
- Was PHP or MySQL/MariaDB updated?
- Was the server migrated?
- Is the problem frontend only, admin only, or both?
- Is the problem affecting all users or only logged-in users?
- Is there a recent backup?

Examples of visible symptoms:

- Site does not load
- White screen
- HTTP 500
- HTTP 403
- HTTP 404
- Too many redirects
- Database connection error
- Admin login unavailable
- Suspicious redirect
- Malware warning
- Very slow response

### 2. Do not make destructive changes first

Avoid doing these as first actions:

- Deleting plugins
- Deleting themes
- Deleting uploads
- Restoring an old database over the live site
- Running mass search-replace
- Updating all plugins at once
- Changing PHP versions without compatibility checks
- Clearing unknown directories
- Removing suspicious files without saving evidence
- Disabling security plugins before understanding the issue

First response should be evidence-preserving and reversible.

### 3. Save a basic report

If possible, save command outputs into a report directory.

Example:

```bash
mkdir -p reports
```

Run checks and save output:

```bash
./bin/wp-backup-check.sh /path/to/wordpress > reports/backup-check.txt
./bin/wp-rescue-check.sh /path/to/wordpress > reports/rescue-check.txt
./bin/wp-site-audit.sh /path/to/wordpress > reports/site-audit.txt
./bin/wp-malware-triage.sh /path/to/wordpress > reports/malware-triage.txt
./bin/wp-performance-audit.sh /path/to/wordpress > reports/performance-audit.txt
```

Adjust the path to the actual WordPress document root.

Common paths include:

```bash
/var/www/html
/var/www/wordpress
/home/USER/public_html
/home/USER/example.com
```

## Emergency workflow

### Step 1: Backup and restore readiness

Run:

```bash
./bin/wp-backup-check.sh /path/to/wordpress
```

Check:

- Is `wp-config.php` present?
- Is `wp-content/uploads` present?
- Are themes present?
- Are plugins present?
- Is there a database dump candidate?
- Is there a backup plugin directory?
- Is there enough disk space?
- Is the site dynamic and data-sensitive?

Do not proceed with high-risk changes unless backup and restore options are understood.

See:

```text
docs/wp-backup-restore.md
```

### Step 2: Basic rescue check

Run:

```bash
./bin/wp-rescue-check.sh /path/to/wordpress
```

Check:

- WordPress root structure
- Important file presence
- File permissions
- `wp-config.php`
- Debug/log indicators
- Basic environment clues

Use this to decide whether the issue appears to be related to files, configuration, permissions, or environment.

### Step 3: Site audit

Run:

```bash
./bin/wp-site-audit.sh /path/to/wordpress
```

Check broader site health indicators.

This can help identify:

- Suspicious file locations
- Common WordPress structure issues
- Configuration risks
- General maintenance concerns

### Step 4: Malware triage when suspicious

Run:

```bash
./bin/wp-malware-triage.sh /path/to/wordpress
```

Use this when there are signs of compromise:

- Unknown admin users
- Suspicious redirects
- Unexpected PHP files
- Obfuscated code
- Search engine warnings
- Security plugin alerts
- Hosting provider suspension
- Recently modified unknown files

Do not delete suspicious files immediately. First record findings and preserve samples when appropriate.

See:

```text
docs/wp-malware-triage.md
```

### Step 5: Performance audit when the site is slow

Run:

```bash
./bin/wp-performance-audit.sh /path/to/wordpress
```

Check:

- PHP version
- Disk usage
- `wp-content` size
- Uploads size
- Plugin count
- Cache drop-ins
- Debug log
- Large uploads
- Optional WP-CLI checks

See:

```text
docs/wp-performance-audit.md
```

## Symptom-based quick guide

### White screen or HTTP 500

Likely areas:

- PHP fatal error
- Plugin conflict
- Theme conflict
- PHP version incompatibility
- Memory limit
- Broken `.htaccess`
- File permission issue

Recommended checks:

```bash
./bin/wp-backup-check.sh /path/to/wordpress
./bin/wp-rescue-check.sh /path/to/wordpress
./bin/wp-site-audit.sh /path/to/wordpress
```

Then check web server logs and PHP error logs.

### Database connection error

Likely areas:

- Wrong DB credentials
- DB server down
- DB host unreachable
- RDS or MySQL/MariaDB issue
- Password changed
- Database user permission issue

Recommended checks:

- Review `wp-config.php`
- Confirm `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`
- Confirm database service is running
- Confirm network access to DB host
- Confirm backup availability before edits

### Suspicious redirect or malware warning

Likely areas:

- Modified theme files
- Modified plugin files
- Malicious dropper files
- Injected JavaScript
- Compromised admin account
- Malicious `.htaccess` rules
- Compromised database content

Recommended checks:

```bash
./bin/wp-backup-check.sh /path/to/wordpress
./bin/wp-malware-triage.sh /path/to/wordpress
./bin/wp-site-audit.sh /path/to/wordpress
```

Also check:

- WordPress admin users
- Recently modified files
- Unknown plugins
- `.htaccess`
- `wp-config.php`
- `wp-content/uploads` for PHP files

### Broken after update

Likely areas:

- Plugin incompatibility
- Theme incompatibility
- PHP version incompatibility
- Incomplete update
- Cache conflict

Recommended approach:

1. Confirm backup.
2. Check logs.
3. Disable one suspected plugin at a time only if safe.
4. Switch theme only if necessary and reversible.
5. Test on staging when possible.

### Slow site

Likely areas:

- No page cache
- Too many plugins
- Heavy page builder
- Large images
- Large database
- Large `debug.log`
- Slow hosting
- Malware
- Excessive external scripts

Recommended checks:

```bash
./bin/wp-performance-audit.sh /path/to/wordpress
./bin/wp-site-audit.sh /path/to/wordpress
```

Also test frontend performance separately with browser-based tools.

## Change control principles

When working on a live WordPress site:

- Make one change at a time.
- Record what was changed.
- Prefer reversible changes.
- Confirm backup before changing.
- Avoid deleting files immediately.
- Rename instead of delete when appropriate.
- Do not restore old databases without confirming data loss risk.
- Validate after each change.
- Keep client-facing notes clear and factual.

## Before disabling plugins

Before disabling plugins:

- Confirm backup.
- Identify whether the site uses WooCommerce, membership, LMS, booking, or payment features.
- Avoid disabling payment, order, security, or membership plugins blindly.
- Consider disabling only the suspected plugin.
- Prefer staging tests when possible.

Common emergency method:

```bash
mv wp-content/plugins/plugin-name wp-content/plugins/plugin-name.disabled
```

This should be used carefully and only when the impact is understood.

## Before restoring a backup

Before restoring a backup:

- Confirm backup date and time.
- Confirm whether orders, users, bookings, or form submissions may be lost.
- Confirm database and file backup match each other.
- Confirm target PHP and database versions.
- Test restore on staging when possible.
- Preserve the current broken state before overwriting it.

For dynamic sites, restoring an old database can cause data loss.

## Before performance optimization

Before optimizing:

- Confirm backup.
- Save current performance observations.
- Check server resource usage.
- Check cache status.
- Check debug logs.
- Check plugin count.
- Check database size if possible.
- Avoid aggressive cleanup before understanding the site.

Optimization should be treated as controlled maintenance, not emergency guessing.

## Client communication notes

A good first-response update should include:

- What was checked
- What was found
- What is risky
- What should be done next
- What should not be done yet

Example:

```text
I completed an initial non-destructive review. The WordPress files are present, but I need to confirm the database backup before making recovery changes. I also found signs that the issue may be related to a plugin or PHP error. I recommend preserving the current state, confirming backup availability, and then testing a targeted plugin isolation step.
```

## Final validation

After any rescue or recovery action, validate:

- Homepage loads
- Admin login works
- Key pages load
- Forms work
- Search works
- Media loads
- Permalinks work
- Error logs are not rapidly growing
- No suspicious redirects remain
- Cache behavior is expected
- Backup is updated after recovery

For WooCommerce or other dynamic sites, also check:

- Cart
- Checkout
- Payment flow
- Orders
- Customer login
- Emails
- Webhooks
- Scheduled actions

## Deliverables

A practical emergency response engagement should produce:

- Initial findings
- Backup/restore readiness notes
- Actions taken
- Risks found
- Items not changed
- Recommended next steps
- Post-recovery validation notes

## Important limitation

This workflow is a first-response operational guide.

It does not guarantee full recovery, full malware removal, forensic completeness, or performance optimization. It is designed to make early WordPress rescue work safer, more structured, and easier to explain to clients.
