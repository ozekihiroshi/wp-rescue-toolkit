# WordPress Update Readiness Workflow

**Prepared by Hiroshi Ozeki**  
Practical workflow for planning and carrying out a careful WordPress core, theme, plugin, and PHP compatibility update.

---

## Purpose

This document outlines a structured approach for updating an older WordPress website while reducing avoidable risk to the live site.

The goal is not to promise zero downtime or guarantee compatibility before inspection. The goal is to assess the current environment, prepare a verified recovery path, make controlled changes, test key functions, and document the outcome.

---

## 1. Initial Assessment

Before any update work begins, review the current website and hosting environment.

Typical checks include:

- Current WordPress core version
- PHP version and available PHP upgrade options
- Active theme, child theme, and custom code
- Active plugins and their update/compatibility status
- WordPress database health and available storage
- Hosting control panel, server access, or managed-hosting limitations
- Existing caching, CDN, security, email, analytics, and form integrations
- Key site functions that must continue working after the update

The assessment identifies high-risk areas before changes are made, especially on older installations with legacy themes, plugins, or custom PHP code.

---

## 2. Backup and Rollback Preparation

A full backup should be created before updating production systems.

The backup scope should include:

- WordPress files
- `wp-content` uploads, themes, plugins, and custom files
- WordPress database export
- Relevant server or hosting configuration where accessible
- A record of current versions, enabled plugins, and important settings

Before proceeding, confirm how the site could be restored if a major issue appears. A backup is useful only when the restoration path is understood and practical.

---

## 3. Compatibility Review and Update Plan

Older WordPress sites often have dependencies that require attention before core updates.

The review should identify:

- Plugins that are abandoned, unsupported, or incompatible with current WordPress/PHP versions
- Themes relying on deprecated WordPress functions or outdated JavaScript libraries
- Custom theme or plugin code that may require PHP compatibility changes
- Required integrations such as contact forms, SMTP, payment, booking, analytics, maps, and membership services
- Whether updates should be tested first in a staging or clone environment

The update plan should define a controlled order, normally beginning with verified backups and environment checks, followed by compatibility-oriented updates and function testing.

---

## 4. Controlled Update Procedure

After the assessment and backup steps are complete, changes should be made carefully and in traceable stages.

A typical sequence is:

1. Place the site in a suitable maintenance or low-risk change window when needed.
2. Confirm backups and rollback materials are available.
3. Update WordPress core in a controlled manner.
4. Update compatible plugins and themes, checking for conflicts after meaningful groups of changes.
5. Apply required PHP compatibility fixes or replace unsupported components where agreed.
6. Clear application, server, and CDN caches as appropriate.
7. Record changes, versions, errors, and corrective actions.

For older sites, a staged approach is safer than treating the work as a single blind update.

---

## 5. Post-Update Functional Testing

After updates, test the site against the functions that matter to visitors and administrators.

Typical checks include:

- Homepage, key landing pages, and navigation
- Mobile layout and responsive behavior
- Contact forms and email delivery
- Login, dashboard, and editor access
- Search, comments, memberships, bookings, e-commerce, or payment workflows where applicable
- Image uploads and media display
- SSL/HTTPS behavior and redirect rules
- Page speed, caching, and obvious browser-console errors
- Error logs or WordPress debug information, where safely available

Any issue found should be documented, isolated, corrected where within scope, and retested.

---

## 6. Completion Report

At the end of the work, provide a concise summary covering:

- Versions updated
- Backup and rollback preparation performed
- Compatibility issues identified and resolved
- Items that could not be updated without further work
- Key functions tested
- Recommendations for remaining maintenance, security, performance, or modernization work

This gives the website owner a clear record of what changed and what should be monitored next.

---

## Practical Principles

- Assess before changing.
- Back up before updating.
- Maintain a practical rollback path.
- Update in controlled stages.
- Test the functions that matter to the business.
- Avoid unnecessary redesign or unrelated changes.
- Communicate constraints and findings clearly.

---

**Note:** The exact scope, estimated effort, and feasible update path depend on the hosting environment, current PHP version, active theme and plugins, customizations, and availability of a staging environment.
