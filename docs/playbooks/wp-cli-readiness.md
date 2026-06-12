# WP-CLI Readiness Playbook

This playbook explains how to check whether WP-CLI is available, usable, or installable for a WordPress site.

WP-CLI is useful for deeper WordPress investigation, database review, plugin/theme inventory, search-replace planning, cache checks, and maintenance tasks. However, it should be checked carefully before relying on it in production work.

## When to use this playbook

Use this playbook when:

- WP-CLI may be needed for WordPress troubleshooting.
- A database size or table review is needed.
- Plugin and theme inventory is needed.
- A migration or restore requires command-line checks.
- A site is slow and deeper WordPress inspection is needed.
- A server does not clearly have WP-CLI installed.
- A Docker WordPress environment separates web and CLI containers.
- You need to confirm whether WP-CLI can read the WordPress installation.
- You need to decide whether to use an existing WP-CLI binary, a dedicated CLI container, or a temporary/user-local install.

## Goal

The goal is to answer these questions:

- Is this a valid WordPress document root?
- Is the `wp` command already available?
- Can WP-CLI read the WordPress installation?
- Is PHP CLI available?
- Is the PHP version suitable for current WP-CLI usage?
- Are required PHP extensions available?
- Is a download tool such as `curl` or `wget` available?
- Is there a writable location for installing WP-CLI if needed?
- Is a MySQL/MariaDB client available?
- Are `wp-config.php` database settings visible?
- Should we use a dedicated WP-CLI container instead of modifying the web container?

This playbook does not install WP-CLI automatically.

## Do not do first

Do not start with these actions:

- Do not install WP-CLI globally without understanding the server environment.
- Do not overwrite an existing `wp` command.
- Do not run destructive WP-CLI commands before confirming backup status.
- Do not run `wp search-replace` on production without a database backup.
- Do not run plugin/theme updates before confirming restore options.
- Do not assume WP-CLI works only because the `wp` command exists.
- Do not assume WP-CLI is unavailable only because it is missing in the web container.
- Do not install extra packages in a production container if a dedicated CLI container is available.

## First checks

Start with the WP-CLI readiness script.

```bash
./bin/wp-cli-readiness-check.sh /path/to/wordpress
```

If database checks are planned, confirm backup readiness first.

```bash
./bin/wp-backup-check.sh /path/to/wordpress
./bin/wp-cli-readiness-check.sh /path/to/wordpress
```

If WP-CLI is available and backup readiness is acceptable, database review can follow.

```bash
./bin/wp-db-size-check.sh /path/to/wordpress
```

## Recommended report output

Save the readiness result.

```bash
mkdir -p reports

./bin/wp-cli-readiness-check.sh /path/to/wordpress \
  > reports/wp-cli-readiness-check.txt
```

For database-related work:

```bash
./bin/wp-backup-check.sh /path/to/wordpress \
  > reports/backup-check.txt

./bin/wp-cli-readiness-check.sh /path/to/wordpress \
  > reports/wp-cli-readiness-check.txt

./bin/wp-db-size-check.sh /path/to/wordpress \
  > reports/db-size-check.txt
```

## How to read the results

### Good signs

Good signs include:

- WordPress root detected
- `wp` command found
- `wp --info` works
- WP-CLI can read the WordPress installation
- PHP CLI is available
- PHP version is modern enough
- `curl` or `wget` is available
- required PHP extensions are available
- MySQL/MariaDB client is available
- `wp-config.php` is found
- DB settings are visible in `wp-config.php`

These signs indicate that WP-CLI-based inspection is likely possible.

### Warning signs

Warning signs include:

- `wp` command not found
- PHP CLI is missing
- PHP version is old
- `curl` and `wget` are missing
- required PHP extensions are missing
- no writable install directory is found
- MySQL/MariaDB client is missing
- `wp-config.php` is missing
- WP-CLI exists but cannot read the WordPress installation
- the command is being run from the wrong directory

Warnings do not always block work. They indicate that the execution environment needs review.

### High-risk signs

High-risk signs include:

- production site has no backup
- WP-CLI can run destructive commands but backup status is unknown
- site is old and uses an old PHP version
- WordPress is very outdated
- plugin/theme update is requested without staging
- database search-replace is requested without backup
- WooCommerce, membership, LMS, booking, or payment data is present
- the web container would need modification even though a dedicated CLI container is available

High-risk cases require backup confirmation and controlled execution.

## Docker-specific interpretation

In Docker environments, WP-CLI may be separated from the web container.

A common structure is:

```text
wordpress-web
  Runs Apache/nginx/PHP and serves the site.
  WP-CLI may not be installed.

wordpress-db
  Runs MySQL or MariaDB.

wordpress-cli
  Runs WP-CLI only when needed.
  Shares the same WordPress volume as the web container.
```

This is a good design.

It means:

- the web container can stay smaller and simpler
- WP-CLI can be run only when needed
- command-line maintenance is separated from web serving
- the CLI container can share the same WordPress files
- the CLI container should use a compatible PHP version

If the web container does not have WP-CLI, that is not automatically a problem.  
Check whether a dedicated WP-CLI container is available.

## Example Docker commands

For a dedicated WP-CLI service:

