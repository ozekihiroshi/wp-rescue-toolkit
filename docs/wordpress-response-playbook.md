# WordPress Response Playbook

This playbook provides practical, non-destructive first-response workflows for WordPress troubleshooting, recovery, performance review, database review, backup/restore readiness, and migration planning.

It is designed to help decide what to check first before making changes to a live WordPress site.

## Core principle

Do not start by changing the site.

Start by:

1. Checking public availability.
2. Confirming backup and restore readiness.
3. Collecting basic WordPress, server, and database facts.
4. Identifying the likely problem area.
5. Making the smallest safe change.
6. Recording findings and next steps.

The goal is to reduce risk and avoid unnecessary damage.

## When to use this playbook

Use this playbook when dealing with:

- A WordPress site that is down
- White screen or HTTP 500 errors
- Slow WordPress frontend or admin pages
- WordPress MySQL database issues
- Backup or restore uncertainty
- Migration or update planning
- Malware or suspicious redirect concerns
- WP-CLI availability checks

## Playbooks

| Situation | Playbook |
| --- | --- |
| Site down, white screen, HTTP 500, database connection error | [Site Down](playbooks/site-down.md) |
| Slow frontend, slow admin, heavy plugins, cache issues | [Slow Site Performance](playbooks/slow-site-performance.md) |
| Large database, slow MySQL, table growth, autoload options | [MySQL Database Issue](playbooks/mysql-database-issue.md) |
| Backup availability, restore risk, recovery planning | [Backup and Restore Readiness](playbooks/backup-restore-readiness.md) |
| WP-CLI missing or needed for deeper checks | [WP-CLI Readiness](playbooks/wp-cli-readiness.md) |
| Suspicious redirects, malware warnings, unknown files | [Malware Suspicion](playbooks/malware-suspicion.md) |
| WordPress update, PHP upgrade, hosting migration | [Migration and Update Readiness](playbooks/migration-update-readiness.md) |

## Toolkit scripts

| Script | Purpose |
| --- | --- |
| `bin/wp-backup-check.sh` | Check backup-related files and restore materials |
| `bin/wp-restore-readiness-check.sh` | Review whether restore planning can proceed safely |
| `bin/wp-performance-audit.sh` | Check basic performance indicators |
| `bin/wp-db-size-check.sh` | Review database size and table growth using WP-CLI |
| `bin/wp-cli-readiness-check.sh` | Check whether WP-CLI exists or can likely be used |
| `bin/wp-rescue-check.sh` | Basic WordPress rescue checks |
| `bin/wp-site-audit.sh` | General WordPress site audit checks |
| `bin/wp-malware-triage.sh` | Initial malware and suspicious file triage |

## Recommended first commands

Replace `/path/to/wordpress` with the actual WordPress document root.

```bash
./bin/wp-backup-check.sh /path/to/wordpress
./bin/wp-restore-readiness-check.sh /path/to/wordpress
./bin/wp-performance-audit.sh /path/to/wordpress
./bin/wp-cli-readiness-check.sh /path/to/wordpress
```

For database-focused work, run this after confirming WP-CLI availability:

```bash
./bin/wp-db-size-check.sh /path/to/wordpress
```

## What not to do first

Avoid these as first actions:

- Do not delete plugins or themes immediately.
- Do not restore an old database over a live site without impact review.
- Do not run mass search-replace without a verified backup.
- Do not update all plugins at once on a broken live site.
- Do not delete large database tables only because they are large.
- Do not remove suspicious files before recording evidence.
- Do not optimize a production database without a backup.

## Client-facing explanation

A safe first-response approach can be summarized as:

```text
I will start with a non-destructive WordPress review: public site status, backup readiness, restore risk, performance indicators, WP-CLI availability, and database size checks before making changes. This helps identify the likely issue while reducing the risk of data loss or additional downtime.
```

## Related documents

- [Backup and Restore Readiness](wp-backup-restore.md)
- [Performance Audit](wp-performance-audit.md)
- [Emergency Response Workflow](wp-emergency-response-workflow.md)
- [Malware Triage](wp-malware-triage.md)
- [Site Audit](wp-site-audit.md)

## Important limitation

This playbook does not guarantee full recovery, full malware removal, or full performance optimization.

It provides a structured first-response workflow to support safer WordPress troubleshooting and clearer client communication.
