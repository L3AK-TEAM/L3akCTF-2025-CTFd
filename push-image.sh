#!/bin/bash
set -euo pipefail

IMAGE_NAME="ctfd"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
TAG=$(git rev-parse --short HEAD)
GCR_IMAGE_LATEST="gcr.io/$PROJECT_ID/$IMAGE_NAME:latest"

echo "[+] Building and pushing Docker image for linux/amd64: $GCR_IMAGE_LATEST"
docker buildx build --platform linux/amd64 -t "$GCR_IMAGE_LATEST" --push .

echo "[+] Images pushed: $GCR_IMAGE_LATEST"
