import React, { useState } from 'react';
import {
  Button,
  Popper,
  Grow,
  ClickAwayListener,
  Box,
  Fab,
  Typography,
  useTheme,
} from '@mui/material';

export interface ActionItem {
  label: string;
  icon?: React.ReactNode;
  onClick: () => void;
  disabled?: boolean;
  color?: 'primary' | 'secondary' | 'success' | 'error' | 'info' | 'warning';
}

interface ActionMenuProps {
  actions: ActionItem[];
  buttonLabel?: string;
}

const ActionMenu: React.FC<ActionMenuProps> = ({
  actions,
  buttonLabel = 'I need to...',
}) => {
  const theme = useTheme();
  const isDarkMode = theme.palette.mode === 'dark';
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);

  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(anchorEl ? null : event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleAction = (action: ActionItem) => {
    action.onClick();
    handleClose();
  };

  return (
    <>
      <Button
        variant="contained"
        onClick={handleClick}
        sx={{
          borderRadius: '24px',
          px: 5,
          py: 1.25,
          textTransform: 'none',
          fontWeight: 600,
          fontSize: '0.9rem',
          minHeight: 42,
        }}
      >
        {buttonLabel}
      </Button>
      <Popper
        open={open}
        anchorEl={anchorEl}
        placement="bottom-end"
        transition
        style={{ zIndex: 1300 }}
      >
        {({ TransitionProps }) => (
          <Grow {...TransitionProps}>
            <Box>
              <ClickAwayListener onClickAway={handleClose}>
                <Box
                  sx={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 1.5,
                    alignItems: 'flex-end',
                    pt: 1.5,
                  }}
                >
                  {actions.map((action, index) => (
                    <Fab
                      key={index}
                      variant="extended"
                      size="medium"
                      onClick={() => handleAction(action)}
                      disabled={action.disabled}
                      sx={{
                        textTransform: 'none',
                        fontWeight: 500,
                        // Glassmorphic styling instead of solid color
                        backgroundColor: isDarkMode 
                          ? 'rgba(35, 35, 35, 0.98)' 
                          : 'rgba(255, 255, 255, 0.99)',
                        backdropFilter: 'blur(8px)',
                        WebkitBackdropFilter: 'blur(8px)',
                        color: theme.palette.text.primary,
                        border: `1px solid ${
                          isDarkMode 
                            ? 'rgba(255, 255, 255, 0.1)' 
                            : 'rgba(0, 0, 0, 0.06)'
                        }`,
                        boxShadow: isDarkMode 
                          ? '0 2px 8px rgba(0, 0, 0, 0.3)' 
                          : '0 2px 8px rgba(0, 0, 0, 0.08)',
                        '&:hover': {
                          backgroundColor: theme.palette.primary.main,
                          color: '#fff',
                          boxShadow: isDarkMode 
                            ? '0 4px 12px rgba(0, 0, 0, 0.4)' 
                            : '0 4px 12px rgba(0, 0, 0, 0.15)',
                        },
                      }}
                    >
                      {action.icon && (
                        <Box component="span" sx={{ mr: 1, display: 'flex', alignItems: 'center' }}>
                          {action.icon}
                        </Box>
                      )}
                      <Typography variant="body2" fontWeight={500}>
                        {action.label}
                      </Typography>
                    </Fab>
                  ))}
                </Box>
              </ClickAwayListener>
            </Box>
          </Grow>
        )}
      </Popper>
    </>
  );
};

export default ActionMenu;
