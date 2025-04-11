#!/bin/bash
set -euo pipefail

zero_downtime_deploy() {
  service_name=${SERVICE_NAME:-app}
  echo "$(date) - Using service name: $service_name"

  # Ensure letsencrypt directory exists
  echo "Creating acme.json if it doesn't exist..."
  mkdir -p letsencrypt
  touch letsencrypt/acme.json
  chmod 600 letsencrypt/acme.json

  # Start Traefik if not running
  echo "Starting Traefik (if not running)..."
  docker compose up -d traefik || {
    echo "Failed to start Traefik"
    exit 1
  }

  # Get current container ID
  echo "Getting current container ID..."
  old_container_id=$(docker ps -f name=$service_name -q | tail -n1)

  # Scale up for zero-downtime
  echo "Scaling up to 2 for zero-downtime..."
  IMAGE_NAME=$IMAGE_NAME IMAGE_TAG=$IMAGE_TAG docker compose up -d \
    --no-deps \
    --scale $service_name=2 \
    --no-recreate $service_name || {
    echo "Failed to scale up"
    exit 1
  }

  # Wait for new container to be healthy
  echo "Waiting for a new container to be healthy..."
  new_container_id=$(docker ps -f name=$service_name -q | head -n1)
  new_container_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $new_container_id)

  # Health check (adjust port as needed)
  echo "Performing health check..."
  curl --include --retry-connrefused --retry 30 --retry-delay 1 --fail http://$new_container_ip:3000/ || {
    echo "Health check failed"
    exit 1
  }

  # Stop old container if exists
  if [ -n "$old_container_id" ]; then
    echo "Stopping old container: $old_container_id"
    docker stop $old_container_id || true
    docker rm $old_container_id || true
  fi

  # Scale back to 1
  echo "Scaling back to 1 container..."
  IMAGE_NAME=$IMAGE_NAME IMAGE_TAG=$IMAGE_TAG docker compose up -d \
    --no-deps \
    --scale $service_name=1 \
    --no-recreate $service_name || {
    echo "Failed to scale down"
    exit 1
  }

  echo "$(date) - Zero-downtime deployment completed ✅"

  # Cleanup
  echo "Cleaning up unused Docker images..."
  docker image prune -a -f
}

zero_downtime_deploy