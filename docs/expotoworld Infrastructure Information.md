# Expo to World - Migration Reference Guide

**Last Updated**: October 17, 2025
**Migration Period**: October 11-17, 2025
**Status**: ✅ **COMPLETE** - All core services migrated and operational
**Latest Update**: Infrastructure fixes for S3 images and ebook editor routing

---

## 📋 **1. Document Purpose**

This document serves as the **authoritative reference** for the Expo to World (expotoworld) infrastructure, providing comprehensive details on all AWS resources, services, credentials, and deployment configurations.

**Scope**: This document covers the complete greenfield migration from the madeinworld project to the expotoworld project, including all backend services, frontend applications, database infrastructure, and development tools.

**Audience**: Development team, DevOps engineers, and system administrators working on the expotoworld project.

---

## ☁️ **2. AWS Infrastructure Inventory**

### **AWS Account Information**

| Property | Value |
|----------|-------|
| **AWS Account ID** | `834076182408` |
| **Primary Region** | `eu-central-1` (Europe - Frankfurt) |
| **Account Type** | Production |

### **AWS Services in Use**

| Service | Purpose | Resource Count |
|---------|---------|----------------|
| **AWS App Runner** | Backend service hosting | 5 services |
| **Amazon ECR** | Container image registry | 5 repositories |
| **AWS Lambda** | Auth cleanup automation | 2 functions (dev/prod) |
| **Amazon S3** | Static website hosting + assets | 4 buckets |
| **Amazon CloudFront** | CDN for frontend apps + assets | 4 distributions |
| **AWS Secrets Manager** | Credentials storage | 4 secrets |
| **Amazon EventBridge** | Lambda scheduling | 2 rules |
| **Amazon SNS** | Alarm notifications | 1 topic |
| **Amazon CloudWatch** | Monitoring & logging | Multiple log groups |
| **AWS IAM** | Access management | 5 roles |

**Examples**:
- ECR: `expotoworld-auth-service`
- App Runner: `expotoworld-auth-service`
- Lambda: `expotoworld-auth-cleanup-dev`
- S3: `expotoworld-admin-website`, `expotoworld-product-images`
- CloudFront: `E2JL3VLX19R2ZH` (admin), `E368C7TCMCEDEG` (assets)

---

## 🔐 **3. Secrets & Credentials**

### **AWS Secrets Manager**

| Secret Name | ARN | Purpose | Used By |
|-------------|-----|---------|---------|
| `expotoworld/neon/db` | `arn:aws:secretsmanager:eu-central-1:834076182408:secret:expotoworld/neon/db-qGlFqS` | Production database connection string | All backend services |
| `expotoworld/jwt/secret` | `arn:aws:secretsmanager:eu-central-1:834076182408:secret:expotoworld/jwt/secret-ppRbxm` | JWT signing secret | Auth service, all services |
| `expotoworld/neon/dev_auth-cleaner` | `arn:aws:secretsmanager:eu-central-1:834076182408:secret:expotoworld/neon/dev_auth-cleaner-nO64KK` | Dev database for auth cleanup | Lambda (dev) |
| `expotoworld/neon/prod_auth-cleaner` | `arn:aws:secretsmanager:eu-central-1:834076182408:secret:expotoworld/neon/prod_auth-cleaner-iv3ynA` | Prod database for auth cleanup | Lambda (prod) |

### **GitHub Secrets**

Required for GitHub Actions workflows:

| Secret Name | Purpose | Used By |
|-------------|---------|---------|
| `DATABASE_URL_SECRET_ARN` | Database secret ARN | App Runner deployments |
| `JWT_SECRET_ARN` | JWT secret ARN | App Runner deployments |

### **Secrets Used by GitHub but hardcoded in workflow yml currently**

| `AWS_ACCOUNT_ID` | AWS account identifier | All ECR workflows | = 834076182408 |
| `AWS_REGION` | AWS region (eu-central-1) | All workflows | = eu-central-1 |
| `S3_BUCKET_ADMIN` | Admin panel S3 bucket name | Admin panel deployment | = expotoworld-admin-website |
| `S3_BUCKET_EBOOK` | Ebook editor S3 bucket name | Ebook editor deployment | = expotoworld-ebook-website |
| `CLOUDFRONT_DISTRIBUTION_ID_ADMIN` | Admin panel CloudFront ID | Admin panel deployment | = E2JL3VLX19R2ZH |
| `CLOUDFRONT_DISTRIBUTION_ID_EBOOK` | Ebook editor CloudFront ID | Ebook editor deployment | = E25UL5QH3I1VIU |

### **Environment Variables**

