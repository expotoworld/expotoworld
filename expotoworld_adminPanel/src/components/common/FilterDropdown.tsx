import React, { useState, useRef } from 'react';
import {
  Popper,
  Fade,
  ClickAwayListener,
  Box,
  Typography,
  useTheme,
} from '@mui/material';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';

export interface FilterOption {
  value: string;
  label: string;
}

interface FilterDropdownProps {
  label: string;
  value: string;
  options: FilterOption[];
  onChange: (value: string) => void;
  minWidth?: number;
}

const FilterDropdown: React.FC<FilterDropdownProps> = ({
  label,
  value,
  options,
  onChange,
  minWidth = 150,
}) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);
  const theme = useTheme();
  const isDarkMode = theme.palette.mode === 'dark';
  const buttonRef = useRef<HTMLDivElement>(null);

  const handleClick = () => {
    setAnchorEl(anchorEl ? null : buttonRef.current);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleSelect = (optionValue: string) => {
    onChange(optionValue);
    handleClose();
  };

  const selectedOption = options.find(opt => opt.value === value);
  const displayText = selectedOption ? selectedOption.label : '';

  return (
    <>
      {/* MUI-style outlined field with label breaking the border - match search bar height */}
      <Box
        ref={buttonRef}
        onClick={handleClick}
        sx={{
          position: 'relative',
          minWidth,
          height: 40,
          cursor: 'pointer',
          borderRadius: '8px',
          border: `1px solid ${open ? theme.palette.primary.main : theme.palette.divider}`,
          px: 1.75,
          transition: 'border-color 0.2s ease-in-out',
          '&:hover': {
            borderColor: theme.palette.primary.main,
          },
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          backgroundColor: 'transparent',
          boxSizing: 'border-box',
        }}
      >
        {/* Floating label that breaks the border - aligned with value text */}
        <Typography
          component="span"
          sx={{
            position: 'absolute',
            top: 0,
            left: 10, // Back to original
            transform: 'translateY(-50%)',
            px: 0.5,
            fontSize: '0.75rem',
            color: open ? theme.palette.primary.main : theme.palette.text.secondary,
            // Use solid background for light mode, gradient for dark mode to match Card
            background: isDarkMode 
              ? 'linear-gradient(to bottom, #1e1e1e, #1b1b1b)'
              : '#fff',
            lineHeight: 1,
            transition: 'color 0.2s ease-in-out',
          }}
        >
          {label}
        </Typography>
        {/* Selected value display - align with dropdown item text */}
        <Typography 
          variant="body2" 
          sx={{ 
            fontWeight: 500, 
            color: theme.palette.text.primary,
            pl: 1.5,
          }}
        >
          {displayText || label}
        </Typography>
        <KeyboardArrowDownIcon 
          sx={{ 
            ml: 1,
            fontSize: '1.25rem',
            color: theme.palette.text.secondary,
            transform: open ? 'rotate(180deg)' : 'rotate(0deg)',
            transition: 'transform 0.2s ease-in-out',
          }} 
        />
      </Box>
      <Popper
        open={open}
        anchorEl={anchorEl}
        placement="bottom-start"
        transition
        style={{ zIndex: 1300 }}
        modifiers={[
          {
            name: 'offset',
            options: {
              offset: [0, 8],
            },
          },
        ]}
      >
        {({ TransitionProps }) => (
          <Fade {...TransitionProps} timeout={150}>
            <div style={{ background: 'transparent', boxShadow: 'none' }}>
              <ClickAwayListener onClickAway={handleClose}>
                <Box
                  sx={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 0.85,
                    py: 0,
                    px: 0,
                    maxHeight: 150,
                    overflowY: 'auto',
                    background: 'transparent !important',
                    boxShadow: 'none !important',
                    // Scrollbar styling
                    '&::-webkit-scrollbar': {
                      width: '4px',
                    },
                    '&::-webkit-scrollbar-track': {
                      background: 'transparent',
                    },
                    '&::-webkit-scrollbar-thumb': {
                      backgroundColor: 'transparent',
                      borderRadius: '2px',
                    },
                    '&:hover::-webkit-scrollbar-thumb': {
                      backgroundColor: theme.palette.divider,
                    },
                  }}
                >
                  {options.map((option) => {
                    const isSelected = value === option.value;
                    return (
                      <Box
                        key={option.value}
                        onClick={() => handleSelect(option.value)}
                        sx={{
                          pl: 3,
                          pr: 1.75,
                          py: 1,
                          borderRadius: '8px',
                          cursor: 'pointer',
                          fontWeight: isSelected ? 600 : 500,
                          fontSize: '0.875rem',
                          width: minWidth,
                          boxSizing: 'border-box',
                          whiteSpace: 'nowrap',
                          transition: 'all 0.15s ease-out',
                          // Selected = solid red, unselected = solid white/dark with subtle blur
                          backgroundColor: isSelected 
                            ? theme.palette.primary.main
                            : isDarkMode 
                              ? 'rgba(35, 35, 35, 0.98)' 
                              : 'rgba(255, 255, 255, 0.99)',
                          backdropFilter: isSelected ? 'none' : 'blur(8px)',
                          WebkitBackdropFilter: isSelected ? 'none' : 'blur(8px)',
                          color: isSelected 
                            ? '#fff' 
                            : theme.palette.text.primary,
                          border: `1px solid ${
                            isSelected 
                              ? theme.palette.primary.main 
                              : isDarkMode 
                                ? 'rgba(255, 255, 255, 0.1)' 
                                : 'rgba(0, 0, 0, 0.06)'
                          }`,
                          // No shadow on items - purely clean floating cards
                          boxShadow: isSelected 
                            ? `0 2px 8px ${theme.palette.primary.main}25` 
                            : 'none',
                          backgroundImage: 'none',
                          '&:hover': {
                            backgroundColor: isSelected 
                              ? theme.palette.primary.dark 
                              : isDarkMode 
                                ? 'rgba(45, 45, 45, 1)' 
                                : 'rgba(250, 250, 250, 1)',
                            boxShadow: isSelected 
                              ? `0 4px 12px ${theme.palette.primary.main}30` 
                              : 'none',
                          },
                        }}
                      >
                        {option.label}
                      </Box>
                    );
                  })}
                </Box>
              </ClickAwayListener>
            </div>
          </Fade>
        )}
      </Popper>
    </>
  );
};

export default FilterDropdown;
