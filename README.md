# WP Rescue Toolkit

A practical toolkit for diagnosing WordPress, VPS, Docker, Traefik, DNS, SSL, and disk-space issues.

This project is based on a real Docker-based WordPress recovery lab environment.

## Purpose

WP Rescue Toolkit helps investigate common server-side problems around WordPress sites, especially on VPS or cloud instances.

It focuses on:

- disk usage
- memory and swap
- Docker daemon status
- Docker Compose services
- Traefik routing
- DNS and HTTPS checks
- WordPress and database container status

## Status

Early development.

## Repository Structure

```text
bin/
  Diagnostic scripts

docs/
  Recovery notes and case studies

examples/
  Example Docker Compose files
```

## Example

```bash
./bin/wp-rescue-check.sh wp.ceri.link

The script checks:

host and OS information
disk usage
memory and swap
Docker daemon status
running and stopped containers
Docker disk usage
listening ports
DNS resolution
HTTP / HTTPS response

```
## WordPress Malware Triage

This toolkit includes a non-destructive WordPress malware triage script.

```bash
./bin/wp-malware-triage.sh /path/to/wordpress
```

The script helps identify possible infection indicators in a WordPress file system.

It checks:

- whether the target path looks like a WordPress site
- PHP files under `wp-content/uploads`
- recently modified PHP files
- suspicious PHP patterns
- `.htaccess` files
- useful WP-CLI follow-up commands

Example:

```bash
./bin/wp-malware-triage.sh --days 14 /var/www/html
```

For Docker-based WordPress environments:

```bash
docker cp bin/wp-malware-triage.sh wp-rescue:/tmp/wp-malware-triage.sh
docker exec -it wp-rescue bash /tmp/wp-malware-triage.sh /var/www/html
```

Important:

This script does not remove malware.  
It does not modify files.  
It does not prove that a site is clean.

It is a first triage tool for collecting information before manual review or cleanup.

See:

```text
docs/wp-malware-triage.md
```