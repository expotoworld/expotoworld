import React from 'react';
import { Typography, Box } from '@mui/material';

interface PageTitleProps {
  title: string;
  description?: string;
  actions?: React.ReactNode;
}

const PageTitle: React.FC<PageTitleProps> = ({ title, description, actions }) => {
  return (
    <Box sx={{ mt: 1, mb: 2.5, ml: 0.5, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
      <Box>
        <Typography variant="h3" fontWeight={800} sx={{ fontSize: '2rem', lineHeight: 1.2 }}>
          {title}
        </Typography>
        {description && (
          <Typography variant="body1" color="text.secondary" sx={{ mt: 0.5 }}>
            {description}
          </Typography>
        )}
      </Box>
      {actions && (
        <Box sx={{ flexShrink: 0 }}>
          {actions}
        </Box>
      )}
    </Box>
  );
};

export default PageTitle;
