# Zero-Downtime Node.js Deployment with GitLab CI/CD, Docker, and Traefik

This project demonstrates a robust deployment pipeline for Node.js applications that ensures zero downtime during updates. It combines GitLab CI/CD for automation, Docker for containerization, and Traefik as a reverse proxy with automatic SSL certificate generation.

## Features

-   🚀 **Zero-downtime deployments** using blue-green deployment strategy
-   🔒 **Automatic HTTPS** with Let's Encrypt via Traefik
-   🤖 **Automated CI/CD pipeline** through GitLab
-   🐳 **Dockerized** application with health checks
-   🔄 **Rollback-ready** architecture
-   📊 **Traefik dashboard** for monitoring

## Architecture Overview

1. **GitLab CI/CD Pipeline**:

    - Builds Docker image on code push
    - Pushes image to container registry
    - Deploys to production server with zero downtime

2. **Production Server**:
    - Runs Traefik as reverse proxy
    - Manages containers via Docker Compose
    - Handles automatic SSL certificates
    - Routes traffic to healthy containers

## Prerequisites

-   GitLab account with a project
-   Server with:
    -   Docker and Docker Compose installed
    -   SSH access
    -   Domain name pointing to server
-   The following environment variables configured in GitLab CI/CD settings:
    -   `CI_REGISTRY_USER` (Built-in GitLab variable)
    -   `CI_REGISTRY_PASSWORD` (Built-in GitLab variable)
    -   `CI_REGISTRY` (Built-in GitLab variable)
    -   `SSH_PRIVATE_KEY` (SSH key for server access)

## Setup Instructions

### 1. Configure GitLab CI/CD Variables

Navigate to your GitLab project:

1. Settings → CI/CD → Variables
2. Add these variables:
    - `CI_REGISTRY_USER`: Your container registry username
    - `CI_REGISTRY_PASSWORD`: Your container registry password
    - `CI_REGISTRY`: Your container registry URL
    - `SSH_PRIVATE_KEY`: Private key for server access

### 2. Server Preparation

On your production server:

```bash
# Create project directory
mkdir -p /home/ubuntu/my-app
```

### 3. Configure Traefik

Edit `docker-compose.yml`:

-   Update `traefik.http.routers.app.rule` with your domain
-   Change `--certificatesresolvers.letsencrypt.acme.email` to your email

### 4. Deploy Your Application

Push to your GitLab repository's default branch (usually main or master). The pipeline will automatically:

1. Build the Docker image
2. Push the image to the container registry
3. SSH into the server
4. Pull the latest image
5. Restart the application with zero downtime
6. Clean up old images

## How It Works

### Deployment Process

1. Build Stage:
    - Creates Docker image tagged with commit SHA
    - Pushes image to GitLab container registry
2. Deploy Stage:
    - Copies necessary files to server via SSH
    - Executes zero-downtime deployment script:
        - Starts Traefik if not running
        - Scales application to 2 containers
        - Verifies new container health
        - Removes old container
        - Scales back to 1 container
        - Cleans up old images

## Zero-Downtime Mechanism

The deploy.sh script implements a blue-green like strategy:

1. New container is started alongside old container
2. Health checks confirm new container is ready
3. Traffic is seamlessly transitioned to new container
4. Old container is removed

## Customizing for Your Application

1. Update Node.js Application:

-   Modify `index.js` and `package.json` for your needs
-   Ensure your app listens on port 3000 (or update all references)

2. Environment Variables:

-   Add any needed environment variables to docker-compose.yml

3. Traefik Configuration:

-   Adjust labels in docker-compose.yml for your routing needs
-   Add middleware as needed (rate limiting, authentication, etc.)

## Monitoring

Access the Traefik dashboard at:

`http://your-domain:8080/dashboard/`

## Troubleshooting

### Common Issues

1. SSL Certificate Problems:

-   Ensure your domain's DNS is properly configured
-   Verify port 80 is accessible for Let's Encrypt validation
-   Check `letsencrypt/acme.json` permissions (must be 600)

2. Deployment Failures:

-   Check GitLab pipeline logs
-   Verify all CI/CD variables are set correctly
-   Confirm SSH access works manually

3. Health Check Failures:

-   Ensure your application has a proper health endpoint
-   Adjust health check parameters in docker-compose.yml

4. Traefik Issues:

-   Check Traefik logs for errors
-   Ensure Traefik is running and accessible on port 80/443
-   Verify Traefik configuration in docker-compose.yml

## Happy Deploying!

This setup provides a solid foundation for deploying Node.js applications with zero downtime. Feel free to customize and extend it to fit your specific needs. If you have any questions or suggestions, please open an issue or submit a pull request.
