#!/bin/bash
set -euo pipefail

# --- CONFIG ---
INFRA_DIR="../L3akCTF-Infra/terraform"
IMAGE_NAME="ctfd"
PROJECT_ID=$(terraform -chdir="$INFRA_DIR" output -raw project_id 2>/dev/null || echo "<your-project-id>")
REGION=$(terraform -chdir="$INFRA_DIR" output -raw region 2>/dev/null || echo "us-central1")
TAG=$(git rev-parse --short HEAD)
GCR_IMAGE="gcr.io/$PROJECT_ID/$IMAGE_NAME:$TAG"
CLOUD_RUN_SERVICE="main-cloudrun"

# --- 1. Build and push Docker image ---
echo "[+] Building Docker image: $GCR_IMAGE"
docker build -t "$GCR_IMAGE" .
echo "[+] Pushing Docker image to GCR"
docker push "$GCR_IMAGE"

# --- 2. Terraform apply ---
echo "[+] Running terraform apply in $INFRA_DIR"
cd "$INFRA_DIR"
terraform init
terraform apply -auto-approve
cd -

# --- 3. Extract outputs from Terraform ---
echo "[+] Extracting Terraform outputs"
DB_USER=$(terraform -chdir="$INFRA_DIR" output -raw db_user)
DB_PASSWORD=$(terraform -chdir="$INFRA_DIR" output -raw db_password)
DB_NAME=$(terraform -chdir="$INFRA_DIR" output -raw db_name)
DB_HOST=$(terraform -chdir="$INFRA_DIR" output -raw sql_private_ip)
REDIS_HOST=$(terraform -chdir="$INFRA_DIR" output -raw redis_host)
BUCKET_NAME=$(terraform -chdir="$INFRA_DIR" output -raw bucket_name 2>/dev/null || terraform -chdir="$INFRA_DIR" output -raw bucket_url)
CLOUD_RUN_URL=$(terraform -chdir="$INFRA_DIR" output -raw cloud_run_url)

# --- 4. Deploy to Cloud Run ---
echo "[+] Deploying to Cloud Run: $CLOUD_RUN_SERVICE"
gcloud run deploy "$CLOUD_RUN_SERVICE" \
  --image "$GCR_IMAGE" \
  --region "$REGION" \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars "DATABASE_URL=mysql+pymysql://$DB_USER:$DB_PASSWORD@$DB_HOST:3306/$DB_NAME,REDIS_URL=redis://$REDIS_HOST:6379/0,BUCKET_NAME=$BUCKET_NAME,UPLOAD_PROVIDER=filesystem" \
  --quiet

echo "[+] Deployment complete!"
echo "Cloud Run URL: $CLOUD_RUN_URL"
