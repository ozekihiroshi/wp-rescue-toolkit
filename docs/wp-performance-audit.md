# WordPress Performance Audit

This document describes a lightweight WordPress performance audit workflow for rescue, maintenance, migration, and optimization projects.

The goal is not to automatically optimize the site.  
The goal is to collect practical indicators that help identify common bottlenecks before proposing changes.

## Purpose

WordPress performance issues can come from many layers:

- Hosting environment
- PHP configuration
- Database size and queries
- Plugin count and plugin behavior
- Theme behavior
- Cache configuration
- Media files
- Cron behavior
- External services
- Malware or injected code

A safe performance audit starts with observation, not immediate changes.

## Related script

```bash
./bin/wp-performance-audit.sh /path/to/wordpress
```

Example:

```bash
./bin/wp-performance-audit.sh /var/www/html
```

The script is read-only. It does not modify files, databases, plugins, themes, cache files, or WordPress settings.

## What the script checks

The basic performance audit script checks:

| Area | Examples |
| --- | --- |
| WordPress root | `wp-config.php`, `wp-content`, core files |
| Runtime | PHP version, MySQL/MariaDB client, WP-CLI availability |
| Disk usage | Current filesystem usage |
| Directory size | `wp-content`, `uploads`, `plugins`, `themes` |
| Plugin/theme inventory | Number of plugins and themes |
| Cache indicators | `object-cache.php`, `advanced-cache.php`, common cache plugins |
| Debug/log indicators | `wp-content/debug.log`, `WP_DEBUG`, `WP_CACHE` |
| Uploads | Large files over 10MB |
| WP-CLI optional checks | WordPress version, active plugin count, database size |

## Minimum performance audit checklist

Before proposing performance changes, check:

- [ ] WordPress root path.
- [ ] PHP version.
- [ ] MySQL/MariaDB version.
- [ ] Disk usage.
- [ ] `wp-content` size.
- [ ] `uploads` size.
- [ ] Plugin count.
- [ ] Active plugin count, if WP-CLI is available.
- [ ] Theme count.
- [ ] Cache plugin presence.
- [ ] Object cache presence.
- [ ] Page cache drop-in presence.
- [ ] `debug.log` size.
- [ ] Whether `WP_DEBUG` is enabled.
- [ ] Whether `WP_CACHE` is enabled.
- [ ] Large files in uploads.
- [ ] Database size, if WP-CLI is available.
- [ ] Server CPU, memory, and web server logs when server access is available.
- [ ] Frontend speed using browser-based tools separately.

## Common bottleneck categories

### Hosting and server resources

Symptoms:

- Slow response even for simple pages
- High CPU usage
- High memory usage
- Disk nearly full
- Slow database connection
- Frequent 502/503/504 errors

Possible causes:

- Undersized hosting plan
- Insufficient PHP workers
- Low memory limit
- Slow disk I/O
- No opcode cache
- Overloaded shared hosting
- Misconfigured PHP-FPM, Apache, or Nginx

### Plugin load

Symptoms:

- Admin dashboard is slow
- Frontend pages are slow even with simple themes
- Slow AJAX requests
- Many external scripts
- High database query count

Possible causes:

- Too many active plugins
- Overlapping plugins
- Heavy page builder usage
- Security plugins scanning too aggressively
- Backup plugins running during traffic hours
- Statistics or analytics plugins storing large data locally

### Database growth

Symptoms:

- Slow admin pages
- Slow search
- Slow product/order/user screens
- Large backup files
- Slow migration

Possible causes:

- Large `wp_options`
- Large autoloaded options
- Large `wp_postmeta`
- Old transients
- Revision buildup
- WooCommerce order/meta growth
- Form submission tables
- Plugin log tables

### Media and uploads

Symptoms:

- Slow page load
- Large backup size
- Slow migration
- High storage usage
- Poor mobile performance

Possible causes:

- Uncompressed images
- Very large original uploads
- Unused generated thumbnails
- Video files stored directly in WordPress
- PDF or archive files stored in uploads

### Cache configuration

Symptoms:

