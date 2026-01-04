import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Fab,
  Box,
  Typography,
  Fade,
  ClickAwayListener,
  Paper,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditNowIcon,
  FileUpload as UploadIcon,
} from '@mui/icons-material';

interface AddFabProps {
  onFillOutNow: () => void;
  onUploadFromDevice: () => void;
}

const AddFab: React.FC<AddFabProps> = ({ onFillOutNow, onUploadFromDevice }) => {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);

  const handleToggle = () => {
    setOpen((prev) => !prev);
  };

  const handleClose = () => {
    setOpen(false);
  };

  const handleFillOutNow = () => {
    handleClose();
    onFillOutNow();
  };

  const handleUpload = () => {
    handleClose();
    onUploadFromDevice();
  };

  return (
    <ClickAwayListener onClickAway={handleClose}>
      <Box
        sx={{
          position: 'fixed',
          bottom: 24,
          right: 24,
          zIndex: 1100,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        {/* Speed Dial Actions */}
        <Fade in={open}>
          <Box
            sx={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 2,
              mb: 2,
            }}
          >
            {/* Upload from Device */}
            <Paper
              elevation={4}
              onClick={handleUpload}
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 1.5,
                px: 2,
                py: 1.5,
                borderRadius: 3,
                cursor: 'pointer',
                bgcolor: 'background.paper',
                transition: 'transform 0.2s, box-shadow 0.2s',
                '&:hover': {
                  transform: 'scale(1.02)',
                  boxShadow: 6,
                },
              }}
            >
              <Box
                sx={{
                  width: 36,
                  height: 36,
                  borderRadius: '50%',
                  bgcolor: 'secondary.main',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <UploadIcon sx={{ color: 'white', fontSize: 20 }} />
              </Box>
              <Typography variant="body2" fontWeight={500} sx={{ whiteSpace: 'nowrap' }}>
                {t('common.uploadFromDevice')}
              </Typography>
            </Paper>

            {/* Fill Out Now */}
            <Paper
              elevation={4}
              onClick={handleFillOutNow}
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 1.5,
                px: 2,
                py: 1.5,
                borderRadius: 3,
                cursor: 'pointer',
                bgcolor: 'background.paper',
                transition: 'transform 0.2s, box-shadow 0.2s',
                '&:hover': {
                  transform: 'scale(1.02)',
                  boxShadow: 6,
                },
              }}
            >
              <Box
                sx={{
                  width: 36,
                  height: 36,
                  borderRadius: '50%',
                  bgcolor: 'primary.main',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <EditNowIcon sx={{ color: 'white', fontSize: 20 }} />
              </Box>
              <Typography variant="body2" fontWeight={500} sx={{ whiteSpace: 'nowrap' }}>
                {t('common.fillOutNow')}
              </Typography>
            </Paper>
          </Box>
        </Fade>

        {/* Main FAB Button */}
        <Fab
          color="primary"
          aria-label="add"
          onClick={handleToggle}
          sx={{
            width: 56,
            height: 56,
            boxShadow: 4,
            transition: 'transform 0.2s',
            transform: open ? 'rotate(45deg)' : 'rotate(0deg)',
            '&:hover': {
              boxShadow: 6,
            },
          }}
        >
          <AddIcon />
        </Fab>
      </Box>
    </ClickAwayListener>
  );
};

export default AddFab;
