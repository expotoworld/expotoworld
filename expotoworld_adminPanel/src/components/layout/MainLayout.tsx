import React from 'react';
import { Outlet } from 'react-router-dom';
import { Box, Container } from '@mui/material';
import Header from './Header';
import { componentSpacing } from '@theme/spacing';

const MainLayout: React.FC = () => {
  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      {/* Header */}
      <Header />

      {/* Main Content Area */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          display: 'flex',
          flexDirection: 'column',
          minHeight: '100vh',
          pt: `${componentSpacing.headerHeight}px`,
        }}
      >
        {/* Page Content */}
        <Box
          sx={{
            flexGrow: 1,
            py: 4,
            px: { xs: 3, sm: 4, md: 6, lg: 8 },
            bgcolor: 'background.default',
            overflow: 'auto',
          }}
        >
          <Container maxWidth="xl" disableGutters>
            <Outlet />
          </Container>
        </Box>
      </Box>
    </Box>
  );
};

export default MainLayout;