```bash
docker compose --profile cli run --rm \
  -v ~/projects/wp-rescue-toolkit/bin:/toolkit:ro \
  wp-cli sh -lc '/toolkit/wp-cli-readiness-check.sh /var/www/html'
```

For a web container without mounting the toolkit directory:

```bash
docker compose exec -T wp-rescue bash -lc '
  /bin/bash -s /var/www/html
' < ~/projects/wp-rescue-toolkit/bin/wp-cli-readiness-check.sh
```

For running a toolkit script from the WP-CLI container:

```bash
docker compose --profile cli run --rm \
  -v ~/projects/wp-rescue-toolkit/bin:/toolkit:ro \
  wp-cli sh -lc '/toolkit/wp-db-size-check.sh /var/www/html'
```

Adjust service names and paths for the actual Docker Compose project.

## Existing WP-CLI vs installable WP-CLI

There are three different states:

| State | Meaning |
| --- | --- |
| WP-CLI already available | `wp` command exists and can be used |
| WP-CLI not installed but likely installable | PHP CLI and download tools exist, and an install path is writable |
| WP-CLI not readily available | missing PHP CLI, missing download tools, missing permissions, or incompatible environment |

The safest option depends on the server.

### Existing WP-CLI

If WP-CLI already exists, confirm:

```bash
wp --info
wp core version --path=/path/to/wordpress
```

Do not assume it works for the target site until it can read that installation.

### Dedicated WP-CLI container

If a Docker WP-CLI container exists, prefer using it instead of modifying the web container.

This is often the cleanest approach.

### User-local install

If the server is not containerized and global install is not appropriate, a user-local install may be safer.

Typical locations include:

- `$HOME/bin`
- `$HOME/.local/bin`

Do not install without understanding the server policy.

### System-wide install

A system-wide install may use:

- `/usr/local/bin/wp`

This may be appropriate when you control the server, but it changes the server environment.

## Safe WP-CLI commands

These commands are generally read-only or low-risk when used carefully:

```bash
wp --info
wp core version --path=/path/to/wordpress
wp plugin list --path=/path/to/wordpress
wp theme list --path=/path/to/wordpress
wp db size --path=/path/to/wordpress
wp option get siteurl --path=/path/to/wordpress
wp option get home --path=/path/to/wordpress
```

Even read-only commands should be run against the correct path.

## Commands that require extra caution

Use caution with:

```bash
wp plugin update --all
wp theme update --all
wp core update
wp search-replace
wp db optimize
wp db repair
wp option delete
wp transient delete --all
wp post delete
wp user delete
```

These commands can change the site.

Before running them:

1. Confirm backup.
2. Confirm target site.
3. Confirm command scope.
4. Prefer staging when possible.
5. Record the command and result.

## Safe next actions

### If WP-CLI is already available

Recommended next steps:

1. Confirm it can read the target WordPress installation.
2. Save `wp --info`.
3. Confirm backup readiness.
4. Run read-only checks first.
5. Use database or plugin/theme review scripts as needed.

### If WP-CLI is missing but a CLI container exists

Recommended next steps:

1. Use the CLI container.
2. Confirm it shares the same WordPress files.
3. Confirm it can connect to the same database.
4. Run read-only checks first.
5. Avoid modifying the web container unnecessarily.

### If WP-CLI is missing and may be installable

Recommended next steps:

1. Confirm PHP CLI.
2. Confirm PHP version.
3. Confirm `curl` or `wget`.
4. Confirm writable install path.
5. Confirm server policy.
6. Install only with approval.
7. Test with `wp --info`.

### If WP-CLI is not available

Recommended next steps:

1. Use non-WP-CLI scripts where possible.
2. Use hosting control panel or phpMyAdmin for read-only checks.
3. Use manual SQL carefully.
4. Ask hosting provider for access if needed.
5. Avoid destructive database work.

## Client-facing summary

Example when WP-CLI is available:

```text
WP-CLI is available and can read the WordPress installation. This allows safer command-line inspection of plugins, themes, database size, and selected WordPress settings before making changes.
```

Example when WP-CLI is missing but not blocking:

```text
WP-CLI is not installed in the current web environment. This does not necessarily block the work, but it limits deeper WordPress and database inspection. If the server supports it, we can use a dedicated WP-CLI container or install WP-CLI in a controlled way.
```

Example for Docker:

```text
This Docker setup separates the web container and WP-CLI container. That is a clean design: the web container serves WordPress, while the WP-CLI container is used only for maintenance commands against the same WordPress files and database.
```

## Related scripts

- `bin/wp-cli-readiness-check.sh`
- `bin/wp-db-size-check.sh`
- `bin/wp-backup-check.sh`
- `bin/wp-performance-audit.sh`
- `bin/wp-restore-readiness-check.sh`

## Related documents

- `docs/wordpress-response-playbook.md`
- `docs/playbooks/mysql-database-issue.md`
- `docs/playbooks/slow-site-performance.md`
- `docs/wp-backup-restore.md`
- `docs/wp-performance-audit.md`
- `docs/wp-emergency-response-workflow.md`

## Important limitation

This playbook checks WP-CLI readiness and safe usage patterns.

It does not automatically install WP-CLI, modify the server, update WordPress, repair the database, or guarantee that WP-CLI commands are safe for every site. Always confirm backups and command scope before making changes.
