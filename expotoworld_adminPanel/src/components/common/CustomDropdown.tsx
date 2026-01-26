/**
 * CustomDropdown - A reusable Popper-based dropdown component
 * 
 * This component provides consistent styling across the admin panel with:
 * - Floating individual option items (no solid backdrop)
 * - Form field integration (error states, required, disabled)
 * - Accessible with proper ARIA attributes
 * 
 * Use this component for all form dropdowns to maintain visual consistency.
 */
import React, { useState, useRef, useId } from 'react';
import {
  Popper,
  Fade,
  ClickAwayListener,
  Box,
  Typography,
  useTheme,
  FormHelperText,
  Portal,
} from '@mui/material';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';

export interface DropdownOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface CustomDropdownProps {
  /** Label text for the dropdown */
  label: string;
  /** Currently selected value */
  value: string;
  /** Array of options to display */
  options: DropdownOption[];
  /** Callback when selection changes */
  onChange: (value: string) => void;
  /** Placeholder text when no value selected */
  placeholder?: string;
  /** Whether the field is required */
  required?: boolean;
  /** Whether the field is disabled */
  disabled?: boolean;
  /** Error state */
  error?: boolean;
  /** Helper text (shown below the field) */
  helperText?: string;
  /** Minimum width of the dropdown */
  minWidth?: number;
  /** Whether to take full width of container */
  fullWidth?: boolean;
  /** Size variant */
  size?: 'small' | 'medium';
  /** Additional sx props */
  sx?: Record<string, unknown>;
}

