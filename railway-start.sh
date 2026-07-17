#!/bin/bash
set -e

echo "Starting Open Connect..."
docker compose -f docker-compose.railway.yaml up -d

echo "Waiting for service to be ready..."
for i in {1..30}; do
  if curl -sf http://localhost:8080/ready > /dev/null 2>&1; then
    echo "Open Connect is ready!"
    exit 0
  fi
  echo "Waiting ($i/30)..."
  sleep 5
done

echo "Service did not start in time"
exit 1