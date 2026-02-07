#!/bin/bash
set -e

# Wait for database to be ready
echo "Waiting for database..."
until nc -z "$EW_DB_HOST" "$EW_DB_PORT"; do
  sleep 1
done
echo "Database is up!"

# Create and migrate database if needed
echo "Running migrations..."
bundle exec rake db:create 2>/dev/null || true
bundle exec rake db:migrate
bundle exec rake widgets:migrate_all

# Start application
echo "Starting Puma..."
exec bundle exec puma -b tcp://0.0.0.0:9292 -e production
