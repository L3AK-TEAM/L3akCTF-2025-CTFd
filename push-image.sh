#!/bin/bash
set -euo pipefail

IMAGE_NAME="ctfd"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
TAG=$(git rev-parse --short HEAD)
GCR_IMAGE="gcr.io/$PROJECT_ID/$IMAGE_NAME:$TAG"

echo "[+] Building Docker image: $GCR_IMAGE"
docker build -t "$GCR_IMAGE" .
echo "[+] Pushing Docker image to GCR"
docker push "$GCR_IMAGE"
echo "[+] Image pushed: $GCR_IMAGE"
echo "$GCR_IMAGE"
