#!/usr/bin/env bash
set -Eeuo pipefail
source /etc/devops-app.conf

IMAGE_URI="$(aws ssm get-parameter --name "$IMAGE_PARAMETER" --query 'Parameter.Value' --output text --region "$AWS_REGION")"
OLD_IMAGE="$(docker inspect --format '{{.Config.Image}}' "$APP_NAME" 2>/dev/null || true)"

aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"
docker pull "$IMAGE_URI"

start_image() {
  local image="$1"
  docker rm -f "$APP_NAME" >/dev/null 2>&1 || true
  docker run -d \
    --name "$APP_NAME" \
    --restart unless-stopped \
    --publish 8000:8000 \
    --log-driver awslogs \
    --log-opt "awslogs-region=${AWS_REGION}" \
    --log-opt "awslogs-group=${LOG_GROUP}" \
    --log-opt "awslogs-stream=$(hostname)" \
    --log-opt awslogs-create-group=false \
    "$image"
}

health_check() {
  local attempt
  for attempt in $(seq 1 45); do
    if curl --fail --silent --show-error http://127.0.0.1:8000/health >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

if start_image "$IMAGE_URI" && health_check; then
  echo "Deployment healthy: ${IMAGE_URI}"
  exit 0
fi

echo "New image failed health validation: ${IMAGE_URI}" >&2
docker logs "$APP_NAME" 2>&1 || true
if [[ -n "$OLD_IMAGE" ]]; then
  echo "Restoring previous image: ${OLD_IMAGE}" >&2
  if start_image "$OLD_IMAGE" && health_check; then
    echo "Previous image restored successfully." >&2
  else
    echo "CRITICAL: previous image could not be restored." >&2
  fi
fi
exit 1