const CustomDropdown: React.FC<CustomDropdownProps> = ({
  label,
  value,
  options,
  onChange,
  placeholder,
  required = false,
  disabled = false,
  error = false,
  helperText,
  minWidth = 150,
  fullWidth = false,
  size = 'small',
  sx = {},
}) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl) && !disabled;
  const theme = useTheme();
  const isDarkMode = theme.palette.mode === 'dark';
  const buttonRef = useRef<HTMLDivElement>(null);
  const dropdownId = useId();

  const height = size === 'small' ? 40 : 56;

  const handleClick = () => {
    if (!disabled) {
      setAnchorEl(anchorEl ? null : buttonRef.current);
    }
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleSelect = (optionValue: string) => {
    onChange(optionValue);
    handleClose();
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (disabled) return;
    
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleClick();
    } else if (e.key === 'Escape' && open) {
      handleClose();
    }
  };

  const selectedOption = options.find(opt => opt.value === value);
  const displayText = selectedOption ? selectedOption.label : placeholder || '';

  // Determine border color
  const getBorderColor = () => {
    if (error) return theme.palette.error.main;
    if (open) return theme.palette.primary.main;
    return theme.palette.divider;
  };

  // Determine label color
  const getLabelColor = () => {
    if (error) return theme.palette.error.main;
    if (open) return theme.palette.primary.main;
    return theme.palette.text.secondary;
  };

  // Calculate dropdown width based on anchor element
  const dropdownWidth = buttonRef.current?.offsetWidth || minWidth;

  return (
    <Box sx={{ width: fullWidth ? '100%' : 'auto', ...sx }}>
      {/* Trigger button */}
      <Box
        ref={buttonRef}
        onClick={handleClick}
        onKeyDown={handleKeyDown}
        tabIndex={disabled ? -1 : 0}
        role="combobox"
        aria-expanded={open}
        aria-haspopup="listbox"
        aria-controls={dropdownId}
        aria-disabled={disabled}
        aria-required={required}
        aria-invalid={error}
        sx={{
          position: 'relative',
          minWidth: fullWidth ? undefined : minWidth,
          width: fullWidth ? '100%' : undefined,
          height,
          cursor: disabled ? 'not-allowed' : 'pointer',
          borderRadius: '8px',
          border: `1px solid ${getBorderColor()}`,
          px: 1.75,
          transition: 'border-color 0.2s ease-in-out',
          opacity: disabled ? 0.5 : 1,
          '&:hover': {
            borderColor: disabled ? undefined : theme.palette.primary.main,
          },
          '&:focus': {
            outline: 'none',
            borderColor: theme.palette.primary.main,
            boxShadow: `0 0 0 2px ${theme.palette.primary.main}20`,
          },
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          backgroundColor: 'transparent',
          boxSizing: 'border-box',
        }}
      >
        {/* Floating label */}
        <Typography
          component="span"
          sx={{
            position: 'absolute',
            top: 0,
            left: 10,
            transform: 'translateY(-50%)',
            px: 0.5,
            fontSize: '0.75rem',
            color: getLabelColor(),
            background: isDarkMode 
              ? 'linear-gradient(to bottom, #1e1e1e, #1b1b1b)'
              : '#fff',
            lineHeight: 1,
            transition: 'color 0.2s ease-in-out',
          }}
        >
          {label}
          {required && <span style={{ color: theme.palette.error.main, marginLeft: 2 }}>*</span>}
        </Typography>

        {/* Selected value display */}
        <Typography 
          variant="body2" 
          sx={{ 
            fontWeight: 500, 
            color: selectedOption 
              ? theme.palette.text.primary 
              : theme.palette.text.secondary,
            pl: 1.5,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
            flex: 1,
          }}
        >
          {displayText}
        </Typography>

        <KeyboardArrowDownIcon 
          sx={{ 
            ml: 1,
            fontSize: '1.25rem',
            color: theme.palette.text.secondary,
            transform: open ? 'rotate(180deg)' : 'rotate(0deg)',
            transition: 'transform 0.2s ease-in-out',
            flexShrink: 0,
          }} 
        />
      </Box>

      {/* Helper text */}
      {helperText && (
        <FormHelperText error={error} sx={{ mx: 1.75, mt: 0.5 }}>
          {helperText}
        </FormHelperText>
      )}

      {/* Dropdown options */}
      <Portal>
        <Popper
          id={dropdownId}
          open={open}
          anchorEl={anchorEl}
          placement="bottom-start"
          transition
          style={{ zIndex: 1400 }} // Higher than Dialog (1300)
          modifiers={[
            {
              name: 'offset',
              options: {
                offset: [0, 8],
              },
            },
            {
              name: 'preventOverflow',
              options: {
                padding: 8,
              },
            },
          ]}
        >
          {({ TransitionProps }) => (
            <Fade {...TransitionProps} timeout={150}>
              <div style={{ background: 'transparent', boxShadow: 'none' }}>
                <ClickAwayListener onClickAway={handleClose}>
                  <Box
                    role="listbox"
                    aria-labelledby={`${dropdownId}-label`}
                    sx={{
                      display: 'flex',
                      flexDirection: 'column',
                      gap: 0.85,
                      py: 0,
                      px: 0,
                      maxHeight: 200,
                      overflowY: 'auto',
                      background: 'transparent !important',
                      boxShadow: 'none !important',
                      // Scrollbar styling - visible on hover, auto-hide when not scrolling
                      '&::-webkit-scrollbar': {
                        width: '6px',
                      },
                      '&::-webkit-scrollbar-track': {
                        background: 'transparent',
                      },
                      '&::-webkit-scrollbar-thumb': {
                        backgroundColor: theme.palette.divider,
                        borderRadius: '3px',
                        transition: 'background-color 0.2s ease',
                      },
                      '&::-webkit-scrollbar-thumb:hover': {
                        backgroundColor: theme.palette.action.disabled,
                      },
                    }}
                  >
                    {options.map((option) => {
                      const isSelected = value === option.value;
                      const isDisabled = option.disabled;
                      // Ensure dropdown options are at least as wide as trigger, but have a reasonable minimum (150px)
                      const optionWidth = Math.max(dropdownWidth, 150);
                      return (
                        <Box
                          key={option.value}
                          role="option"
                          aria-selected={isSelected}
                          aria-disabled={isDisabled}
                          onClick={() => !isDisabled && handleSelect(option.value)}
                          sx={{
                            pl: 3,
                            pr: 1.75,
                            py: 1,
                            borderRadius: '8px',
                            cursor: isDisabled ? 'not-allowed' : 'pointer',
                            fontWeight: isSelected ? 600 : 500,
                            fontSize: '0.875rem',
                            width: optionWidth,
                            minWidth: 150,
                            minHeight: 40, // Ensure minimum height
                            flexShrink: 0, // Prevent squishing
                            boxSizing: 'border-box',
                            whiteSpace: 'nowrap',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            display: 'flex',
                            alignItems: 'center',
                            transition: 'all 0.15s ease-out',
                            opacity: isDisabled ? 0.5 : 1,
                            // Selected = solid primary, unselected = solid white/dark with subtle blur
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
                            boxShadow: isSelected 
                              ? `0 2px 8px ${theme.palette.primary.main}25` 
                              : 'none',
                            backgroundImage: 'none',
                            '&:hover': isDisabled ? {} : {
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
      </Portal>
    </Box>
  );
};

export default CustomDropdown;
