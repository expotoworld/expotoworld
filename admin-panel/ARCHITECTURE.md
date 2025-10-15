# Admin Panel Architecture

## Overview

The admin panel is a React-based Single Page Application (SPA) that provides a web interface for managing the expotoworld e-commerce platform.

## Infrastructure Components

### 1. Static Site Hosting

**Purpose**: Hosts the admin panel React application (HTML, JS, CSS files)

- **S3 Bucket**: `expotoworld-editor-site`
- **CloudFront Distribution**: `E2JL3VLX19R2ZH`
- **Domain**: `https://admin.expotoworld.com`
- **Region**: `eu-central-1`

**Deployment Process**:
1. GitHub Actions builds the React app (`npm run build`)
2. Build artifacts are uploaded to S3 bucket `expotoworld-editor-site`
3. CloudFront cache is invalidated to serve the latest version
4. Users access the admin panel at `https://admin.expotoworld.com`

### 2. Product Image Storage

**Purpose**: Stores product images uploaded through the admin panel

- **S3 Bucket**: `expotoworld-product-images`
- **CloudFront Distribution**: `E368C7TCMCEDEG`
- **Domain**: `https://assets.expotoworld.com`
- **Region**: `eu-central-1`

**Usage**:
- Admin panel uploads product images to this bucket at runtime
- Images are served via CloudFront CDN at `https://assets.expotoworld.com`
- This bucket is NOT used for deploying the admin panel itself

### 3. API Gateway (Cloudflare Worker)

**Purpose**: Routes API requests from the admin panel to backend microservices

- **Production URL**: `https://device-api.expotoworld.com`
- **Development URL**: `http://127.0.0.1:8787` (local Cloudflare Worker)

**Routing Configuration**:

| Route Pattern | Backend Service | App Runner URL |
|--------------|----------------|----------------|
| `/api/auth/*` | Auth Service | `https://yumaw38pdp.eu-central-1.awsapprunner.com` |
| `/api/admin/users/*` | User Service | `https://yumaw38pdp.eu-central-1.awsapprunner.com` |
| `/api/v1/*` | Catalog Service | `https://kykqma8nq4.eu-central-1.awsapprunner.com` |
| `/api/admin/orders/*` | Order Service | `https://mttci22rgj.eu-central-1.awsapprunner.com` |
| `/api/admin/carts/*` | Cart Service | *[To be migrated]* |
| `/api/admin/manufacturer/*` | Manufacturer Service | *[To be migrated]* |

**Features**:
- CORS handling
- Request routing
- Authentication token forwarding
- Error handling

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  User Browser                                               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ HTTPS
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  CloudFront (E2JL3VLX19R2ZH)                                │
│  Domain: admin.expotoworld.com                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Origin Request
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  S3 Bucket: expotoworld-editor-site                         │
│  - index.html                                               │
│  - static/js/*.js                                           │
│  - static/css/*.css                                         │
│  - static/media/*                                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Admin Panel React App (Running in Browser)                 │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ↓            ↓            ↓
   API Calls    Image Upload  Image Display
        │            │            │
        ↓            ↓            ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Cloudflare   │ │ S3 Bucket:   │ │ CloudFront   │
│ Worker       │ │ expotoworld- │ │ (E368C7TC..  │
│ device-api.  │ │ product-     │ │ assets.expo  │
│ expotoworld  │ │ images       │ │ toworld.com  │
└──────┬───────┘ └──────────────┘ └──────────────┘
       │
       │ Routes to Backend Services
       │
       ├─────────────────────────────────────────────┐
       │                                             │
       ↓                                             ↓
┌──────────────┐                              ┌──────────────┐
│ Auth Service │                              │ User Service │
│ App Runner   │                              │ App Runner   │
└──────────────┘                              └──────────────┘
       ↓                                             ↓
┌──────────────┐                              ┌──────────────┐
│ Catalog Svc  │                              │ Order Svc    │
│ App Runner   │                              │ App Runner   │
└──────────────┘                              └──────────────┘
```

## Technology Stack

### Frontend
- **React**: 18.2.0
- **Material-UI**: 5.15.1
- **React Router**: 6.20.1
- **Axios**: 1.6.2 (HTTP client)
- **TypeScript**: 4.9.5

### Build Tools
- **Create React App**: 5.0.1
- **Node.js**: 18.x

### Deployment
- **GitHub Actions**: CI/CD pipeline
- **AWS S3**: Static site hosting
- **AWS CloudFront**: CDN
- **AWS IAM**: Access control

## Environment Configuration

### Production
```env
REACT_APP_API_BASE_URL=https://device-api.expotoworld.com
```

### Development
```env
REACT_APP_API_BASE_URL=http://127.0.0.1:8787
```

## Security

### IAM Permissions

**Role**: `GitHubActionsECRPush-expotoworld`

**Policies**:
1. `ECRPushPolicy-expotoworld` - ECR access for backend services
2. `S3CloudFrontPolicy-expotoworld` - S3 and CloudFront access for admin panel

**S3CloudFrontPolicy Permissions**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "arn:aws:s3:::expotoworld-editor-site",
        "arn:aws:s3:::expotoworld-editor-site/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations"
      ],
      "Resource": "arn:aws:cloudfront::834076182408:distribution/E2JL3VLX19R2ZH"
    }
  ]
}
```

### Authentication
- JWT-based authentication
- Tokens stored in localStorage
- Automatic token refresh on 401 responses
- Refresh token rotation support

## Deployment Workflow

### GitHub Actions Workflow

**File**: `.github/workflows/admin-panel-deploy.yml`

**Triggers**:
- Push to `main` branch
- Changes in `admin-panel/**` or workflow file
- Manual workflow dispatch

**Steps**:
1. Checkout code
2. Setup Node.js 18
3. Install dependencies (`npm ci`)
4. Build React app with production env vars
5. Configure AWS credentials (OIDC)
6. Deploy to S3 with cache-control headers
7. Invalidate CloudFront cache

**Cache Control Strategy**:
- Static assets (JS, CSS, images): `public, max-age=31536000, immutable`
- HTML files: `public, max-age=0, must-revalidate`

## Missing Configuration

### ⚠️ Cloudflare Worker Setup Required

The admin panel requires a Cloudflare Worker to be configured at `device-api.expotoworld.com` to route API requests to backend services.

**Required Steps**:
1. Create Cloudflare Worker for `device-api.expotoworld.com`
2. Configure routing to App Runner services
3. Set up CORS headers
4. Configure authentication token forwarding

**Alternative Solutions**:
- Use AWS API Gateway instead of Cloudflare Worker
- Configure admin panel to call backend services directly (requires CORS configuration on each service)
- Use a different reverse proxy solution (e.g., nginx, Traefik)

## Troubleshooting

### Common Issues

1. **Build Failures**: Check TypeScript version compatibility with react-scripts
2. **Deployment Failures**: Verify IAM permissions for S3 and CloudFront
3. **API Connection Issues**: Verify Cloudflare Worker configuration
4. **CORS Errors**: Check API gateway CORS settings

### Logs and Monitoring

- **GitHub Actions**: View workflow runs at `https://github.com/expomadeinworld/expotoworld/actions`
- **CloudFront**: Monitor via AWS CloudWatch
- **S3**: Check bucket access logs if enabled

