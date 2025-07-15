# Focust Terraform Infrastructure

Terraform infrastructure for Focust microservices (frontend, backend, auth) on Google Cloud Run.

## Quick Start

```bash
# Set your GCP project ID
export PROJECT_ID="focust-dev"

# Create state bucket
gsutil mb -p $PROJECT_ID gs://${PROJECT_ID}-terraform-state

# Update project ID in tfvars
sed -i "s/focust-dev/$PROJECT_ID/g" environments/dev.tfvars

# Deploy everything
./deploy.sh dev all
```

## Directory Structure

```
├── base/                  # Shared infrastructure (APIs, Artifact Registry, IAM)
├── services/              
│   ├── frontend/         # Frontend service
│   ├── backend/          # Backend service
│   ├── auth/             # Auth service
│   └── common-modules/   # Reusable Cloud Run module
├── environments/         # Environment configurations
│   ├── dev.tfvars
│   ├── stage.tfvars
│   └── prod.tfvars
├── .github/workflows/    # GitHub Actions
│   └── infra.yml        # Terraform workflow
└── deploy.sh            # Deployment script
```

## Prerequisites

1. **Google Cloud Project** with billing enabled
2. **Service Account** with the following roles:
   - Cloud Run Admin
   - Artifact Registry Admin
   - Storage Admin
   - Secret Manager Admin
   - Service Account Admin
   - IAM Admin

3. **Terraform State Buckets** created for each environment:
   ```bash
   gsutil mb gs://focust-dev-terraform-state
   gsutil mb gs://focust-stage-terraform-state
   gsutil mb gs://focust-prod-terraform-state
   ```

4. **Service Account Keys** stored as GitHub secrets:
   - `GCP_SA_KEY_DEV`
   - `GCP_SA_KEY_STAGE`
   - `GCP_SA_KEY_PROD`

## Setup Instructions

### 1. Create Service Account

```bash
# Create service account
gcloud iam service-accounts create terraform \
  --display-name="Terraform Service Account" \
  --project=YOUR_PROJECT_ID

# Grant necessary roles
for role in \
  "roles/run.admin" \
  "roles/artifactregistry.admin" \
  "roles/storage.admin" \
  "roles/secretmanager.admin" \
  "roles/iam.serviceAccountAdmin" \
  "roles/iam.serviceAccountKeyAdmin" \
  "roles/resourcemanager.projectIamAdmin"
do
  gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="$role"
done

# Create and download key
gcloud iam service-accounts keys create service-account-key.json \
  --iam-account=terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### 2. Configure GitHub Secrets

Add the service account key to GitHub secrets:
1. Go to Settings → Secrets and variables → Actions
2. Create secrets for each environment:
   - `GCP_SA_KEY_DEV`: Contents of dev service account key
   - `GCP_SA_KEY_STAGE`: Contents of stage service account key
   - `GCP_SA_KEY_PROD`: Contents of prod service account key

### 3. Update Environment Variables

Edit the `.tfvars` files in `environments/` directory:
- Update `project_id` with your GCP project ID
- Update `terraform_state_bucket` with your state bucket name
- Configure service-specific variables as needed

## Deployment

### GitHub Actions (Recommended)

The infrastructure is automatically deployed via GitHub Actions:

- **Pull Requests**: Runs terraform validate and plan
- **Push to develop**: Deploys to dev environment
- **Push to main**: Deploys to staging environment
- **Push to production**: Deploys to production environment

You can also manually trigger deployments using the workflow dispatch feature.

### Local Deployment

Use the provided deployment script:

```bash
# Deploy all components to dev
./deploy.sh dev

# Deploy only frontend to staging
./deploy.sh stage frontend

# Deploy only base infrastructure to production
./deploy.sh prod base
```

### Manual Deployment

#### 1. Deploy Base Infrastructure
```bash
cd base
terraform init -backend-config="bucket=${PROJECT_ID}-terraform-state"
terraform plan -var-file="./environments/dev.tfvars"
terraform apply -var-file="./environments/dev.tfvars"
cd ..
```

#### 2. Deploy Services
```bash
# Auth Service
cd services/auth
terraform init -backend-config="bucket=${PROJECT_ID}-terraform-state"
terraform plan -var-file="../environments/dev.tfvars"
terraform apply -var-file="../environments/dev.tfvars"
cd ../..

# Backend Service
cd services/backend
terraform init -backend-config="bucket=${PROJECT_ID}-terraform-state"
terraform plan -var-file="../environments/dev.tfvars"
terraform apply -var-file="../environments/dev.tfvars"
cd ../..

# Frontend Service
cd services/frontend
terraform init -backend-config="bucket=${PROJECT_ID}-terraform-state"
terraform plan -var-file="../environments/dev.tfvars"
terraform apply -var-file="../environments/dev.tfvars"
cd ../..
```

## Module Usage

The reusable Cloud Run module supports:
- Container deployment with custom images
- Environment variables and secrets
- Auto-scaling configuration
- Custom domains
- VPC connectivity
- Storage buckets
- IAM policies

Example usage:
```hcl
module "my_service" {
  source = "../common-modules/cloud-run"
  
  service_name          = "my-service"
  region                = var.region
  project_id            = var.project_id
  environment           = var.environment
  artifact_registry_url = data.terraform_remote_state.base.outputs.artifact_registry_url
  image_tag             = "latest"
  
  env_vars = {
    NODE_ENV = "production"
    PORT     = "8080"
  }
  
  min_instances = 1
  max_instances = 100
}
```

## Cross-Service Communication

After deploying all services, update the service URLs in the tfvars files:

1. Deploy base infrastructure and all services
2. Get the service URLs from outputs
3. Update the tfvars files with the URLs:
   ```hcl
   backend_url = "https://focust-backend-production-xxxxx.run.app"
   auth_url = "https://focust-auth-production-xxxxx.run.app"
   frontend_urls = ["https://focust-frontend-production-xxxxx.run.app"]
   ```
4. Re-apply the services to update their configurations

## Troubleshooting

### State Lock Issues
If you encounter state lock issues:
```bash
terraform force-unlock LOCK_ID
```

### Permission Errors
Ensure your service account has all required roles:
```bash
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --format='table(bindings.role)' \
  --filter="bindings.members:terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com"
```

### Container Image Not Found
Ensure images are pushed to Artifact Registry before deploying:
```bash
docker tag my-image:latest REGION-docker.pkg.dev/PROJECT_ID/focust-services/SERVICE_NAME:TAG
docker push REGION-docker.pkg.dev/PROJECT_ID/focust-services/SERVICE_NAME:TAG
```

## Security Best Practices

1. **Never commit service account keys** to the repository
2. **Use least privilege** for service accounts
3. **Enable audit logging** for production environments
4. **Rotate service account keys** regularly
5. **Use Secret Manager** for sensitive configuration
6. **Enable VPC** for production services