**Backend Services** (via Secrets Manager):
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - JWT signing key
- `PORT` - Service port (8081-8085)

**Frontend Applications** (build-time):
- `REACT_APP_API_BASE_URL` - API gateway URL
- `VITE_API_BASE_URL` - API gateway URL (Vite)

---

## 🗄️ **4. Database Infrastructure**

### **Neon PostgreSQL**

| Property | Value |
|----------|-------|
| **Provider** | Neon (Serverless PostgreSQL) |
| **Project ID** | `dry-leaf-47229106` |
| **Region** | AWS eu-central-1 |
| **PostgreSQL Version** | 16 |

### **Database Branches**

| Environment | Branch ID | Branch Name | Purpose |
|-------------|-----------|-------------|---------|
| **Production** | `br-summer-grass-agae9qc2` | `main` | Production database |
| **Development** | `br-ancient-smoke-agdkjqa8` | `dev` | Development database |

### **Database Names**

- **Primary Database**: `neondb` (default)
- **Schema**: Public schema with all application tables

### **Database Access**

- **Secrets Manager**: All connection strings stored in AWS Secrets Manager
- **SSL**: Required for all connections
- **Pooling**: Managed by Neon (serverless)

---

## 🔧 **5. Backend Services**

All backend services are built with **Go 1.24.4** and deployed to **AWS App Runner**.

### **Service Overview**

| Service | Port | ECR Repository | App Runner Service | Health Check |
|---------|------|----------------|-------------------|--------------|
| **Auth Service** | 8081 | `expotoworld-auth-service` | `expotoworld-auth-service` | `/live` |
| **User Service** | 8082 | `expotoworld-user-service` | `expotoworld-user-service` | `/live` |
| **Catalog Service** | 8083 | `expotoworld-catalog-service` | `expotoworld-catalog-service` | `/live` |
| **Order Service** | 8084 | `expotoworld-order-service` | `expotoworld-order-service` | `/live` |
| **Ebook Service** | 8085 | `expotoworld-ebook-service` | `expotoworld-ebook-service` | `/live` |

### **ECR Repository URIs**

```
834076182408.dkr.ecr.eu-central-1.amazonaws.com/expotoworld-auth-service
834076182408.dkr.ecr.eu-central-1.amazonaws.com/expotoworld-user-service
834076182408.dkr.ecr.eu-central-1.amazonaws.com/expotoworld-catalog-service
834076182408.dkr.ecr.eu-central-1.amazonaws.com/expotoworld-order-service
834076182408.dkr.ecr.eu-central-1.amazonaws.com/expotoworld-ebook-service
```

### **App Runner Configuration**

**Common Settings**:
- **CPU**: 1 vCPU
- **Memory**: 2 GB
- **Auto Scaling**: 1-10 instances
- **Health Check**: HTTP GET on `/live`
- **Health Check Interval**: 5 seconds
- **Health Check Timeout**: 2 seconds
- **Unhealthy Threshold**: 5 failures

**Environment Variables** (all services):
- `DATABASE_URL` (from Secrets Manager)
- `JWT_SECRET` (from Secrets Manager)
- `PORT` (service-specific)

### **API Endpoints**

**Production** (via Cloudflare Worker Gateway):
```
https://device-api.expotoworld.com
```

**Development** (local):
```
http://localhost:8081  # Auth Service
http://localhost:8082  # User Service
http://localhost:8083  # Catalog Service
http://localhost:8084  # Order Service
http://localhost:8085  # Ebook Service
```

### **Service Routes**

| Service | Route Pattern | Example |
|---------|---------------|---------|
| **Auth** | `/api/auth/*` | `/api/auth/login` |
| **User** | `/api/admin/users/*` | `/api/admin/users/list` |
| **Catalog** | `/api/v1/*` | `/api/v1/products` |
| **Order** | `/api/admin/orders/*` | `/api/admin/orders/list` |
| **Ebook** | `/api/ebook/*` | `/api/ebook` (GET/PUT), `/api/ebook/versions` (POST) |

---

## 🎨 **6. Frontend Applications**

### **Admin Panel**

| Property | Value |
|----------|-------|
| **Technology** | React 18.2.0 + Create React App |
| **UI Framework** | Material-UI (@mui) 5.15.1 |
| **S3 Bucket** | `expotoworld-admin-website` |
| **CloudFront Distribution** | `E2JL3VLX19R2ZH` |
| **Production URL** | `https://admin.expotoworld.com` |
| **Local Dev URL** | `http://localhost:3000` |

**Build Configuration**:
- Node.js 18
- Build command: `npm run build`
- Build output: `build/`

