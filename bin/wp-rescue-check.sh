#!/usr/bin/env bash
set -u

TARGET_DOMAIN="${1:-}"

echo "=== WP Rescue Check ==="
echo

echo "## Host"
hostname
date
uptime
echo

echo "## OS"
if [ -f /etc/os-release ]; then
  cat /etc/os-release | grep -E '^(NAME|VERSION)='
fi
echo

echo "## Disk Usage"
df -h /
echo

echo "## Memory"
free -h
echo

echo "## Docker"
if command -v docker >/dev/null 2>&1; then
  docker --version
  docker compose version 2>/dev/null || true
  systemctl is-active docker 2>/dev/null || true
else
  echo "docker command not found"
fi
echo

echo "## Docker Containers"
docker ps -a 2>/dev/null || true
echo

echo "## Docker Disk Usage"
docker system df 2>/dev/null || true
echo

echo "## Listening Ports"
ss -lntp 2>/dev/null | grep -E ':80|:443|:8080|:3306' || true
echo

if [ -n "$TARGET_DOMAIN" ]; then
  echo "## DNS"
  getent hosts "$TARGET_DOMAIN" || true
  echo

  echo "## HTTP"
  curl -I --max-time 10 "http://${TARGET_DOMAIN}" || true
  echo

  echo "## HTTPS"
  curl -I --max-time 15 "https://${TARGET_DOMAIN}" || true
  echo
else
  echo "## Domain Check"
  echo "No domain specified."
  echo "Usage: ./bin/wp-rescue-check.sh example.com"
fi

echo
echo "=== Done ==="
