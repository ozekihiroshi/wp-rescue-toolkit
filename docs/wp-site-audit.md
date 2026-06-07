# WordPress Site Audit

`wp-site-audit.sh` is a basic external audit script for WordPress sites.

It checks the public side of a website.

It focuses on:

- HTTP and HTTPS behavior
- response status
- response time
- page size
- basic security headers
- common WordPress endpoints
- basic HTML metadata for user experience

This script is useful before WordPress improvement work.

It is also useful before discussing performance, security, or user experience issues with a client.

## Purpose

Many WordPress improvement requests are broad.

For example:

- "Please improve my WordPress site."
- "Please improve performance."
- "Please improve security."
- "Please improve user experience."
- "The site feels slow."
- "I want a better WordPress setup."

Before making changes, it is useful to collect a baseline report.

This script gives a simple first report.

It does not replace a full audit.

## What This Script Does

The script checks a target domain or URL from the outside.

Example:

```bash
./bin/wp-site-audit.sh example.com
```