**Environment Variables**:
- `REACT_APP_API_BASE_URL=https://device-api.expotoworld.com`

### **Ebook Editor**

| Property | Value |
|----------|-------|
| **Technology** | React 18.2.0 + Vite 5.3.4 |
| **Editor** | TipTap 2.4.0 |
| **S3 Bucket** | `expotoworld-ebook-website` |
| **CloudFront Distribution** | `E25UL5QH3I1VIU` |
| **Production URL** | `https://huashangdao.expotoworld.com` |
| **Local Dev URL** | `http://localhost:5173` |

**Build Configuration**:
- Node.js 18
- Build command: `npm run build`
- Build output: `dist/`

**Environment Variables**:
- `VITE_API_BASE_URL=https://device-api.expotoworld.com`

### **Flutter Mobile App**

| Property | Value |
|----------|-------|
| **Technology** | Flutter 3.8.1 + Dart 3.8.1 |
| **State Management** | Provider 6.1.1 |
| **Package Name** | `com.expotoworld.app` |
| **Min SDK (Android)** | 21 (Android 5.0) |
| **Min iOS** | 12.0 |

**Build Flavors**:
- **dev**: Development flavor with dev badge
- **prod**: Production flavor

**API Configuration**:
- **Production**: `https://device-api.expotoworld.com`
- **iOS Dev**: `http://127.0.0.1:8787`
- **Android Dev**: `http://10.0.2.2:8787`

---

## 📦 **7. S3 Buckets & CloudFront Distributions**

### **S3 Buckets**

| Bucket Name | Purpose | Region | Public Access | Size | Objects |
|-------------|---------|--------|---------------|------|---------|
| `expotoworld-admin-website` | Admin panel static hosting | eu-central-1 | Via CloudFront | ~2 MB | ~20 |
| `expotoworld-ebook-website` | Ebook editor static hosting | eu-central-1 | Via CloudFront | ~1 MB | ~15 |
| `expotoworld-product-images` | Product/store/category images | eu-central-1 | Via CloudFront OAC | 23.5 MiB | 33 |
| `expotoworld-ebook-versions` | Ebook versions storage | eu-central-1 | Private | - | - |

**Legacy Buckets** (deprecated, kept for backup):
- `madeinworld-product-images-admin` - Old product images (33 objects, 23.5 MiB)

### **CloudFront Distributions**

| Distribution ID | Domain | Origin | Purpose | Status |
|-----------------|--------|--------|---------|--------|
| `E2JL3VLX19R2ZH` | `admin.expotoworld.com` | `expotoworld-admin-website.s3` | Admin panel CDN | ✅ Active |
| `E25UL5QH3I1VIU` | `huashangdao.expotoworld.com` | `expotoworld-ebook-website.s3` | Ebook editor CDN | ✅ Active |
| `E368C7TCMCEDEG` | `assets.expotoworld.com` | `expotoworld-product-images.s3` | Product images CDN | ✅ Active |

**Legacy Distributions** (deprecated):
- `E1W2M5U1SUJOW9` - `assets.expomadeinworld.com` → `madeinworld-product-images-admin`

### **CloudFront Configuration**

**Common Settings**:
- **Price Class**: All edge locations
- **HTTP Version**: HTTP/2 and HTTP/3
- **IPv6**: Enabled
- **Compression**: Enabled (Gzip, Brotli)
- **SSL Certificate**: AWS Certificate Manager (ACM)
- **Minimum TLS Version**: TLSv1.2

**Origin Access Control (OAC)**:
- **Product Images CDN** (`E368C7TCMCEDEG`): OAC enabled (`E1FOLNE3I9B4ES`)
- **Admin/Ebook CDNs**: Public S3 bucket access

### **S3 Bucket Policies**

**Product Images Bucket** (`expotoworld-product-images`):
- CloudFront OAC has read access
- Catalog service has read/write access via IAM role
- Public access blocked

**Website Buckets** (`expotoworld-admin-website`, `expotoworld-ebook-website`):
- Public read access for CloudFront
- GitHub Actions has write access for deployments

### **Image URL Patterns**

**Product Images**:
```
https://assets.expotoworld.com/products/{product_id}/{timestamp}_{filename}
```

**Store Images**:
```
https://assets.expotoworld.com/stores/store_{store_id}_{timestamp}_{filename}
```

**Category Images**:
```
https://assets.expotoworld.com/categories/category_{category_id}_{timestamp}_{filename}
```

**Subcategory Images**:
```
https://assets.expotoworld.com/subcategories/subcategory_{subcategory_id}_{timestamp}_{filename}
```

---

## ⚡ **8. Lambda Functions**

