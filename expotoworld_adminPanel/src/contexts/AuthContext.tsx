import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

// TODO: NEED TO FULLY IMPLEMENT - Connect to auth-service backend

interface AdminUser {
  id: string;
  username: string;
  email: string;
  role: 'admin';
  permissions: string[];
}

interface AuthContextType {
  user: AdminUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  hasPermission: (permission: string) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const STORAGE_KEY = 'expotoworld-admin-auth';

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Check for existing session on mount
  useEffect(() => {
    const checkAuth = async () => {
      try {
        const stored = localStorage.getItem(STORAGE_KEY);
        if (stored) {
          const parsed = JSON.parse(stored);
          // TODO: NEED TO FULLY IMPLEMENT - Validate token with backend
          setUser(parsed.user);
        }
      } catch (error) {
        console.error('Auth check failed:', error);
        localStorage.removeItem(STORAGE_KEY);
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, []);

  const login = async (email: string, password: string): Promise<void> => {
    setIsLoading(true);
    setError(null);
    try {
      // TODO: DUMMY DATA - Replace with actual auth-service API call
      // POST /api/auth/login
      await new Promise((resolve) => setTimeout(resolve, 1000)); // Simulate API call

      // Mock successful login
      if (email === 'admin@expotoworld.com' && password === 'admin123') {
        const mockUser: AdminUser = {
          id: '1',
          username: 'admin',
          email: 'admin@expotoworld.com',
          role: 'admin',
          permissions: ['*'], // Admin has all permissions
        };

        setUser(mockUser);
        localStorage.setItem(
          STORAGE_KEY,
          JSON.stringify({
            user: mockUser,
            token: 'mock-jwt-token', // TODO: Store actual JWT token
          })
        );
      } else {
        throw new Error('Invalid credentials');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem(STORAGE_KEY);
    // TODO: NEED TO FULLY IMPLEMENT - Call logout endpoint to invalidate token
  };

  const hasPermission = (permission: string): boolean => {
    if (!user) return false;
    // Admin has all permissions
    if (user.permissions.includes('*')) return true;
    return user.permissions.includes(permission);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        isLoading,
        error,
        login,
        logout,
        hasPermission,
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
