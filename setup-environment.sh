#!/bin/bash

# Environment setup script for Google Cloud Run deployment
# This script prepares the local environment for deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Setting up deployment environment...${NC}"

# Check if gcloud CLI is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${YELLOW}📥 Installing Google Cloud CLI...${NC}"
    
    # Detect OS and install accordingly
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl https://sdk.cloud.google.com | bash
        exec -l $SHELL
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install --cask google-cloud-sdk
        else
            echo -e "${RED}❌ Please install Homebrew or manually install Google Cloud CLI${NC}"
            echo "Visit: https://cloud.google.com/sdk/docs/install"
            exit 1
        fi
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        # Windows
        echo -e "${YELLOW}Please download and install Google Cloud CLI for Windows:${NC}"
        echo "https://cloud.google.com/sdk/docs/install-sdk#windows"
        exit 1
    else
        echo -e "${RED}❌ Unsupported OS. Please manually install Google Cloud CLI${NC}"
        echo "Visit: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Docker not found. Please install Docker Desktop${NC}"
    echo "Visit: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Initialize gcloud if not done
if [ ! -f ~/.config/gcloud/credentials_db ]; then
    echo -e "${YELLOW}🔐 Initializing Google Cloud CLI...${NC}"
    gcloud init
fi

# Verify authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}🔐 Please authenticate with Google Cloud...${NC}"
    gcloud auth login
fi

# Configure Docker to use gcloud as credential helper
echo -e "${YELLOW}🐳 Configuring Docker for Google Cloud...${NC}"
gcloud auth configure-docker

echo -e "${GREEN}✅ Environment setup completed!${NC}"
echo -e "${BLUE}You can now run ./deploy.sh to deploy your application${NC}"