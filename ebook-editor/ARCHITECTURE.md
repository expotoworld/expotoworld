# Ebook Editor - Architecture Documentation

## Overview

The Ebook Editor is a web-based rich text editor built with React, TypeScript, and TipTap. It provides a WYSIWYG editing experience for authors to create and edit ebook content.

## Technology Stack

- **Frontend Framework**: React 18.2.0
- **Build Tool**: Vite 5.3.4
- **Language**: TypeScript 5.5.4
- **Editor**: TipTap 2.4.0 (ProseMirror-based)
- **HTTP Client**: Axios 1.7.2
- **Internationalization**: i18next 25.5.3

## Infrastructure Components

### 1. Static Site Hosting

- **S3 Bucket**: `expotoworld-ebook-website`
- **Region**: eu-central-1 (Frankfurt)
- **Purpose**: Hosts the compiled React application (HTML, JS, CSS, assets)
- **Access**: Private (CloudFront OAC only)

### 2. Content Delivery Network (CDN)

- **CloudFront Distribution**: `E25UL5QH3I1VIU`
- **Domain**: `huashangdao.expotoworld.com`
- **SSL Certificate**: AWS Certificate Manager (ACM) in us-east-1
- **Origin Access Control (OAC)**: `E305BF2ASOHOAY`
- **Purpose**: HTTPS termination, global content delivery, caching

### 3. API Gateway (Cloudflare Worker)

- **Production URL**: `https://device-api.expotoworld.com` ✅ **OPERATIONAL**
- **Purpose**: Routes API requests to backend services
- **CORS**: Enabled for `https://huashangdao.expotoworld.com`
- **Routes**:
  - `/api/auth/*` → Auth Service
  - `/api/ebook/*` → Ebook Service

## Deployment Process

### GitHub Actions Workflow

**File**: `.github/workflows/ebook-editor-deploy.yml`

**Trigger**: Push to `main` branch with changes in `ebook-editor/` directory

**Steps**:
1. Checkout code
2. Setup Node.js 18
3. Install dependencies (`npm ci`)
4. Build application (`npm run build`)
   - Sets production environment variables
   - Compiles TypeScript to JavaScript
   - Bundles with Vite
   - Outputs to `dist/` directory
5. Configure AWS credentials (OIDC)
6. Deploy to S3
   - Sync `dist/` to `s3://expotoworld-ebook-website/`
   - Set cache headers:
     - Static assets (JS, CSS): `max-age=31536000, immutable`
     - HTML/JSON: `max-age=0, must-revalidate`
7. Invalidate CloudFront cache (`/*`)

### Build Configuration

**Vite Config** (`vite.config.ts`):
```typescript
{
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: process.env.VITE_API_BASE || 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
}
```

### Environment Variables

**Production** (`.env.production`):
```
VITE_API_BASE=https://device-api.expotoworld.com
VITE_AUTH_BASE=https://device-api.expotoworld.com
```

**Development** (`.env.development`):
```
VITE_API_BASE=http://localhost:8084
VITE_AUTH_BASE=http://localhost:8081
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Browser                             │
│                  https://huashangdao.expotoworld.com            │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CloudFront Distribution                       │
│                      E25UL5QH3I1VIU                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Origin Access Control (OAC): E305BF2ASOHOAY             │  │
│  │  SSL Certificate: ACM (us-east-1)                        │  │
│  │  Cache Behavior: Static assets cached, HTML not cached  │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │ S3 Origin Request (OAC signed)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      S3 Bucket (Private)                         │
│                  expotoworld-ebook-website                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  index.html                                              │  │
│  │  assets/                                                 │  │
│  │    ├── main.[hash].js                                    │  │
│  │    ├── main.[hash].css                                   │  │
│  │    └── ...                                               │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    API Requests Flow                             │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Cloudflare Worker API Gateway                       │
│            https://device-api.expotoworld.com                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CORS: huashangdao.expotoworld.com                       │  │
│  │  Routes:                                                 │  │
│  │    /api/auth/* → Auth Service (App Runner)              │  │
│  │    /api/ebook/* → Ebook Service (App Runner)            │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Security and Permissions

### S3 Bucket Policy

The S3 bucket is **private** and only accessible via CloudFront OAC.

**Policy**: See `ebook-editor/S3_BUCKET_POLICY.md`

### IAM Role for GitHub Actions

**Role**: `GitHubActionsECRPush-expotoworld`  
**Policy**: `S3CloudFrontPolicy-expotoworld`

**Permissions**:
- S3: PutObject, GetObject, DeleteObject, ListBucket on `expotoworld-ebook-website`
- CloudFront: CreateInvalidation, GetInvalidation, ListInvalidations on `E25UL5QH3I1VIU`

### Authentication Flow

1. User enters email on login page
2. Verification code sent via Auth Service
3. User enters code
4. Auth Service validates and returns JWT token + refresh token
5. Tokens stored in localStorage
6. Axios interceptor attaches Bearer token to all API requests
7. Automatic token refresh when access token expires

## Editor Features

### TipTap Extensions

- **StarterKit**: Basic formatting (bold, italic, headings, lists, etc.)
- **Link**: Hyperlink support
- **Underline**: Underline text
- **Highlight**: Text highlighting
- **Superscript/Subscript**: Scientific notation
- **TextAlign**: Left, center, right, justify
- **Image**: Image embedding
- **TaskList/TaskItem**: Checklist support
- **Placeholder**: Empty editor placeholder text

### Internationalization

- **Languages**: English (en), Chinese (zh)
- **Library**: i18next + react-i18next
- **Locale Files**: `src/locales/en.json`, `src/locales/zh.json`

## Local Development

### Prerequisites

- Node.js 18+
- npm or yarn

### Setup

```bash
cd ebook-editor
npm install
```

### Run Development Server

```bash
npm run dev
```

Runs on `http://localhost:5173` with API proxy to local backend services.

### Build for Production

```bash
npm run build
```

Outputs to `dist/` directory.

### Preview Production Build

```bash
npm run preview
```

## Troubleshooting

### "Access Denied" Error

**Symptoms**: XML error message with `<Code>AccessDenied</Code>`

**Causes**:
1. S3 bucket policy missing or incorrect
2. CloudFront OAC not configured
3. CloudFront distribution ARN mismatch

**Solution**: See `ebook-editor/S3_BUCKET_POLICY.md`

### Build Failures

**Common Issues**:
- TypeScript errors: Check `tsconfig.json` and fix type errors
- Missing dependencies: Run `npm ci` to install exact versions
- Environment variables: Ensure `.env.production` exists

### API Connection Issues

**Symptoms**: Network errors, CORS errors

**Checks**:
1. Verify Cloudflare Worker is deployed
2. Check CORS configuration allows `huashangdao.expotoworld.com`
3. Verify backend services are running
4. Check browser console for detailed error messages

## Monitoring and Logs

### CloudFront Logs

- **Access Logs**: Can be enabled in CloudFront distribution settings
- **Real-time Logs**: Available via CloudWatch

### Application Logs

- **Browser Console**: Client-side errors and warnings
- **Backend Logs**: Check App Runner service logs for API errors

## Related Documentation

- [S3 Bucket Policy](./S3_BUCKET_POLICY.md)
- [CloudFront OAC Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [TipTap Documentation](https://tiptap.dev/)
- [Vite Documentation](https://vitejs.dev/)

## Change Log

- **2025-10-15**: Initial migration from madeinworld to expotoworld
  - Migrated source code and dependencies
  - Updated domain references to expotoworld.com
  - Configured S3 bucket and CloudFront distribution
  - Created GitHub Actions deployment workflow
  - Updated IAM permissions

