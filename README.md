# actions-example
# Automated Deployment Pipeline with Terraform and AWS

## Overview
This repository contains a sample web application that is automatically deployed using Terraform and GitHub Actions. It provisions the necessary AWS infrastructure, builds a Docker image, and deploys the application.

## Prerequisites
- AWS Account
- AWS CLI configured
- Docker installed
- GitHub Account
- GitHub repository created for this project

## Setting Up the Environment

1. Clone the repository:
    ```bash
    git clone <repository_url>
    cd your-app
    ```

2. Set up AWS credentials in your GitHub repository:
   - Go to the repository settings.
   - Navigate to *Secrets*.
   - Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as secrets.

3. Modify `terraform/variables.tf` to specify your key name under the `key_name` variable.

4. Update the Docker Hub username in `.github/workflows/ci-cd.yml` file.

## Deploying the Application
Once everything is set up, push changes to the `main` branch to trigger the CI/CD pipeline:

```bash
git add .
git commit -m "Setup CI/CD Pipeline"
git push origin main