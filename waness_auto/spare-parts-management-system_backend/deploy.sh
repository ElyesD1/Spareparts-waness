#!/bin/bash

# Deployment script for Azure App Service

# Exit on error
set -e

echo "Starting deployment..."

# Install dependencies
echo "Installing dependencies..."
npm install --production=false

# Build the application
echo "Building application..."
npm run build

# Copy uploads directory
echo "Copying uploads directory..."
cp -r uploads dist/ || mkdir -p dist/uploads

echo "Deployment completed successfully!"
