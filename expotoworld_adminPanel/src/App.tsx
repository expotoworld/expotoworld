import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from '@contexts/ThemeContext';
import { AuthProvider, useAuth } from '@contexts/AuthContext';
import { MainLayout } from '@components/layout';
import {
  Dashboard,
  ProductsPage,
  OrdersPage,
  NotificationsPage,
  UsersPage,
  StoresPage,
  CategoriesPage,
  OrganizationsPage,
  RegionsPage,
  ContentPage,
  ReportsPage,
  SettingsPage,
  LoginPage,
  RolesPage,
} from '@pages';
import './App.css';

// Query client configuration
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

// Protected Route wrapper
interface ProtectedRouteProps {
  children: React.ReactNode;
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div 
        style={{ 
          display: 'flex', 
          justifyContent: 'center', 
          alignItems: 'center', 
          height: '100vh' 
        }}
        role="status"
        aria-busy="true"
        aria-label="Loading application"
      >
        Loading...
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
};

// App Routes
const AppRoutes: React.FC = () => {
  const { isAuthenticated } = useAuth();

  return (
    <Routes>
      {/* Public Routes */}
      <Route
        path="/login"
        element={
          isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />
        }
      />

      {/* Protected Routes */}
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <MainLayout />
          </ProtectedRoute>
        }
      >
        {/* Dashboard */}
        <Route index element={<Dashboard />} />

        {/* Products */}
        <Route path="products" element={<ProductsPage />} />

        {/* Orders */}
        <Route path="orders" element={<OrdersPage />} />

        {/* Notifications */}
        <Route path="notifications" element={<NotificationsPage />} />

        {/* Users */}
        <Route path="users" element={<UsersPage />} />

        {/* Stores */}
        <Route path="stores" element={<StoresPage />} />

        {/* Categories */}
        <Route path="categories" element={<CategoriesPage />} />

        {/* Organizations */}
        <Route path="organizations" element={<OrganizationsPage />} />

        {/* Regions */}
        <Route path="regions" element={<RegionsPage />} />

        {/* Roles & Permissions */}
        <Route path="roles" element={<RolesPage />} />

        {/* Content */}
        <Route path="content" element={<ContentPage />} />

        {/* Analytics (Reports) */}
        <Route path="analytics" element={<ReportsPage />} />

        {/* Settings */}
        <Route path="settings" element={<SettingsPage />} />
      </Route>

      {/* Catch all - redirect to dashboard */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

// Main App component
const App: React.FC = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
};

export default App;