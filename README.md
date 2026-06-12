# WP Rescue Toolkit

A practical diagnostic toolkit for WordPress recovery, migration, VPS troubleshooting, Docker issues, DNS/SSL checks, and basic security triage.

This toolkit is designed for the first stage of WordPress support work.

It helps answer simple but important questions:

- Is the server healthy enough?
- Is Docker running correctly?
- Is the domain pointing to the right server?
- Is HTTPS working?
- Is the WordPress site reachable?
- Are there obvious security or malware warning signs?
- Are there basic performance, security, or UX issues?

The tools are intentionally conservative and non-destructive.

They do not delete files.  
They do not change WordPress settings.  
They do not replace a full professional audit.

They help collect useful information before deeper recovery, migration, cleanup, or optimization work.

---

## WordPress Response Playbook

This toolkit includes a practical WordPress response playbook for non-destructive first-response workflows:

- [WordPress Response Playbook](docs/wordpress-response-playbook.md)
- [Backup and Restore Readiness](docs/playbooks/backup-restore-readiness.md)
- [Site Down](docs/playbooks/site-down.md)
- [Slow Site Performance](docs/playbooks/slow-site-performance.md)
- [MySQL Database Issue](docs/playbooks/mysql-database-issue.md)
- [WP-CLI Readiness](docs/playbooks/wp-cli-readiness.md)
- [Malware Suspicion](docs/playbooks/malware-suspicion.md)
- [Migration and Update Readiness](docs/playbooks/migration-update-readiness.md)

## Why This Toolkit Exists

Many WordPress support requests start with unclear information.

Examples:

- "My WordPress site is down."
- "The site is slow."
- "The migration failed."
- "SSL is not working."
- "The VPS disk is full."
- "Docker containers are stuck."
- "The host says malware was detected."
- "I took over a site from another freelancer."

Before making changes, it is useful to run a safe first check.

This toolkit provides that first check.

---

## Current Tools

### 1. `wp-rescue-check.sh`

Basic VPS / Docker / DNS / SSL check.

It checks:

- host and OS information
- disk usage
- memory and swap
- Docker daemon status
- Docker Compose version
- running and stopped containers
- Docker disk usage
- listening ports
- DNS resolution
- HTTP response
- HTTPS response

Example:

```bash
./bin/wp-rescue-check.sh wp.example.com
```

---

### 2. `wp-site-audit.sh`

Basic external WordPress site audit.

It checks the public side of a website.

It checks:

- DNS resolution
- HTTP to HTTPS redirect
- HTTPS status
- response time
- page size
- security headers
- cache and compression headers
- common WordPress endpoints
- basic HTML metadata

Example:

```bash
./bin/wp-site-audit.sh https://wp.example.com
```

Documentation:

```text
docs/wp-site-audit.md
```

---

### 3. `wp-malware-triage.sh`

Non-destructive WordPress file-system malware triage.

It checks for possible infection indicators.

It checks:

- whether the target path looks like a WordPress site
- PHP files under `wp-content/uploads`
- recently modified PHP files
- suspicious PHP patterns
- `.htaccess` files
- useful WP-CLI follow-up commands

Example:

```bash
./bin/wp-malware-triage.sh /var/www/html
```

Docker example:

```bash
docker cp bin/wp-malware-triage.sh wp-rescue:/tmp/wp-malware-triage.sh
docker exec -it wp-rescue bash /tmp/wp-malware-triage.sh /var/www/html
```

Documentation:

```text
docs/wp-malware-triage.md
```

---

## Use Cases

This toolkit is useful for:

- WordPress migration checks
- VPS disk-space troubleshooting
- Docker-based WordPress troubleshooting
- Traefik / Nginx / reverse proxy checks
- DNS and SSL checks
- site-down investigation
- pre-migration review
- inherited WordPress site review
- basic security baseline checks
- suspected malware first triage
- client support preparation

---

## Quick Start

Clone the repository:

```bash
git clone https://github.com/ozekihiroshi/wp-rescue-toolkit.git
cd wp-rescue-toolkit
```

Make scripts executable:

```bash
chmod +x bin/*.sh
```

Run a basic server and site check:

```bash
./bin/wp-rescue-check.sh wp.example.com
```

Run a public site audit:

```bash
./bin/wp-site-audit.sh https://wp.example.com
```

Run a WordPress malware triage check:

```bash
./bin/wp-malware-triage.sh /path/to/wordpress
```

---

## Example Workflow

