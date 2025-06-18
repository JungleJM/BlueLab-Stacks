#!/bin/sh

# BlueLab Database Backup Script

BACKUP_DIR="/backups/database"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL
echo "Starting PostgreSQL backup..."
pg_dump -h postgres -U ${POSTGRES_USER:-bluelab} ${POSTGRES_DB:-bluelab} | gzip > "$BACKUP_DIR/postgres_${TIMESTAMP}.sql.gz"

# Backup Redis (if running)
echo "Starting Redis backup..."
if redis-cli -h redis ping > /dev/null 2>&1; then
    redis-cli -h redis --rdb "$BACKUP_DIR/redis_${TIMESTAMP}.rdb"
    gzip "$BACKUP_DIR/redis_${TIMESTAMP}.rdb"
fi

# Clean up old backups (keep last 7 days)
find "$BACKUP_DIR" -name "*.gz" -mtime +7 -delete

echo "Database backup completed: $TIMESTAMP"