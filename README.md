# Focust Terraform Infrastructure

Terraform infrastructure for Focust microservices (frontend, backend, auth) on Google Cloud Run.

## Prerequisites

- Google Cloud Project with billing enabled
- Terraform installed
- gcloud CLI installed and authenticated
- Service Account with required roles (Cloud Run Admin, Artifact Registry Admin, Storage Admin, Secret Manager Admin)
- Terraform state bucket created: `gs://${PROJECT_ID}-terraform-state`

## Quick Start

```bash
# Set project ID
export PROJECT_ID="your-gcp-project-id"

# Deploy all services
./deploy.sh dev all

# Deploy specific service
./deploy.sh dev frontend
./deploy.sh dev backend
./deploy.sh dev auth
```

## Commands

### Local Testing
```bash
# Initialize and validate
terraform init
terraform validate
terraform fmt -check

# Plan changes
terraform plan -var-file=../../environments/dev.tfvars

# Apply changes
terraform apply -var-file=../../environments/dev.tfvars
```

### Deployment Commands
```bash
# Deploy base infrastructure
cd base && terraform init && terraform apply

# Deploy individual services
cd services/auth && terraform init && terraform apply -var-file=../../environments/dev.tfvars
cd services/backend && terraform init && terraform apply -var-file=../../environments/dev.tfvars
cd services/frontend && terraform init && terraform apply -var-file=../../environments/dev.tfvars
```

## Cross-Service Communication

1. Deploy all services first
2. Get service URLs from terraform outputs
3. Update `environments/*.tfvars` with service URLs:
   ```hcl
   backend_url = "https://focust-backend-dev-xxxxx.run.app"
   auth_url = "https://focust-auth-dev-xxxxx.run.app"
   frontend_urls = ["https://focust-frontend-dev-xxxxx.run.app"]
   ```
4. Re-apply services to update configurations