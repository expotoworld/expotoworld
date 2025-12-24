import React from 'react';
import { Chip, ChipProps } from '@mui/material';
import type { OrderStatus } from '@/types';

interface StatusChipProps {
  status: OrderStatus | string;
  size?: ChipProps['size'];
}

const getStatusConfig = (status: string): { color: ChipProps['color']; label: string } => {
  const configs: Record<string, { color: ChipProps['color']; label: string }> = {
    // Order statuses
    pending: { color: 'warning', label: 'Pending' },
    confirmed: { color: 'info', label: 'Confirmed' },
    processing: { color: 'info', label: 'Processing' },
    ready_for_pickup: { color: 'primary', label: 'Ready for Pickup' },
    shipped: { color: 'primary', label: 'Shipped' },
    delivered: { color: 'success', label: 'Delivered' },
    completed: { color: 'success', label: 'Completed' },
    cancelled: { color: 'error', label: 'Cancelled' },
    refunded: { color: 'default', label: 'Refunded' },
    disputed: { color: 'error', label: 'Disputed' },

    // User statuses
    active: { color: 'success', label: 'Active' },
    suspended: { color: 'error', label: 'Suspended' },
    inactive: { color: 'default', label: 'Inactive' },

    // General
    enabled: { color: 'success', label: 'Enabled' },
    disabled: { color: 'default', label: 'Disabled' },
    draft: { color: 'warning', label: 'Draft' },
    published: { color: 'success', label: 'Published' },
  };

  return configs[status.toLowerCase()] || { color: 'default', label: status };
};

const StatusChip: React.FC<StatusChipProps> = ({ status, size = 'small' }) => {
  const { color, label } = getStatusConfig(status);

  return (
    <Chip
      label={label}
      color={color}
      size={size}
      sx={{
        fontWeight: 500,
        textTransform: 'capitalize',
      }}
    />
  );
};

export default StatusChip;
