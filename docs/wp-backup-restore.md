# WordPress Backup and Restore Readiness

This document describes a practical backup and restore readiness workflow for WordPress rescue, migration, malware triage, and recovery work.

The goal is not to perform an automatic restore.  
The goal is to confirm whether the essential materials required for recovery appear to exist before making changes to a live site.

## Purpose

Before changing a WordPress site, confirm that the site can be recovered if something goes wrong.

Typical situations include:

- Site down or white screen recovery
- Plugin or theme conflict recovery
- Malware triage
- Server migration
- PHP or MySQL/MariaDB version upgrade
- WordPress core, plugin, or theme update
- Hosting transfer
- Manual file cleanup

A backup is only useful if it is complete enough to restore.

## Related script

```bash
./bin/wp-backup-check.sh /path/to/wordpress
```

Example:

```bash
./bin/wp-backup-check.sh /var/www/html
```

The script is read-only. It does not modify files, databases, plugins, themes, or WordPress settings.

## What should be available for a reliable restore

A practical WordPress restore normally requires the following materials:

| Item | Why it matters |
| --- | --- |
| WordPress files or clean WordPress core | Required to run WordPress |
| `wp-content/uploads` | Media files uploaded by users |
| `wp-content/themes` | Active theme and custom theme files |
| `wp-content/plugins` | Installed plugin code |
| Database dump | Posts, pages, users, settings, plugin data |
| `wp-config.php` or database credentials | Required for database connection |
| Domain and URL replacement plan | Required when migrating to a new domain or path |
| PHP and MySQL/MariaDB compatibility check | Prevents restore failures caused by version mismatch |

## Minimum pre-change checklist

Before making changes to a live WordPress site:

- [ ] Confirm the WordPress root directory.
- [ ] Confirm `wp-config.php` exists.
- [ ] Confirm `wp-content/uploads` exists.
- [ ] Confirm `wp-content/themes` exists.
- [ ] Confirm `wp-content/plugins` exists.
- [ ] Confirm a database backup exists.
- [ ] Confirm file backup location.
- [ ] Confirm whether a hosting control panel backup exists.
- [ ] Confirm whether a plugin backup exists.
- [ ] Confirm whether an external backup exists.
- [ ] Confirm available disk space.
- [ ] Confirm PHP version.
- [ ] Confirm MySQL/MariaDB version.
- [ ] Confirm whether the site is using a cache plugin.
- [ ] Confirm whether the site is using a security plugin.
- [ ] Confirm whether the site is using WooCommerce or another data-sensitive plugin.
- [ ] Record current domain, document root, and database name.
- [ ] Prepare a rollback plan.

## Backup source candidates

Common backup sources include:

- Hosting provider backup
- Control panel backup
- Manual file archive
- Manual database dump
- UpdraftPlus backup
- All-in-One WP Migration backup
- WPvivid backup
- BackupBuddy backup
- Server snapshot
- RDS snapshot
- S3 backup
- Offsite backup

The presence of a backup directory does not prove that the backup is valid.  
It only indicates that backup data may exist.

## Database dump candidates

Common database dump file extensions:

- `.sql`
- `.sql.gz`
- `.sql.zip`
- `.dump`

A database dump should be checked for:

- File size
- Last modified date
- Whether the file appears truncated
- Whether it contains WordPress tables
- Whether it contains the expected table prefix
- Whether it contains `wp_options` or equivalent prefixed options table
- Whether it was created before or after the incident
- Whether it matches the current WordPress files

## Restore readiness levels

### Good

A restore is likely possible when:

- A recent database dump exists.
- `wp-content/uploads` is available.
- Theme and plugin files are available.
- `wp-config.php` or database credentials are available.
- The target PHP and database versions are compatible.
- A staging restore can be tested.

### Partial

A restore may be possible but requires caution when:

- The database dump exists but file backups are incomplete.
- Uploads exist but plugin/theme files are missing.
- Plugin backup exists but database backup is unclear.
- The backup is old.
- The target server environment differs from the original environment.

### High risk

A restore is risky when:

- No database dump is available.
- `wp-content/uploads` is missing.
- `wp-config.php` is missing and credentials are unknown.
- Backup files appear incomplete or extremely small.
- The site uses WooCommerce, membership, LMS, booking, or payment plugins and the backup timing is unclear.
- The site may be infected and backups may also contain malware.

## Special caution for dynamic sites

Some WordPress sites are highly data-sensitive. Examples:

- WooCommerce stores
- Membership sites
- LMS sites
- Booking sites
- Forums or community sites
- Donation sites
- Payment-related sites
- Sites with frequent form submissions

For these sites, backup timing matters. A backup from several hours ago may lose orders, users, bookings, submissions, or payments.

Do not restore a database over a live dynamic site without confirming the impact.

## Migration and URL replacement

When restoring or migrating to a different domain, URL, or path, plan for URL replacement.

Common items to check:

- `siteurl`
- `home`
- Serialized data in the database
- Hardcoded URLs in theme files
- Hardcoded URLs in page builder data
- Upload paths
- Cache files
- CDN URLs
- Mixed HTTP/HTTPS references

Use WordPress-aware tools for serialized data replacement.  
Avoid simple text replacement directly against SQL dumps unless the risk is understood.

## Security notes

Do not expose backup files publicly.

High-risk files include:

- `wp-config.php`
- `.sql`
- `.sql.gz`
- `.zip`
- `.tar`
- `.tar.gz`
- Full site backups
- Plugin-generated backup archives

If backup files are inside a public web directory, confirm that direct access is blocked.

## Recommended workflow

1. Identify the WordPress root directory.
2. Run the backup readiness check.
3. Save the report.
4. Confirm available backup sources.
5. Confirm database backup availability.
6. Confirm file backup availability.
7. Confirm dynamic-site risks.
8. Create a fresh backup before touching the live site.
9. Test restore on staging when possible.
10. Only then proceed with rescue, migration, cleanup, or optimization work.

## Example command

```bash
./bin/wp-backup-check.sh /var/www/html > backup-readiness-report.txt
```

## Important limitation

This checklist and script do not prove that a backup can be restored successfully.

They provide a structured first-pass review to support safer decision-making before WordPress recovery or maintenance work.
