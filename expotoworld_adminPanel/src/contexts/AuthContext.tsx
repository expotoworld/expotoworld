import React, { createContext, useContext, useState, useEffect, useCallback, ReactNode, useRef } from 'react';
import {
  sendAdminCode,
  verifyAdminCode,
  refreshAccessToken,
  logout as logoutApi,
  decodeJWT,
  isTokenExpired,
  getDeviceId,
  type TokenResponse,
} from '@services/authApi';

// Admin user extracted from JWT
interface AdminUser {
  id: string;
  email: string;
  role: string;
  orgs?: Array<{
    id: string;
    type: string;
    role: string;
    name: string;
  }>;
}

// Authentication step in the OTP flow
type AuthStep = 'email' | 'otp' | 'authenticated';

interface AuthContextType {
  user: AdminUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  authStep: AuthStep;
  pendingEmail: string | null;
  // OTP flow actions
  sendCode: (email: string) => Promise<void>;
  verifyCode: (code: string) => Promise<void>;
  resendCode: () => Promise<void>;
  resetAuthStep: () => void;
  // Session actions
  logout: () => Promise<void>;
  // Token management
  getAccessToken: () => Promise<string | null>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const STORAGE_KEY = 'expotoworld-admin-auth';
const REFRESH_BUFFER_MS = 60 * 1000; // Refresh 1 minute before expiry
const DEFAULT_REFRESH_TTL_DAYS = 90; // Fallback if backend doesn't send refresh_expires_at

interface StoredAuth {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
  refreshExpiresAt: string; // ISO 8601 timestamp
}

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [authStep, setAuthStep] = useState<AuthStep>('email');
  const [pendingEmail, setPendingEmail] = useState<string | null>(null);
  const [tokens, setTokens] = useState<StoredAuth | null>(null);
  const refreshTimerRef = useRef<number | null>(null);

  // Extract user from JWT
  const extractUserFromToken = useCallback((accessToken: string): AdminUser | null => {
    const payload = decodeJWT(accessToken);
    if (!payload) return null;
    
    return {
      id: payload.sub,
      email: payload.email || '',
      role: payload.role,
      orgs: payload.orgs,
    };
  }, []);

