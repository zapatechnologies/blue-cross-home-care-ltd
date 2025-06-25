# Google Cloud Run Deployment - blue cross home care ltd

## One-Click Deployment for Care Connect

This package contains everything needed to deploy your Care Connect instance to Google Cloud Run with a single command.

### 🚀 Quick Start

1. **Extract the deployment package**
   ```bash
   unzip bluecrosshomecare-cloudrun-deployment.zip
   cd bluecrosshomecare-careconnect-cloudrun-deployment
   ```

2. **Run the setup script** (first time only)
   ```bash
   chmod +x setup-environment.sh
   ./setup-environment.sh
   ```

3. **Deploy your application**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

4. **Access your application**
   - Main Application: https://bluecrosshomecareltd
   - Admin Portal: https://bluecrosshomecareltd/admin
   - Care Portal: https://bluecrosshomecareltd/care
   - ACT Portal: https://bluecrosshomecareltd/act

### 📋 Prerequisites

- Google Cloud Account with billing enabled
- Domain control for `bluecrosshomecareltd`
- Local machine with internet connection

### 🏗️ What Gets Deployed

- **Cloud Run Service** - Serverless container hosting
- **Cloud SQL Database** - Managed PostgreSQL database
- **Secret Manager** - Secure credential storage
- **Custom Domain** - SSL certificate and DNS configuration
- **Monitoring** - Health checks and logging

### 💰 Cost Estimation

- **Free Tier**: $0/month (first 300$ credit)
- **After Free Tier**: ~$7-15/month
  - Cloud Run: $0-5/month (scales to zero)
  - Cloud SQL: $7-10/month (f1-micro)

### 🔧 Manual Configuration (if needed)

If you prefer manual setup or encounter issues:

1. **Create Google Cloud Project**
   ```bash
   gcloud projects create bluecrosshomecare-careconnect --name="blue cross home care ltd Care Connect"
   gcloud config set project bluecrosshomecare-careconnect
   ```

2. **Enable APIs**
   ```bash
   gcloud services enable run.googleapis.com sql-component.googleapis.com cloudbuild.googleapis.com
   ```

3. **Deploy with Cloud Build**
   ```bash
   gcloud builds submit --config cloudbuild.yaml
   ```

### 📊 Instance Details

- **Organization**: blue cross home care ltd
- **Domain**: bluecrosshomecareltd
- **Project ID**: bluecrosshomecare-careconnect
- **Instance ID**: 74b6fc3f-9c07-4e23-b2a5-f8c0fa7191ee
- **License Key**: 8e30afee-7c07-424d-8a59-6e735eaaaf77
- **Database**: PostgreSQL on Cloud SQL
- **Scaling**: 0-10 instances (auto)

### 🛠️ Maintenance Commands

```bash
# View application logs
gcloud run services logs tail care-connect --region us-central1

# Scale service
gcloud run services update care-connect --max-instances 20 --region us-central1

# Update application
gcloud builds submit --tag gcr.io/bluecrosshomecare-careconnect/care-connect
gcloud run services update care-connect --image gcr.io/bluecrosshomecare-careconnect/care-connect --region us-central1

# Backup database
gcloud sql export sql bluecrosshomecare-careconnect-db gs://bluecrosshomecare-careconnect-backups/backup-$(date +%Y%m%d).sql --database=careconnect

# Monitor resources
gcloud run services describe care-connect --region us-central1
gcloud sql instances describe bluecrosshomecare-careconnect-db
```

### 🔒 Security Features

- Non-root container execution
- Secret Manager for sensitive data
- Cloud SQL with private networking
- Automatic SSL certificates
- IAM-based access control

### 📞 Support

- **Technical Support**: support@careconnect.com
- **License Issues**: Include License Key: 8e30afee-7c07-424d-8a59-6e735eaaaf77
- **Instance ID**: 74b6fc3f-9c07-4e23-b2a5-f8c0fa7191ee
- **Google Cloud Console**: https://console.cloud.google.com/run?project=bluecrosshomecare-careconnect

### 🔄 Troubleshooting

**Billing Issues**
```bash
# Check billing status
gcloud beta billing accounts list
gcloud beta billing projects link bluecrosshomecare-careconnect --billing-account=BILLING_ACCOUNT_ID
```

**Domain Issues**
```bash
# Check domain mapping
gcloud run domain-mappings describe --domain bluecrosshomecareltd --region us-central1

# View DNS requirements
gcloud dns managed-zones describe bluecrosshomecareltd-zone
```

**Application Issues**
```bash
# Check service status
gcloud run services describe care-connect --region us-central1

# View recent logs
gcloud run services logs read care-connect --region us-central1 --limit 50
```

---

**Deployed by Care Connect Super Admin**  
**Package generated**: $(date)