- Repeated slow full-page generation
- High database load during traffic spikes
- Inconsistent cache behavior
- Logged-in users are slow
- Cache not working after migration

Possible causes:

- No page cache
- No object cache
- Cache plugin installed but not configured
- Cache disabled by `DONOTCACHEPAGE`
- Logged-in traffic bypasses cache
- Cache conflicts with theme or plugins
- CDN and site cache not aligned

### Debug and logging

Symptoms:

- Large `debug.log`
- Disk usage grows unexpectedly
- Hidden PHP warnings
- Slow file writes

Possible causes:

- `WP_DEBUG` enabled in production
- Repeated PHP notices or warnings
- Plugin compatibility issues
- Theme errors
- Log files not rotated

## WP-CLI checks

If WP-CLI is available, useful checks include:

```bash
wp core version
wp plugin list
wp plugin list --status=active
wp theme list
wp db size --human-readable
wp option list --autoload=on
```

For deeper database review:

```bash
wp db query "SHOW TABLE STATUS;"
wp db query "SELECT option_name, LENGTH(option_value) AS size FROM wp_options WHERE autoload = 'yes' ORDER BY size DESC LIMIT 20;"
```

Adjust the table prefix if the site does not use `wp_`.

## Frontend performance checks

This toolkit focuses on server-side and file-level indicators.  
Frontend speed should also be checked separately.

Useful frontend review points:

- Time to first byte
- Largest Contentful Paint
- Total Blocking Time
- Cumulative Layout Shift
- Image size
- Render-blocking CSS/JS
- Third-party scripts
- Font loading
- CDN behavior
- Cache headers
- Redirect chain

## Performance readiness levels

### Good

The site is likely in a healthy baseline state when:

- Disk usage is not near full.
- PHP version is supported by the site.
- Plugin count is moderate.
- Cache indicators are present and intentional.
- `debug.log` is absent or small.
- Uploads are not unexpectedly large.
- Database size is reasonable for the site type.
- No obvious error/log growth is visible.

### Needs review

The site should be reviewed more carefully when:

- Plugin count is high.
- `debug.log` exists and is growing.
- Uploads are very large.
- Cache drop-ins are missing or unclear.
- WP-CLI is unavailable and database size cannot be checked.
- Disk usage is increasing.
- The site uses page builders, WooCommerce, LMS, booking, or membership plugins.

### High risk

Optimization should be handled carefully when:

- Disk is nearly full.
- The site has no verified backup.
- `WP_DEBUG` is enabled in production.
- Large logs indicate repeated PHP errors.
- Database tables are very large.
- Cache plugins conflict.
- The site handles orders, payments, bookings, or memberships.
- The site may be infected or has suspicious code.

## Safe optimization workflow

1. Confirm backup and restore readiness.
2. Run the basic performance audit.
3. Save the report.
4. Identify obvious risks.
5. Check server resource usage.
6. Check frontend performance separately.
7. Prioritize low-risk improvements.
8. Test on staging when possible.
9. Apply one change at a time.
10. Re-test after each change.

## Low-risk first improvements

Common low-risk improvements include:

- Remove unused plugins after backup.
- Disable duplicate functionality.
- Clear expired transients carefully.
- Configure page cache.
- Configure object cache when supported.
- Compress large images.
- Review `debug.log`.
- Disable production debug logging.
- Move large videos or downloads outside WordPress hosting.
- Schedule backups and scans outside peak hours.

## What not to do first

Avoid starting with aggressive changes such as:

- Deleting database tables without identifying ownership.
- Deleting uploads without confirming usage.
- Disabling many plugins at once on a live site.
- Changing PHP versions without compatibility review.
- Replacing cache plugins without testing.
- Running mass search-replace without a backup.
- Optimizing database tables during peak traffic.
- Restoring an old database over a live dynamic site.

## Example command

```bash
./bin/wp-performance-audit.sh /var/www/html > performance-audit-report.txt
```

## Important limitation

This audit does not measure real page speed by itself.

It provides a structured server-side and WordPress file-level review to support safer performance troubleshooting and client recommendations.
