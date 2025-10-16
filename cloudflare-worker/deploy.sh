#!/bin/bash
set -e

# Cloudflare Worker Deployment Script
# This script deploys the API gateway worker to Cloudflare

echo "🚀 Deploying Cloudflare Worker: device-api-gateway"
echo "=================================================="
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Wrangler CLI not found!"
    echo ""
    echo "Please install it first:"
    echo "  npm install -g wrangler"
    echo ""
    exit 1
fi

# Check if logged in
echo "🔐 Checking Cloudflare authentication..."
if ! wrangler whoami &> /dev/null; then
    echo "❌ Not logged in to Cloudflare!"
    echo ""
    echo "Please login first:"
    echo "  wrangler login"
    echo ""
    exit 1
fi

echo "✅ Authenticated"
echo ""

# Deploy
echo "📦 Deploying worker..."
wrangler deploy

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Worker URL: https://device-api.expotoworld.com"
echo ""
echo "🧪 Test the deployment:"
echo "  curl https://device-api.expotoworld.com/api/v1/products"
echo ""

