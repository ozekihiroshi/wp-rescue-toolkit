# Backup and Restore Readiness Playbook

This playbook explains how to check WordPress backup and restore readiness before making changes to a live site.

Use this when you need to confirm whether a WordPress site can be safely recovered, migrated, cleaned, updated, or repaired.

## When to use this playbook

Use this playbook when:

- A WordPress site is down or unstable.
- A client asks for recovery or repair work.
- A site may need to be restored from backup.
- A site will be migrated to another server.
- WordPress core, plugins, themes, PHP, or MySQL/MariaDB will be updated.
- Malware cleanup or suspicious file removal may be needed.
- Database repair or optimization may be needed.
- You need to confirm whether a backup actually exists.

## Goal

The goal is to answer these questions before touching the site:

- Is this a valid WordPress installation?
- Are essential WordPress files present?
- Are uploads, plugins, and themes present?
- Is there a database backup candidate?
- Is there a backup plugin directory?
- Is `wp-config.php` available?
- Are database connection details available?
- Is the site dynamic or transaction-sensitive?
- Is it safe to proceed with repair, migration, or cleanup?

This playbook does not perform a restore.

## Do not do first

Do not start with these actions:

- Do not delete plugins.
- Do not delete themes.
- Do not delete uploads.
- Do not overwrite the database.
- Do not restore an old database over a live site.
- Do not run mass search-replace.
- Do not remove suspicious files before recording evidence.
- Do not optimize or clean the database before confirming backup status.

## First checks

Start with non-destructive checks.

Replace `/path/to/wordpress` with the actual WordPress document root.

```bash
./bin/wp-backup-check.sh /path/to/wordpress
./bin/wp-restore-readiness-check.sh /path/to/wordpress
```

If the site is also slow or database-related, run:

```bash
./bin/wp-cli-readiness-check.sh /path/to/wordpress
./bin/wp-db-size-check.sh /path/to/wordpress
```

`wp-db-size-check.sh` requires WP-CLI. If WP-CLI is not available, use `wp-cli-readiness-check.sh` first.

## Recommended report output

For real work, save reports instead of only reading terminal output.

Example:

```bash
mkdir -p reports

./bin/wp-backup-check.sh /path/to/wordpress \
  > reports/backup-check.txt

./bin/wp-restore-readiness-check.sh /path/to/wordpress \
  > reports/restore-readiness-check.txt
```

For database-related restoration planning:

```bash
./bin/wp-cli-readiness-check.sh /path/to/wordpress \
  > reports/wp-cli-readiness-check.txt

./bin/wp-db-size-check.sh /path/to/wordpress \
  > reports/db-size-check.txt
```

## How to read the results

### Good signs

Good signs include:

- `wp-config.php` found
- `wp-content` found
- WordPress core files found
- `wp-content/uploads` found
- `wp-content/plugins` found
- `wp-content/themes` found
- Database dump candidate found
- Backup directory candidate found
- Database settings found in `wp-config.php`
- Disk space is not close to full

These do not prove that a restore will work, but they indicate that recovery materials may exist.

### Warning signs

Warning signs include:

- No database dump candidate found
- No common backup directory found
- `wp-config.php` missing
- `uploads` missing
- themes or plugins missing
- backup files are very small
- backup date is unclear
- WP-CLI is not available
- site appears to be old or unmaintained

Warnings mean more investigation is needed before changing the site.

### High-risk signs

High-risk signs include:

- No database backup
- No file backup
- no `wp-config.php`
- missing `wp-content/uploads`
- unknown database credentials
- dynamic site with orders, bookings, users, or payments
- suspected malware and no clean backup
- production site with no staging environment

High-risk cases should not proceed directly to restore, cleanup, or update work.

## Dynamic site caution

Be especially careful with:

- WooCommerce stores
- Membership sites
- LMS sites
- Booking sites
- Payment-related sites
- Donation sites
- Forums or communities
- Sites with frequent form submissions

For these sites, database backup timing is critical.

Restoring an old database may lose:

- orders
- customers
- users
- bookings
- payments
- form submissions
- membership changes
- course progress

Do not restore an old database over a live dynamic site without impact review.

## Backup source checklist

Check possible backup sources:

- hosting control panel backups
- server snapshots
- EBS snapshots
- RDS snapshots
- manual file archives
- manual SQL dumps
- UpdraftPlus backups
- All-in-One WP Migration backups
- WPvivid backups
- BackupBuddy backups
- S3 or remote backups
- offsite backup services

Do not assume a backup is valid only because a backup directory exists.

## Restore readiness checklist

Before planning a restore, confirm:

- [ ] backup date and time
- [ ] database backup exists
- [ ] file backup exists
- [ ] uploads are included
- [ ] theme files are included
- [ ] plugin files are included
- [ ] `wp-config.php` or DB credentials are available
- [ ] table prefix is known
- [ ] current site state is preserved
- [ ] target PHP version is known
- [ ] target MySQL/MariaDB version is known
- [ ] domain or URL changes are planned
- [ ] serialized data replacement will be handled safely
- [ ] staging restore is possible or has been considered

## Next actions

### If backup materials look complete

Proceed with careful planning:

1. Save the reports.
2. Create a fresh backup of the current state.
3. Confirm the restore target.
4. Test restore on staging when possible.
5. Plan URL replacement if migration is involved.
6. Restore files and database in a controlled order.
7. Validate the restored site.

### If backup materials are incomplete

Do not proceed with destructive changes.

Next steps:

1. Ask the client or hosting provider for backups.
2. Check server-level backup locations.
3. Check hosting panel backups.
4. Check cloud snapshots.
5. Check backup plugin directories.
6. Create a fresh backup of the current broken state.
7. Document what is missing.

### If no database backup exists

Be very cautious.

WordPress files alone cannot fully restore:

- posts
- pages
- users
- settings
- plugin data
- WooCommerce data
- form submissions
- menus
- widgets

If no database backup exists, recovery options may be limited.

## Client-facing summary

Use a clear, factual summary.

Example:

```text
I completed an initial backup and restore readiness review. The WordPress files and wp-content directory are present, but I did not find a database dump or common backup directory in the checked path. Before making repair or cleanup changes, I recommend confirming hosting-level backups, database backups, or server snapshots. Without a database backup, a full WordPress restore may not be possible.
```

If materials look complete:

```text
The initial review found the main WordPress files, wp-content, uploads, themes, plugins, and possible backup materials. The next safe step is to confirm the backup date, create a fresh backup of the current state, and test restoration on staging before making production changes.
```

## Related scripts

- `bin/wp-backup-check.sh`
- `bin/wp-restore-readiness-check.sh`
- `bin/wp-cli-readiness-check.sh`
- `bin/wp-db-size-check.sh`

## Related documents

- `docs/wp-backup-restore.md`
- `docs/wp-emergency-response-workflow.md`
- `docs/wordpress-response-playbook.md`

## Important limitation

This playbook and the related scripts do not prove that a backup is valid or restorable.

They provide a structured, non-destructive first-pass review before WordPress recovery, migration, cleanup, or update work.
