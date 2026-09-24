#!/usr/bin/env bash
set -e

timestamp=$(date +%Y-%m-%d_%H-%M-%S)

# Backup Docmost/Kaneo DBs and Home Assistant config to NAS/backup/homelab

echo "Backing up Docmost & Kaneo databases."

ssh server@thinkcentre "
  mkdir -p /mnt/nas_backup/homelab/{docmost,kaneo}

  docker exec docmost-postgres pg_dump -U docmost docmost \
    > /mnt/nas_backup/homelab/docmost/docmost-${timestamp}.sql

  docker exec kaneo-postgres pg_dump -U kaneo kaneo \
    > /mnt/nas_backup/homelab/kaneo/kaneo-${timestamp}.sql
"

echo "Database backups complete."

# Backup Home Assistant configs

echo "Backing up Home Assistant config."

ssh server@thinkcentre "
  mkdir -p /mnt/nas_backup/homelab/home-assistant

  docker exec home-assistant \
    tar -C /config -czf - . \
    > /mnt/nas_backup/homelab/home-assistant/config-${timestamp}.tar.gz
"

echo "Home Assistant backup complete."