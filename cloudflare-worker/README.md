# Cloudflare Worker - API Gateway

This directory contains the Cloudflare Worker that acts as an API gateway for the EXPO to World backend services.

## Overview

**Worker Name**: `device-api-gateway`  
**Deployed URL**: `https://device-api.expotoworld.com`  
**Purpose**: Routes API requests from frontend applications to backend microservices on AWS App Runner

## Architecture

```
Frontend Apps (admin-panel, ebook-editor, mobile app)
                    ↓
        device-api.expotoworld.com
                    ↓
         Cloudflare Worker (this)
                    ↓
    ┌───────────────┴───────────────┐
    ↓               ↓               ↓
Auth Service   Catalog Service   Order Service
User Service   Ebook Service
```

## Routing Configuration

| Route Pattern | Backend Service | App Runner URL |
|--------------|----------------|----------------|
| `/api/auth/*` | Auth Service | `https://ge6ik5nm6e.eu-central-1.awsapprunner.com` |
| `/api/admin/users/*` | User Service | `https://yumaw38pdp.eu-central-1.awsapprunner.com` |
| `/api/v1/*` | Catalog Service | `https://kykqma8nq4.eu-central-1.awsapprunner.com` |
| `/api/admin/orders/*` | Order Service | `https://mttci22rgj.eu-central-1.awsapprunner.com` |
| `/api/admin/manufacturer/*` | Order Service | `https://mttci22rgj.eu-central-1.awsapprunner.com` |
| `/api/ebooks/*` | Ebook Service | `https://brdmfppyst.eu-central-1.awsapprunner.com` |
| `/api/cart/*` | Order Service | `https://mttci22rgj.eu-central-1.awsapprunner.com` |
| `/api/orders/*` | Order Service | `https://mttci22rgj.eu-central-1.awsapprunner.com` |

## Deployment

### Prerequisites

1. **Node.js** 18 or later
2. **Cloudflare Account** with access to `expotoworld.com` zone

### First-Time Setup

1. **Install Wrangler CLI**:
   ```bash
   npm install -g wrangler
   ```

2. **Login to Cloudflare**:
   ```bash
   wrangler login
   ```
   This will open a browser window for authentication.

3. **Verify Configuration**:
   ```bash
   cd cloudflare-worker
   wrangler whoami
   ```
   Should show your Cloudflare account details.

### Deploy the Worker

From the `cloudflare-worker/` directory:

```bash
cd cloudflare-worker
wrangler deploy
```

**Expected Output**:
```
✨ Built successfully
✨ Uploaded successfully
✨ Deployed device-api-gateway
   https://device-api.expotoworld.com
```

### Verify Deployment

Test the worker is routing correctly:

```bash
# Test auth service routing
curl https://device-api.expotoworld.com/api/auth/admin/send-verification \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'

# Test catalog service routing
curl https://device-api.expotoworld.com/api/v1/products

# Test health check
curl https://device-api.expotoworld.com/
```

## Local Development

To test the worker locally before deploying:

```bash
cd cloudflare-worker
wrangler dev
```

This starts a local server at `http://localhost:8787` that mimics the production worker.

## Troubleshooting

### Issue: "No route found for worker"

**Solution**: Make sure the route is configured in `wrangler.toml`:
```toml
routes = [
  { pattern = "device-api.expotoworld.com/*", zone_name = "expotoworld.com" }
]
```

### Issue: "Authentication failed"

**Solution**: Re-authenticate with Cloudflare:
```bash
wrangler logout
wrangler login
```

### Issue: "Worker still shows old version"

**Solution**: 
1. Deploy again: `wrangler deploy`
2. Clear Cloudflare cache in dashboard
3. Wait 30 seconds for propagation

### Issue: CORS errors in browser

**Solution**: Check that your frontend origin is in the `allowedOrigins` array in `worker.js`:
```javascript
const allowedOrigins = [
  'https://admin.expotoworld.com',
  'https://huashangdao.expotoworld.com',
  'http://localhost:3000',
  'http://localhost:5173',
];
```

## Updating the Worker

When you need to update the worker (rare):

1. Edit `worker.js` with your changes
2. Deploy: `wrangler deploy`
3. Verify: Test the affected routes

**Common reasons to update**:
- Adding a new backend service
- Changing backend service URLs
- Modifying CORS configuration
- Adding new route patterns

## Files

- `wrangler.toml` - Worker configuration (account ID, routes, settings)
- `worker.js` - Worker code (routing logic, CORS, error handling)
- `README.md` - This file

## Security Notes

- ✅ CORS is configured to allow only specific origins
- ✅ All backend requests use HTTPS
- ✅ Client IP is forwarded to backend services
- ✅ No sensitive credentials stored in worker code
- ✅ Worker runs in Cloudflare's secure edge network

## Monitoring

View worker logs and analytics:
```bash
wrangler tail
```

Or in Cloudflare Dashboard:
**Workers & Pages → device-api-gateway → Logs**

## Support

For issues with:
- **Worker deployment**: Check Cloudflare Workers documentation
- **Backend routing**: Verify App Runner service URLs in `worker.js`
- **CORS issues**: Check `allowedOrigins` configuration
- **Performance**: Review Cloudflare Analytics dashboard

