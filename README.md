# Google Cloud DNS Updater

This utility allows for the remote update of DNS records from dynamic clients using basic authentication.

This is a containerized Express.js application written in TypeScript that provides an endpoint to update Google Cloud DNS records.

## Deployment

The solution is deployed to Google Cloud Functions using Terraform.

### Prerequisites

Before deploying to Google Cloud, you must set the following secrets in Google Secret Manager:

- `DNS_API_USER`: The username for basic authentication.
- `DNS_API_PASSWORD`: The password for basic authentication.

### GitHub Actions Deployment

The repository includes a GitHub Actions workflow for automated deployment. For this to work, you need to configure the following repository secrets and variables:

**Secrets:**

- `GCP_ID_PROVIDER`: The Workload Identity Provider resource name.
- `GCP_DEPLOY_ACC`: The email address of the service account to use for deployment.

**Variables:**

- `GCP_PROJECT`: Your Google Cloud project ID.
- `DOMAIN_NAME`: The domain name of the zone (e.g., `example.com`).

Refer to the `.github/workflows/deploy.yml` file for more details.

## Local Development

For local development and testing, you need to create two configuration files:

1.  **`dns-updater-ts/.env`**: This file provides environment variables for the TypeScript application.

    ```
    API_USER=your_username
    API_PASSWORD=your_password
    DNS_ZONE=your_dns_zone_name
    DNS_DOMAIN=your_dns_domain.com
    ```

2.  **`infrastructure/.auto.tfvars`**: This file provides variables for Terraform.

    ```tfvars
    project      = "your-gcp-project-id"
    domain_name  = "your-dns-domain.com"
    ```

### Building and Deploying Locally

The `Makefile` provides helpers for building and deploying:

- `make build-ts`: Builds the TypeScript application.
- `make deploy-ts`: Builds the application and applies the Terraform configuration.

### Basic Usage

The function detects the caller's public IP and updates the specified host's A record to that IP address.

Start the function locally:

```bash
cd dns-updater-ts
npm run dev
```

Call the function with a GET request:

```bash
curl -u "your-username:your-password" "http://localhost:8080/update?host=subdomain"
```

Or with a POST request:

```bash
curl -X POST -u "your-username:your-password" http://localhost:8080/update -H "Content-Type:application/json" --data '{"host":"subdomain"}'
```

The `host` parameter should be the subdomain to update (e.g., `www`). The application will append the domain configured.

---
