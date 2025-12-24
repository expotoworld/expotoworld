import React from 'react';
import { Card, CardContent, Box, Typography, Skeleton, alpha, useTheme } from '@mui/material';
import { TrendingUp as TrendingUpIcon, TrendingDown as TrendingDownIcon } from '@mui/icons-material';

interface StatCardProps {
  title: string;
  value: string | number;
  change?: number; // Percentage change
  changeLabel?: string;
  icon?: React.ReactNode;
  color?: 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'info';
  loading?: boolean;
}

const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  change,
  changeLabel,
  icon,
  color = 'primary',
  loading = false,
}) => {
  const theme = useTheme();
  const isPositive = change !== undefined && change >= 0;

  if (loading) {
    return (
      <Card elevation={0} sx={{ height: '100%' }}>
        <CardContent>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <Box sx={{ flex: 1 }}>
              <Skeleton variant="text" width="60%" height={24} />
              <Skeleton variant="text" width="40%" height={40} sx={{ mt: 1 }} />
              <Skeleton variant="text" width="50%" height={20} sx={{ mt: 1 }} />
            </Box>
            <Skeleton variant="circular" width={48} height={48} />
          </Box>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card
      elevation={0}
      sx={{
        height: '100%',
        transition: 'box-shadow 0.2s ease-in-out',
        '&:hover': {
          boxShadow: theme.shadows[2],
        },
      }}
    >
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <Box sx={{ flex: 1 }}>
            <Typography
              variant="body2"
              color="text.secondary"
              sx={{ fontWeight: 500, mb: 1 }}
            >
              {title}
            </Typography>
            <Typography
              variant="h4"
              sx={{
                fontWeight: 700,
                color: 'text.primary',
                lineHeight: 1.2,
              }}
            >
              {value}
            </Typography>
            {change !== undefined && (
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 0.5,
                  mt: 1,
                }}
              >
                {isPositive ? (
                  <TrendingUpIcon
                    sx={{ fontSize: 18, color: 'success.main' }}
                  />
                ) : (
                  <TrendingDownIcon
                    sx={{ fontSize: 18, color: 'error.main' }}
                  />
                )}
                <Typography
                  variant="body2"
                  sx={{
                    color: isPositive ? 'success.main' : 'error.main',
                    fontWeight: 500,
                  }}
                >
                  {isPositive ? '+' : ''}{change.toFixed(1)}%
                </Typography>
                {changeLabel && (
                  <Typography variant="body2" color="text.secondary">
                    {changeLabel}
                  </Typography>
                )}
              </Box>
            )}
          </Box>
          {icon && (
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: 2,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                bgcolor: alpha(theme.palette[color].main, 0.1),
                color: `${color}.main`,
              }}
            >
              {icon}
            </Box>
          )}
        </Box>
      </CardContent>
    </Card>
  );
};

export default StatCard;
