#!/bin/bash

# Google Cloud Run One-Click Deployment Script
# Care Connect - Client Instance Deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration (will be replaced by actual values during package generation)
CLIENT_NAME="blue cross home care ltd"
DOMAIN_NAME="bluecrosshomecareltd"
PROJECT_ID="bluecrosshomecare-careconnect"
INSTANCE_ID="74b6fc3f-9c07-4e23-b2a5-f8c0fa7191ee"
LICENSE_KEY="8e30afee-7c07-424d-8a59-6e735eaaaf77"
DB_PASSWORD=".lxu7v8621hb"
JWT_SECRET="0.bygkqob866"

echo -e "${BLUE}🚀 Care Connect Cloud Run Deployment${NC}"
echo -e "${BLUE}Client: ${CLIENT_NAME}${NC}"
echo -e "${BLUE}Domain: ${DOMAIN_NAME}${NC}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI not found. Please install Google Cloud CLI first.${NC}"
    echo "Visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}🔐 Please authenticate with Google Cloud...${NC}"
    gcloud auth login
fi

echo -e "${YELLOW}⚙️  Setting up Google Cloud project...${NC}"

# Create project
gcloud projects create $PROJECT_ID --name="$CLIENT_NAME Care Connect" 2>/dev/null || true
gcloud config set project $PROJECT_ID

# Enable billing (user needs to link billing account manually)
echo -e "${YELLOW}💳 Please ensure billing is enabled for project: $PROJECT_ID${NC}"
echo "Visit: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
read -p "Press Enter when billing is enabled..."

echo -e "${YELLOW}🔧 Enabling required APIs...${NC}"
gcloud services enable \
    run.googleapis.com \
    sql-component.googleapis.com \
    sqladmin.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com \
    dns.googleapis.com \
    compute.googleapis.com

echo -e "${YELLOW}🔐 Creating secrets...${NC}"
echo -n "$DB_PASSWORD" | gcloud secrets create db-password --data-file=- || true
echo -n "$JWT_SECRET" | gcloud secrets create jwt-secret --data-file=- || true
echo -n "$LICENSE_KEY" | gcloud secrets create license-key --data-file=- || true

# Create service account for Cloud Run
echo -e "${YELLOW}👤 Creating service account...${NC}"
gcloud iam service-accounts create $PROJECT_ID-cloudrun \
    --display-name="Care Connect Cloud Run Service Account" || true

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$PROJECT_ID-cloudrun@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$PROJECT_ID-cloudrun@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"

echo -e "${YELLOW}🗄️  Setting up Cloud SQL database...${NC}"
# Create Cloud SQL instance
gcloud sql instances create $PROJECT_ID-db \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=us-central1 \
    --storage-type=HDD \
    --storage-size=30GB \
    --backup-start-time=03:00 \
    --maintenance-release-channel=production \
    --maintenance-window-day=SUN \
    --maintenance-window-hour=4 \
    --no-assign-ip \
    --network=default || true

# Set database password
gcloud sql users set-password postgres \
    --instance=$PROJECT_ID-db \
    --password="$DB_PASSWORD" || true

# Create application database
gcloud sql databases create careconnect --instance=$PROJECT_ID-db || true

# Create application user
gcloud sql users create careconnect \
    --instance=$PROJECT_ID-db \
    --password="$DB_PASSWORD" || true

# Get database connection name
DB_CONNECTION_NAME=$(gcloud sql instances describe $PROJECT_ID-db --format="value(connectionName)")

echo -e "${YELLOW}🏗️  Building and deploying application...${NC}"

# Build container image
gcloud builds submit --tag gcr.io/$PROJECT_ID/care-connect .

# Deploy to Cloud Run
gcloud run deploy care-connect \
    --image gcr.io/$PROJECT_ID/care-connect \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated \
    --port 3000 \
    --memory 512Mi \
    --cpu 1 \
    --concurrency 80 \
    --max-instances 10 \
    --service-account $PROJECT_ID-cloudrun@$PROJECT_ID.iam.gserviceaccount.com \
    --add-cloudsql-instances $DB_CONNECTION_NAME \
    --set-env-vars NODE_ENV=production \
    --set-env-vars INSTANCE_ID=$INSTANCE_ID \
    --set-env-vars CLIENT_NAME="$CLIENT_NAME" \
    --set-env-vars CUSTOM_DOMAIN=$DOMAIN_NAME \
    --set-env-vars DATABASE_URL="postgresql://careconnect:$DB_PASSWORD@localhost/careconnect?host=/cloudsql/$DB_CONNECTION_NAME" \
    --set-secrets JWT_SECRET=jwt-secret:latest \
    --set-secrets LICENSE_KEY=license-key:latest

# Get service URL
SERVICE_URL=$(gcloud run services describe care-connect --platform managed --region us-central1 --format "value(status.url)")

echo -e "${YELLOW}🌐 Setting up custom domain...${NC}"

# Create DNS zone if it doesn't exist
DOMAIN_ZONE=$(echo $DOMAIN_NAME | tr '.' '-')
gcloud dns managed-zones create $DOMAIN_ZONE-zone \
    --description="DNS zone for $DOMAIN_NAME" \
    --dns-name=$DOMAIN_NAME || true

# Map custom domain to Cloud Run
gcloud run domain-mappings create \
    --service care-connect \
    --domain $DOMAIN_NAME \
    --region us-central1 || true

echo -e "${YELLOW}⏳ Waiting for SSL certificate provisioning...${NC}"
echo "This may take 5-10 minutes..."

# Wait for domain mapping to be ready
while true; do
    STATUS=$(gcloud run domain-mappings describe --domain $DOMAIN_NAME --region us-central1 --format="value(status.conditions[0].status)" 2>/dev/null || echo "False")
    if [ "$STATUS" = "True" ]; then
        break
    fi
    echo -e "${YELLOW}⏳ Still provisioning SSL certificate...${NC}"
    sleep 30
done

echo -e "${YELLOW}🔄 Running database migrations...${NC}"
# Trigger database setup via API call
curl -X POST "$SERVICE_URL/api/setup-database" \
    -H "Content-Type: application/json" \
    -d '{"license_key": "'$LICENSE_KEY'", "setup_key": "initial_setup"}' || true

echo ""
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo -e "${GREEN}🎉 Your Care Connect instance is ready!${NC}"
echo -e "${BLUE}Application URL: https://$DOMAIN_NAME${NC}"
echo -e "${BLUE}Admin Portal: https://$DOMAIN_NAME/admin${NC}"
echo -e "${BLUE}Care Portal: https://$DOMAIN_NAME/care${NC}"
echo -e "${BLUE}ACT Portal: https://$DOMAIN_NAME/act${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Set up DNS records (if not using Cloud DNS)"
echo "2. Access the admin portal and complete initial setup"
echo "3. Configure user accounts and organization settings"
echo ""
echo -e "${BLUE}📊 Project Details:${NC}"
echo "Project ID: $PROJECT_ID"
echo "Instance ID: $INSTANCE_ID"
echo "License Key: $LICENSE_KEY"
echo ""
echo -e "${GREEN}Support: support@careconnect.com${NC}"