A safe first workflow for WordPress support work:

```text
1. Check the server and Docker status
2. Check DNS and HTTPS
3. Check the public website response
4. Check basic security headers
5. Check common WordPress endpoints
6. If file access is available, run malware triage
7. Review warnings manually
8. Make a recovery, migration, cleanup, or optimization plan
```

Example commands:

```bash
./bin/wp-rescue-check.sh wp.example.com
./bin/wp-site-audit.sh https://wp.example.com
./bin/wp-malware-triage.sh /var/www/html
```

---

## Output Levels

The tools use simple output levels.

### `[OK]`

The check looks good.

### `[WARN]`

The item should be reviewed.

A warning does not always mean a serious problem.

### `[FAIL]`

An important check failed.

### `[INFO]`

Useful context or next steps.

---

## Safety Policy

These tools are designed to be safe first-check tools.

They do not:

- delete files
- modify files
- change WordPress settings
- update WordPress
- update plugins
- update themes
- clean malware automatically
- guarantee that a site is safe
- replace a full security audit
- replace a full performance audit

Always take a backup before making changes to a client site.

---

## WordPress Malware Triage Policy

`wp-malware-triage.sh` is not a malware remover.

It is useful not only for known malware cases, but also as a light pre-migration or pre-recovery check for inherited WordPress sites.

It helps find obvious warning signs such as:

- PHP files under `wp-content/uploads`
- recently modified PHP files
- suspicious PHP patterns
- unusual `.htaccess` rules

Important:

- `WARN` does not mean confirmed infection.
- `OK` does not prove that the site is clean.
- Manual review is required.
- Full malware cleanup should be handled carefully.

---

## Site Audit Policy

`wp-site-audit.sh` is not a full performance or security audit.

It is a baseline check.

It helps collect practical information before improving a WordPress site.

It is useful when a client asks for:

- performance improvement
- security improvement
- user experience improvement
- WordPress cleanup
- pre-migration review

For deeper audits, use additional tools such as:

- browser developer tools
- Lighthouse
- PageSpeed Insights
- server logs
- WordPress plugin profiling
- WAF logs
- manual code review

---

## Repository Structure

```text
wp-rescue-toolkit/
├── bin/
│   ├── wp-rescue-check.sh
│   ├── wp-site-audit.sh
│   └── wp-malware-triage.sh
├── docs/
│   ├── wp-site-audit.md
│   └── wp-malware-triage.md
├── examples/
│   └── docker-compose.wp-rescue.example.yml
├── README.md
└── README-jp.md
```

---

## Related Lab Site

WP Rescue Lab is a live test and demonstration environment for this toolkit.

```text
https://wp.ceri.link
```

The lab is used to test:

- Docker-based WordPress deployment
- Traefik routing
- HTTPS / Let's Encrypt
- WordPress multilingual setup
- site audit checks
- malware triage workflow
- recovery and migration documentation

---

## Example Docker / Traefik Note

When using Traefik with a WordPress container connected to multiple Docker networks, specify the Traefik network explicitly.

Example:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=demand-monitor_web"
```

Without this, Traefik may choose the wrong network and return a gateway timeout.

---

## Requirements

The scripts are written for Linux-like environments.

Basic requirements:

- Bash
- curl
- grep
- sed
- awk
- common Linux utilities

Optional:

- Docker
- Docker Compose
- WP-CLI

Some checks require SSH access to the server.

On shared hosting environments, some scripts may not be usable if SSH access is not available.

---

## Current Status

Early development.

The toolkit currently focuses on first-stage diagnosis.

It is not a complete recovery platform yet.

Current focus:

- practical shell scripts
- clear reports
- non-destructive checks
- WordPress support workflows
- documentation for real-world support cases

---

## Roadmap

Possible future improvements:

- Markdown report output
- JSON report output
- sample reports
- batch domain checks
- TLS certificate expiry checks
- redirect chain details
- Docker Compose project detection
- WordPress container auto-detection
- WP-CLI integration
- database safety checks
- plugin and theme audit helpers
- client-friendly summary reports
- recovery checklists

---

## Professional Use

This toolkit can be used before contacting a developer or freelancer.

You can run a basic check and share the result.

However, this toolkit is provided as-is.

I cannot guarantee free support for every report.

For professional review, migration, cleanup, or recovery work, please contact me separately.

---

## License

To be decided.

---

## Author

Hiroshi Ozeki

GitHub:

```text
https://github.com/ozekihiroshi
```