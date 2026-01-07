/**
 * Auth API Service
 * Handles communication with the auth-service backend for OTP-based authentication.
 */

// Types for auth API responses
export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
}

export interface SendCodeResponse {
  message: string;
}

export interface ApiError {
  error: string;
}

// JWT payload structure (matches backend jwt.MapClaims)
export interface JWTPayload {
  sub: string; // User ID
  email?: string;
  role: string;
  iat: number;
  exp: number;
  iss: string;
  orgs?: Array<{
    id: string;
    type: string;
    role: string;
    name: string;
  }>;
}

// Decode JWT without verification (for client-side use only)
export function decodeJWT(token: string): JWTPayload | null {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch {
    return null;
  }
}

// Check if token is expired (with 1 minute buffer)
export function isTokenExpired(token: string): boolean {
  const payload = decodeJWT(token);
  if (!payload) return true;
  const now = Math.floor(Date.now() / 1000);
  return payload.exp < now + 60; // 1 minute buffer
}

// Get auth API base URL
function getAuthApiUrl(): string {
  // Auth service runs on a different port than the main API
  // Default to localhost:8081 for development
  return import.meta.env.VITE_AUTH_API_URL || 'http://localhost:8081';
}

/**
 * Send verification code to admin email
 */
export async function sendAdminCode(email: string): Promise<void> {
  const response = await fetch(`${getAuthApiUrl()}/api/v1/admin/auth/send-code`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email }),
  });

  if (!response.ok) {
    const error: ApiError = await response.json().catch(() => ({ error: 'Failed to send code' }));
    throw new Error(error.error);
  }
}

/**
 * Verify OTP code and get tokens
 */
export async function verifyAdminCode(email: string, code: string): Promise<TokenResponse> {
  const response = await fetch(`${getAuthApiUrl()}/api/v1/admin/auth/verify-code`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, code }),
  });

  if (!response.ok) {
    const error: ApiError = await response.json().catch(() => ({ error: 'Verification failed' }));
    throw new Error(error.error);
  }

  return response.json();
}

/**
 * Refresh access token using refresh token
 */
export async function refreshAccessToken(refreshToken: string): Promise<TokenResponse> {
  const response = await fetch(`${getAuthApiUrl()}/api/v1/auth/refresh`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ refresh_token: refreshToken }),
  });

  if (!response.ok) {
    const error: ApiError = await response.json().catch(() => ({ error: 'Token refresh failed' }));
    throw new Error(error.error);
  }

  return response.json();
}

/**
 * Logout and invalidate refresh token
 */
export async function logout(refreshToken: string): Promise<void> {
  try {
    await fetch(`${getAuthApiUrl()}/api/v1/auth/logout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });
  } catch {
    // Silently fail - we still want to clear local storage
  }
}
