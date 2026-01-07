import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  InputAdornment,
  IconButton,
  Alert,
  CircularProgress,
  Fade,
  Link,
} from '@mui/material';
import {
  Email as EmailIcon,
  ArrowBack as ArrowBackIcon,
} from '@mui/icons-material';
import { useAuth } from '@contexts/AuthContext';

const OTP_LENGTH = 6;
const CODE_EXPIRY_SECONDS = 10 * 60; // 10 minutes

const LoginPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { 
    isLoading, 
    error, 
    authStep, 
    pendingEmail,
    sendCode, 
    verifyCode, 
    resendCode,
    resetAuthStep,
    isAuthenticated 
  } = useAuth();
  
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState<string[]>(new Array(OTP_LENGTH).fill(''));
  const [localError, setLocalError] = useState<string | null>(null);
  const [countdown, setCountdown] = useState(CODE_EXPIRY_SECONDS);
  const [canResend, setCanResend] = useState(false);
  const otpRefs = useRef<(HTMLInputElement | null)[]>([]);

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/');
    }
  }, [isAuthenticated, navigate]);

  // Countdown timer for OTP expiry
  useEffect(() => {
    if (authStep !== 'otp') return;
    
    setCountdown(CODE_EXPIRY_SECONDS);
    setCanResend(false);
    
    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          setCanResend(true);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [authStep, pendingEmail]);

  // Format countdown as MM:SS
  const formatCountdown = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // Handle email submission
  const handleEmailSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLocalError(null);
    try {
      await sendCode(email);
    } catch (err) {
      setLocalError(err instanceof Error ? err.message : 'Failed to send code');
    }
  };

  // Handle OTP input change
  const handleOtpChange = (index: number, value: string) => {
    // Only allow digits
    if (value && !/^\d$/.test(value)) return;

    const newOtp = [...otp];
    newOtp[index] = value;
    setOtp(newOtp);

    // Auto-focus next input
    if (value && index < OTP_LENGTH - 1) {
      otpRefs.current[index + 1]?.focus();
    }

    // Auto-submit when all digits entered
    if (value && index === OTP_LENGTH - 1) {
      const code = newOtp.join('');
      if (code.length === OTP_LENGTH) {
        handleOtpSubmit(code);
      }
    }
  };

  // Handle OTP key down (backspace navigation)
  const handleOtpKeyDown = (index: number, e: React.KeyboardEvent) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      otpRefs.current[index - 1]?.focus();
    }
  };

  // Handle OTP paste
  const handleOtpPaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, OTP_LENGTH);
    if (pastedData.length === OTP_LENGTH) {
      const newOtp = pastedData.split('');
      setOtp(newOtp);
      handleOtpSubmit(pastedData);
    }
  };

  // Handle OTP verification
  const handleOtpSubmit = async (code?: string) => {
    const otpCode = code || otp.join('');
    if (otpCode.length !== OTP_LENGTH) return;

    setLocalError(null);
    try {
      await verifyCode(otpCode);
      navigate('/');
    } catch (err) {
      setLocalError(err instanceof Error ? err.message : 'Verification failed');
      // Clear OTP on error
      setOtp(new Array(OTP_LENGTH).fill(''));
      otpRefs.current[0]?.focus();
    }
  };

  // Handle resend code
  const handleResend = async () => {
    setLocalError(null);
    try {
      await resendCode();
      setOtp(new Array(OTP_LENGTH).fill(''));
      otpRefs.current[0]?.focus();
    } catch (err) {
      setLocalError(err instanceof Error ? err.message : 'Failed to resend code');
    }
  };

  // Handle back to email
  const handleBack = () => {
    resetAuthStep();
    setOtp(new Array(OTP_LENGTH).fill(''));
    setLocalError(null);
  };

  const displayError = localError || error;

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'background.default',
        p: 2,
      }}
    >
      <Card
        elevation={0}
        sx={{
          maxWidth: 420,
          width: '100%',
          border: 1,
          borderColor: 'divider',
        }}
      >
        <CardContent sx={{ p: 4 }}>
          {/* Logo / Brand */}
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <Typography
              variant="h4"
              sx={{
                fontWeight: 700,
                background: 'linear-gradient(135deg, #1976D2 0%, #42A5F5 100%)',
                backgroundClip: 'text',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                mb: 1,
              }}
            >
              EXPO to WORLD
            </Typography>
            <Typography variant="body1" color="text.secondary">
              {t('auth.adminPanel')}
            </Typography>
          </Box>

          {/* Error Alert */}
          {displayError && (
            <Alert severity="error" sx={{ mb: 3 }}>
              {displayError}
            </Alert>
          )}

          {/* Step 1: Email Entry */}
          <Fade in={authStep === 'email'} unmountOnExit>
            <Box component="form" onSubmit={handleEmailSubmit}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                {t('auth.enterEmailDesc')}
              </Typography>
              
              <TextField
                fullWidth
                label={t('auth.email')}
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                sx={{ mb: 3 }}
                autoFocus
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <EmailIcon color="action" />
                    </InputAdornment>
                  ),
                }}
              />

              <Button
                fullWidth
                type="submit"
                variant="contained"
                size="large"
                disabled={isLoading || !email}
              >
                {isLoading ? (
                  <CircularProgress size={24} color="inherit" />
                ) : (
                  t('auth.sendCode')
                )}
              </Button>
            </Box>
          </Fade>

          {/* Step 2: OTP Entry */}
          <Fade in={authStep === 'otp'} unmountOnExit>
            <Box>
              {/* Back button */}
              <IconButton 
                onClick={handleBack} 
                sx={{ mb: 2, ml: -1 }}
                disabled={isLoading}
              >
                <ArrowBackIcon />
              </IconButton>

              <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                {t('auth.enterCodeDesc')}
              </Typography>
              <Typography variant="body2" fontWeight={500} sx={{ mb: 3 }}>
                {pendingEmail}
              </Typography>

              {/* OTP Input Fields */}
              <Box
                sx={{
                  display: 'flex',
                  gap: 1,
                  justifyContent: 'center',
                  mb: 3,
                }}
                onPaste={handleOtpPaste}
              >
                {otp.map((digit, index) => (
                  <TextField
                    key={index}
                    inputRef={(el) => (otpRefs.current[index] = el)}
                    value={digit}
                    onChange={(e) => handleOtpChange(index, e.target.value)}
                    onKeyDown={(e) => handleOtpKeyDown(index, e)}
                    inputProps={{
                      maxLength: 1,
                      style: { 
                        textAlign: 'center', 
                        fontSize: '1.5rem',
                        fontWeight: 600,
                        padding: '12px 8px',
                      },
                      inputMode: 'numeric',
                    }}
                    sx={{
                      width: 48,
                      '& .MuiOutlinedInput-root': {
                        borderRadius: 2,
                      },
                    }}
                    disabled={isLoading}
                  />
                ))}
              </Box>

              {/* Timer and Resend */}
              <Box sx={{ textAlign: 'center', mb: 3 }}>
                {countdown > 0 ? (
                  <Typography variant="body2" color="text.secondary">
                    {t('auth.codeExpiresIn')} {formatCountdown(countdown)}
                  </Typography>
                ) : (
                  <Typography variant="body2" color="error">
                    {t('auth.codeExpired')}
                  </Typography>
                )}
                
                {canResend && (
                  <Link
                    component="button"
                    type="button"
                    variant="body2"
                    onClick={handleResend}
                    disabled={isLoading}
                    sx={{ mt: 1, display: 'block', mx: 'auto' }}
                  >
                    {t('auth.resendCode')}
                  </Link>
                )}
              </Box>

              <Button
                fullWidth
                variant="contained"
                size="large"
                onClick={() => handleOtpSubmit()}
                disabled={isLoading || otp.join('').length !== OTP_LENGTH}
              >
                {isLoading ? (
                  <CircularProgress size={24} color="inherit" />
                ) : (
                  t('auth.verify')
                )}
              </Button>
            </Box>
          </Fade>
        </CardContent>
      </Card>
    </Box>
  );
};

export default LoginPage;
