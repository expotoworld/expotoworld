/**
 * Cloudflare Worker: API Gateway for EXPO to World Backend Services
 *
 * This worker routes API requests from frontend applications to the appropriate
 * backend microservices running on AWS App Runner (production) or localhost (development).
 *
 * Deployed at: device-api.expotoworld.com
 * Last Updated: November 27, 2025
 *
 * Production Backend Services (AWS App Runner):
 * - Auth Service: https://ge6ik5nm6e.eu-central-1.awsapprunner.com
 * - User Service: https://yumaw38pdp.eu-central-1.awsapprunner.com
 * - Catalog Service: https://kykqma8nq4.eu-central-1.awsapprunner.com
 * - Order Service: https://mttci22rgj.eu-central-1.awsapprunner.com
 * - Ebook Service: https://brdmfppyst.eu-central-1.awsapprunner.com
 *
 * Local Development Ports:
 * - Auth Service: http://localhost:8081
 * - User Service: http://localhost:8083
 * - Catalog Service: http://localhost:8080
 * - Order Service: http://localhost:8082
 * - Ebook Service: http://localhost:8084
 */

// Backend service URLs - use environment variables for local dev, fallback to production
const getBackendUrls = (env) => {
  // Check if running locally (wrangler dev sets certain env characteristics)
  const isLocal = env?.LOCAL_DEV === 'true' || typeof env?.AUTH_SERVICE === 'undefined';

  if (isLocal) {
    // Local development - connect to localhost services
    return {
      AUTH: env?.AUTH_SERVICE || 'http://localhost:8081',
      USER: env?.USER_SERVICE || 'http://localhost:8083',
      CATALOG: env?.CATALOG_SERVICE || 'http://localhost:8080',
      ORDER: env?.ORDER_SERVICE || 'http://localhost:8082',
      EBOOK: env?.EBOOK_SERVICE || 'http://localhost:8084',
    };
  }

  // Production - use AWS App Runner URLs
  return {
    AUTH: env?.AUTH_SERVICE || 'https://ge6ik5nm6e.eu-central-1.awsapprunner.com',
    USER: env?.USER_SERVICE || 'https://yumaw38pdp.eu-central-1.awsapprunner.com',
    CATALOG: env?.CATALOG_SERVICE || 'https://kykqma8nq4.eu-central-1.awsapprunner.com',
    ORDER: env?.ORDER_SERVICE || 'https://mttci22rgj.eu-central-1.awsapprunner.com',
    EBOOK: env?.EBOOK_SERVICE || 'https://brdmfppyst.eu-central-1.awsapprunner.com',
  };
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Get backend URLs based on environment
    const backends = getBackendUrls(env);

    // CORS configuration
    const allowedOrigins = [
      'https://admin.expotoworld.com',
      'https://huashangdao.expotoworld.com',
      'http://localhost:3000',
      'http://localhost:5173',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:5173',
    ];

    const origin = request.headers.get('Origin');
    const allowOrigin = allowedOrigins.includes(origin) ? origin : '*';

    const corsHeaders = {
      'Access-Control-Allow-Origin': allowOrigin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With, X-Require-Existing, X-Require-Role',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Max-Age': '86400',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: corsHeaders,
      });
    }

    // Route matching - ORDER MATTERS (most specific first)
    let backendUrl = null;

    // Admin routes (most specific first)
    if (path.startsWith('/api/admin/manufacturer')) {
      backendUrl = backends.ORDER;
    } else if (path.startsWith('/api/admin/users')) {
      backendUrl = backends.USER;
    } else if (path.startsWith('/api/admin/carts')) {
      // Admin cart management - handled by order service
      backendUrl = backends.ORDER;
    } else if (path.startsWith('/api/admin/orders')) {
      backendUrl = backends.ORDER;
    } else if (path.startsWith('/.well-known')) {
      // JWKS and other .well-known endpoints exposed at gateway root
      backendUrl = backends.AUTH;
    } else if (path.startsWith('/api/auth') || path.startsWith('/api/v1/auth')) {
      // Auth service - handles all authentication (both /api/auth and /api/v1/auth)
      backendUrl = backends.AUTH;
    } else if (path.startsWith('/api/v1/admin/auth')) {
      // Admin auth endpoints
      backendUrl = backends.AUTH;
    } else if (path.startsWith('/api/ebook')) {
      // Ebook service - handles both /api/ebook and /api/ebook/* routes
      backendUrl = backends.EBOOK;
    } else if (path.startsWith('/api/cart')) {
      // Cart routes - handled by order service
      backendUrl = backends.ORDER;
    } else if (path.startsWith('/api/orders')) {
      // Order routes
      backendUrl = backends.ORDER;
    } else if (path.startsWith('/api/v1')) {
      // Catalog service - products, categories, stores
      backendUrl = backends.CATALOG;
    }

    // If no route matches
    if (!backendUrl) {
      return new Response(
        JSON.stringify({
          error: 'Not Found',
          message: `No backend service configured for path: ${path}`,
          available_routes: [
            '/api/auth/*',
            '/api/v1/auth/*',
            '/api/v1/admin/auth/*',
            '/api/admin/users/*',
            '/api/admin/carts/*',
            '/api/admin/orders/*',
            '/api/admin/manufacturer/*',
            '/api/ebook/*',
            '/api/cart/*',
            '/api/orders/*',
            '/api/v1/*',
          ],
        }),
        {
          status: 404,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        }
      );
    }

    // Build backend request URL with optional path rewrite
    let backendPath = path;
    // Rewrite gateway-prefixed JWKS to auth-service root JWKS
    if (path === '/api/auth/.well-known/jwks.json') {
      backendPath = '/.well-known/jwks.json';
    }
    const backendRequestUrl = backendUrl + backendPath + url.search;

    // Clone headers and add forwarding headers
    const headers = new Headers(request.headers);
    headers.set('X-Forwarded-For', request.headers.get('CF-Connecting-IP') || '');
    headers.set('X-Forwarded-Proto', 'https');
    headers.set('X-Forwarded-Host', url.hostname);
    headers.set('X-Real-IP', request.headers.get('CF-Connecting-IP') || '');

    // Create backend request
    const backendRequest = new Request(backendRequestUrl, {
      method: request.method,
      headers: headers,
      body: request.body,
      redirect: 'follow',
    });

    try {
      // Forward to backend
      const response = await fetch(backendRequest);

      // Clone response and add CORS headers
      const modifiedResponse = new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers,
      });

      // Add CORS headers to response
      Object.entries(corsHeaders).forEach(([key, value]) => {
        modifiedResponse.headers.set(key, value);
      });

      return modifiedResponse;
    } catch (error) {
      console.error('Backend request failed:', {
        path,
        backend: backendUrl,
        error: error.message,
      });

      return new Response(
        JSON.stringify({
          error: 'Bad Gateway',
          message: 'Failed to connect to backend service',
          details: error.message,
          backend: backendUrl,
        }),
        {
          status: 502,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        }
      );
    }
  },
};