### **Auth Cleanup Lambda**

**Purpose**: Automated cleanup of expired authentication records and tokens

| Property | Dev | Prod |
|----------|-----|------|
| **Function Name** | `expotoworld-auth-cleanup-dev` | `expotoworld-auth-cleanup-prod` |
| **Runtime** | `provided.al2023` (Go custom runtime) | `provided.al2023` (Go custom runtime) |
| **Memory** | 128 MB | 128 MB |
| **Timeout** | 30 seconds | 30 seconds |
| **Schedule** | `rate(12 hours)` | `rate(12 hours)` |
| **Database Branch** | `br-ancient-smoke-agdkjqa8` (dev) | `br-summer-grass-agae9qc2` (main) |
| **Secret ARN** | `...dev_auth-cleaner-nO64KK` | `...prod_auth-cleaner-iv3ynA` |

**Retention Periods**:
- Verification codes (used): 24 hours
- Verification codes (expired): 1 hour
- Rate limits: 24 hours
- Refresh tokens (revoked): 24 hours
- Refresh tokens (expired): **3 days** (reduced from 7 days)

**EventBridge Rules**:
- `expotoworld-auth-cleanup-dev`: Enabled, `rate(12 hours)`
- `expotoworld-auth-cleanup-prod`: Enabled, `rate(12 hours)`

**CloudWatch Metrics**:
- Namespace: `ExpoToWorld/AuthCleanup`
- Metrics: Deleted rows per category

**SNS Notifications**:
- Topic: `expotoworld-auth-cleanup-alarms`
- Subscription: `expotobsrl@gmail.com`
- Alarms: Lambda errors (≥1 in 5 minutes)

---

## 🚀 **9. CI/CD Pipeline**

### **GitHub Actions Workflows**

**Backend Services** (5 workflows):
1. `auth-service-ecr.yml` - Build and push to ECR
2. `user-service-ecr.yml` - Build and push to ECR
3. `catalog-service-ecr.yml` - Build and push to ECR
4. `order-service-ecr.yml` - Build and push to ECR
5. `ebook-service-ecr.yml` - Build and push to ECR

**App Runner Deployments** (5 workflows):
1. `auth-service-apprunner.yml` - Deploy to App Runner ✅ **NEW**
2. `user-service-apprunner.yml` - Deploy to App Runner
3. `catalog-service-apprunner.yml` - Deploy to App Runner
4. `order-service-apprunner.yml` - Deploy to App Runner
5. `ebook-service-apprunner.yml` - Deploy to App Runner

**Frontend Deployments** (2 workflows):
1. `admin-panel-deploy.yml` - Build and deploy to S3/CloudFront
2. `ebook-editor-deploy.yml` - Build and deploy to S3/CloudFront

### **Deployment Process**

**Backend Services**:
1. Push to `main` branch with changes in `backend/{service}/`
2. GitHub Actions builds Docker image
3. Pushes image to ECR with tags: `latest` and `{commit-sha}`
4. App Runner automatically deploys new image (for services with auto-deploy)
5. Health checks verify deployment

**Frontend Applications**:
1. Push to `main` branch with changes in `{app}/`
2. GitHub Actions builds React/Vite app
3. Deploys to S3 bucket
4. Invalidates CloudFront cache
5. Application available immediately

### **Required GitHub Secrets**

See Section 3 (Secrets & Credentials) for complete list.

---

## 🛠️ **10. Development Tools & Scripts**

### **Makefile Commands**

Located at repository root: `Makefile`

| Command | Purpose |
|---------|---------|
| `make dev-env` | Start all backend + frontend services |
| `make dev-backend` | Start all 5 Go backend services |
| `make dev-frontend` | Start admin panel + ebook editor |
| `make dev-flutter-ios` | Launch Flutter app (iOS simulator) |
| `make dev-flutter-android` | Launch Flutter app (Android emulator) |
| `make stop` | Stop all running development services |
| `make help` | Show all available commands |

### **Development Scripts**

Located in `scripts/` directory:

| Script | Purpose |
|--------|---------|
| `flutter_dev_ios.sh` | Launch Flutter app for iOS with dev API |
| `flutter_dev_android.sh` | Launch Flutter app for Android with dev API |
| `flutter_prod.sh` | Launch Flutter app with production API |
| `ios/apply_dev_badge.sh` | Apply "DEV" badge to iOS app icons |
| `ios/dev_icon_overlay.swift` | Swift script for icon overlay rendering |

### **Local Development Setup**

**Prerequisites**:
- Go 1.24.4
- Node.js 18
- Flutter 3.8.1
- Docker (optional, for containerized development)