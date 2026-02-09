/**
 * Auth API Service
 * Handles communication with the auth-service backend for OTP-based authentication.
 * Supports httpOnly cookie dual-storage and persistent device fingerprinting.
 */

// ============================================
// DEVICE ID MANAGEMENT
// ============================================

const DEVICE_ID_KEY = 'admin_device_id';

/** Generate a v4-like UUID for device identification. */
function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/** Get or create a persistent device ID for stable fingerprinting. */
export function getDeviceId(): string {
  let id = localStorage.getItem(DEVICE_ID_KEY);
  if (!id) {
    id = generateUUID();
    localStorage.setItem(DEVICE_ID_KEY, id);
  }
  return id;
}

// ============================================
// TYPES
// ============================================

// Types for auth API responses
export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
  refresh_expires_in?: number;
  refresh_expires_at?: string;
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

// ============================================
// JWT UTILITIES
// ============================================

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

// ============================================
// API CONFIG
// ============================================

// Get auth API base URL
function getAuthApiUrl(): string {
  // Auth service runs on a different port than the main API
  // Default to localhost:8081 for development
  return import.meta.env.VITE_AUTH_API_URL || 'http://localhost:8081';
}

/** Build common headers including device ID. */
function authHeaders(): Record<string, string> {
  return {
    'Content-Type': 'application/json',
    'X-Device-Id': getDeviceId(),
  };
}

// ============================================
// AUTH API FUNCTIONS
// ============================================

/**
 * Send verification code to admin email
 */
export async function sendAdminCode(email: string): Promise<void> {
  const response = await fetch(`${getAuthApiUrl()}/api/v1/admin/auth/send-code`, {
    method: 'POST',
    headers: authHeaders(),
    credentials: 'include',
    body: JSON.stringify({ email }),
  });

  if (!response.ok) {
    const error: ApiError = await response.json().catch(() => ({ error: 'Failed to send code' }));
    throw new Error(error.error);
  }
}

/**
 * Verify OTP code and get tokens.
 * The backend also sets an httpOnly cookie as backup storage.
 */
export async function verifyAdminCode(email: string, code: string): Promise<TokenResponse> {
  const response = await fetch(`${getAuthApiUrl()}/api/v1/admin/auth/verify-code`, {
    method: 'POST',
    headers: authHeaders(),
    credentials: 'include',
    body: JSON.stringify({ email, code }),
  });

  if (!response.ok) {
    const error: ApiError = await response.json().catch(() => ({ error: 'Verification failed' }));
    throw new Error(error.error);
  }

  return response.json();
}

/**
 * Refresh access token using refresh token.
 * Sends the refresh token in the body AND accepts the httpOnly cookie as fallback.
 */
export async function refreshAccessToken(refreshToken: string): Promise<TokenResponse> {
  const response = await fetch(`${getAuthApiUrl()}/api/v1/auth/refresh`, {
    method: 'POST',
    headers: authHeaders(),
    credentials: 'include',
    body: JSON.stringify({ refresh_token: refreshToken }),
  });

  if (!response.ok) {
    const error: ApiError = await response.json().catch(() => ({ error: 'Token refresh failed' }));
    throw new Error(error.error);
  }

  return response.json();
}

/**
 * Logout and invalidate refresh token.
 * Sends refresh token in body AND the backend also clears the httpOnly cookie.
 */
export async function logout(refreshToken: string): Promise<void> {
  try {
    await fetch(`${getAuthApiUrl()}/api/v1/auth/logout`, {
      method: 'POST',
      headers: authHeaders(),
      credentials: 'include',
      body: JSON.stringify({ refresh_token: refreshToken }),
    });
  } catch {
    // Silently fail - we still want to clear local storage
  }
}
