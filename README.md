# Care Connect GCP Cloud Build Deployment

## Client: blue cross home care ltd

This package contains a complete GCP Cloud Build deployment for Care Connect using multi-container architecture.

### Architecture

- **Frontend**: React app served by NGINX (gcr.io/PROJECT_ID/careconnect-bluecrosshomecareltd-frontend)
- **Backend**: Express.js API server (gcr.io/PROJECT_ID/careconnect-bluecrosshomecareltd-backend)  
- **Database**: Cloud SQL PostgreSQL instance
- **Infrastructure**: Terraform-managed Cloud Run services

### Quick Start

1. **Prerequisites**
   ```bash
   # Enable required APIs
   gcloud services enable cloudbuild.googleapis.com
   gcloud services enable run.googleapis.com
   gcloud services enable sql-component.googleapis.com
   ```

2. **Deploy Application**
   ```bash
   # Submit to Cloud Build
   gcloud builds submit --config cloudbuild.yaml
   ```

### File Structure
```
├── frontend/
│   ├── Dockerfile          # React build → NGINX
│   └── .dockerignore
├── nginx/
│   ├── Dockerfile          # NGINX reverse proxy
│   └── conf.d/default.conf # SPA routing config
├── backend/
│   └── Dockerfile          # Express API server
├── terraform/
│   ├── main.tf             # Cloud Run + SQL
│   ├── variables.tf
│   └── outputs.tf
├── cloudbuild.yaml         # Build pipeline
├── .gcloudignore
└── README.md
```

### GCP Quota Compliance

- Max instances: 5 per service (within 10 limit)
- Memory: 512Mi per instance (within 40GB region limit)  
- CPU: 1 vCPU per instance (within 20,000m limit)
- Scales to zero when not in use

### Client Information

- **Organization**: blue cross home care ltd
- **Domain**: bluecrosshomecareltd
- **License Key**: 8e30afee-7c07-424d-8a59-6e735eaaaf77
- **Instance ID**: 74b6fc3f-9c07-4e23-b2a5-f8c0fa7191ee

### GitHub Integration

This package is ready for GitHub-triggered Cloud Build:

1. Upload to GitHub repository
2. Connect Cloud Build trigger to repository
3. Trigger on push to main branch
4. Automatic deployment to Cloud Run

### Support

Frontend URL: Available after deployment in Terraform outputs
Backend URL: Available after deployment in Terraform outputs

For support: support@careconnect.com