  // Save tokens to storage
  const saveTokens = useCallback((response: TokenResponse) => {
    const expiresAt = Date.now() + response.expires_in * 1000;
    // Use backend's refresh_expires_at, then refresh_expires_in, then default 90 days
    const refreshExpiresAt =
      response.refresh_expires_at ||
      (response.refresh_expires_in
        ? new Date(Date.now() + response.refresh_expires_in * 1000).toISOString()
        : new Date(Date.now() + DEFAULT_REFRESH_TTL_DAYS * 24 * 60 * 60 * 1000).toISOString());

    const storedAuth: StoredAuth = {
      accessToken: response.access_token,
      refreshToken: response.refresh_token,
      expiresAt,
      refreshExpiresAt,
    };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(storedAuth));
    setTokens(storedAuth);
    return storedAuth;
  }, []);

  // Clear tokens from storage (preserves device ID for stable fingerprinting)
  const clearTokens = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
    setTokens(null);
    setUser(null);
    setAuthStep('email');
    setPendingEmail(null);
    if (refreshTimerRef.current) {
      clearTimeout(refreshTimerRef.current);
      refreshTimerRef.current = null;
    }
  }, []);

  // Refresh tokens
  const refreshTokens = useCallback(async (): Promise<StoredAuth | null> => {
    const stored = tokens || JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null');
    if (!stored?.refreshToken) {
      clearTokens();
      return null;
    }

    try {
      const response = await refreshAccessToken(stored.refreshToken);
      const newTokens = saveTokens(response);
      const newUser = extractUserFromToken(response.access_token);
      setUser(newUser);
      return newTokens;
    } catch (err) {
      console.error('Token refresh failed:', err);
      clearTokens();
      return null;
    }
  }, [tokens, clearTokens, saveTokens, extractUserFromToken]);

  // Schedule token refresh
  const scheduleRefresh = useCallback((expiresAt: number) => {
    if (refreshTimerRef.current) {
      clearTimeout(refreshTimerRef.current);
    }
    
    const timeUntilRefresh = expiresAt - Date.now() - REFRESH_BUFFER_MS;
    if (timeUntilRefresh <= 0) {
      // Token about to expire or expired, refresh now
      refreshTokens();
      return;
    }

    refreshTimerRef.current = window.setTimeout(() => {
      refreshTokens();
    }, timeUntilRefresh);
  }, [refreshTokens]);

  // Check for existing session on mount
  useEffect(() => {
    // Ensure device ID is initialized early
    getDeviceId();

    const checkAuth = async () => {
      try {
        const stored = localStorage.getItem(STORAGE_KEY);
        if (!stored) {
          setIsLoading(false);
          return;
        }

        const parsed: StoredAuth = JSON.parse(stored);
        setTokens(parsed);

        // Check if access token is expired
        if (isTokenExpired(parsed.accessToken)) {
          // Try to refresh
          const newTokens = await refreshTokens();
          if (!newTokens) {
            setIsLoading(false);
            return;
          }
          const newUser = extractUserFromToken(newTokens.accessToken);
          setUser(newUser);
          setAuthStep('authenticated');
          scheduleRefresh(newTokens.expiresAt);
        } else {
          // Token still valid
          const user = extractUserFromToken(parsed.accessToken);
          setUser(user);
          setAuthStep('authenticated');
          scheduleRefresh(parsed.expiresAt);
        }
      } catch (error) {
        console.error('Auth check failed:', error);
        clearTokens();
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();

    // Visibility change listener: refresh token when tab becomes visible
    // This handles Chrome's aggressive timer throttling for background tabs
    const handleVisibility = () => {
      if (document.visibilityState !== 'visible') return;
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return;
      try {
        const stored: StoredAuth = JSON.parse(raw);
        // If access token is expired or within 60 s of expiry, refresh proactively
        if (isTokenExpired(stored.accessToken)) {
          refreshTokens().then((fresh) => {
            if (fresh) {
              scheduleRefresh(fresh.expiresAt);
            }
          });
        }
      } catch {
        // Malformed storage – ignore
      }
    };
    document.addEventListener('visibilitychange', handleVisibility);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibility);
      if (refreshTimerRef.current) {
        clearTimeout(refreshTimerRef.current);
      }
    };
  }, []);

  // Send verification code
  const sendCode = async (email: string): Promise<void> => {
    setIsLoading(true);
    setError(null);
    try {
      await sendAdminCode(email);
      setPendingEmail(email);
      setAuthStep('otp');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to send verification code';
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  // Verify OTP code
  const verifyCode = async (code: string): Promise<void> => {
    if (!pendingEmail) {
      throw new Error('No pending email address');
    }

    setIsLoading(true);
    setError(null);
    try {
      const response = await verifyAdminCode(pendingEmail, code);
      
      // Save tokens (including refresh_expires_at from backend)
      const newTokens = saveTokens(response);
      
      // Extract user from token
      const newUser = extractUserFromToken(response.access_token);
      if (!newUser) {
        throw new Error('Invalid token received');
      }

      // Verify this is an admin user
      if (newUser.role !== 'Admin') {
        clearTokens();
        throw new Error('Access denied: Not an admin user');
      }

      setUser(newUser);
      setAuthStep('authenticated');
      setPendingEmail(null);
      scheduleRefresh(newTokens.expiresAt);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Verification failed';
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  // Resend verification code
  const resendCode = async (): Promise<void> => {
    if (!pendingEmail) {
      throw new Error('No pending email address');
    }
    await sendCode(pendingEmail);
  };

  // Reset auth step (go back to email)
  const resetAuthStep = () => {
    setAuthStep('email');
    setPendingEmail(null);
    setError(null);
  };

  // Logout
  const logout = async (): Promise<void> => {
    const stored = tokens || JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null');
    if (stored?.refreshToken) {
      await logoutApi(stored.refreshToken);
    }
    clearTokens();
  };

  // Get valid access token (refresh if needed)
  const getAccessToken = async (): Promise<string | null> => {
    const stored = tokens || JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null');
    if (!stored?.accessToken) return null;

    if (isTokenExpired(stored.accessToken)) {
      const newTokens = await refreshTokens();
      return newTokens?.accessToken || null;
    }

    return stored.accessToken;
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: authStep === 'authenticated' && !!user,
        isLoading,
        error,
        authStep,
        pendingEmail,
        sendCode,
        verifyCode,
        resendCode,
        resetAuthStep,
        logout,
        getAccessToken,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export default AuthContext;
