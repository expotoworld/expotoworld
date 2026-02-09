import React, { useState, useEffect, useCallback, useRef } from 'react';
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
  CssBaseline,
} from '@mui/material';
import { createTheme, ThemeProvider } from '@mui/material/styles';
import {
  Email as EmailIcon,
  ArrowBack as ArrowBackIcon,
} from '@mui/icons-material';
import axios from 'axios';
import { setAccessToken, setRefreshToken, getDeviceId } from './auth';

// Default MUI theme — matches admin panel login appearance (it uses standard MUI blue gradient + default components)
const muiTheme = createTheme();

const OTP_LENGTH = 6;
const CODE_EXPIRY_SECONDS = 10 * 60; // 10 minutes

interface LoginNewProps {
  onToken: (token: string) => void;
}

export default function LoginNew({ onToken }: LoginNewProps) {
  const [step, setStep] = useState<'email' | 'otp'>('email');
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState<string[]>(new Array(OTP_LENGTH).fill(''));
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [countdown, setCountdown] = useState(CODE_EXPIRY_SECONDS);
  const [canResend, setCanResend] = useState(false);
  const otpRefs = useRef<(HTMLInputElement | null)[]>([]);

  const AUTH_BASE = import.meta.env.VITE_AUTH_BASE || 'https://device-api.expotoworld.com';

  // Countdown timer for OTP expiry
  useEffect(() => {
    if (step !== 'otp') return;

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
  }, [step, email]);

  // Format countdown as MM:SS
  const formatCountdown = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // Handle email submission
  const handleEmailSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      await axios.post(
        `${AUTH_BASE}/api/v1/auth/send-code`,
        { email },
        {
          withCredentials: true,
          headers: {
            'X-Require-Existing': 'true',
            'X-Require-Role': 'Author',
            'X-Device-Id': getDeviceId(),
          },
        }
      );
      setStep('otp');
      setOtp(new Array(OTP_LENGTH).fill(''));
    } catch (e: any) {
      setError(e?.response?.data?.message || 'Failed to send verification code');
    } finally {
      setIsLoading(false);
    }
  };

  // Handle OTP input change
  const handleOtpChange = (index: number, value: string) => {
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
  const handleOtpSubmit = useCallback(async (code?: string) => {
    const otpCode = code || otp.join('');
    if (otpCode.length !== OTP_LENGTH) return;

    setIsLoading(true);
    setError('');

    try {
      const res = await axios.post(
        `${AUTH_BASE}/api/v1/auth/verify-code`,
        { email, code: otpCode },
        {
          withCredentials: true,
          headers: {
            'X-Require-Existing': 'true',
            'X-Require-Role': 'Author',
            'X-Device-Id': getDeviceId(),
          },
        }
      );

      const accessToken: string = res.data?.access_token;
      const refreshToken: string | undefined = res.data?.refresh_token;
      const expiresIn: number = res.data?.expires_in || 900;
      const expiresAt = new Date(Date.now() + expiresIn * 1000).toISOString();
      const refreshExpiresAt: string | undefined =
        res.data?.refresh_expires_at
        || (res.data?.refresh_expires_in
            ? new Date(Date.now() + res.data.refresh_expires_in * 1000).toISOString()
            : undefined)
        || (refreshToken
            ? new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString()
            : undefined);

      if (!accessToken) {
        setError('Authentication failed - no token received');
        return;
      }

      setAccessToken(accessToken, expiresAt);
      if (refreshToken && refreshExpiresAt) setRefreshToken(refreshToken, refreshExpiresAt);
      onToken(accessToken);
    } catch (e: any) {
      setError(e?.response?.data?.message || 'Invalid verification code');
      setOtp(new Array(OTP_LENGTH).fill(''));
      otpRefs.current[0]?.focus();
    } finally {
      setIsLoading(false);
    }
  }, [email, otp, AUTH_BASE, onToken]);

  // Handle resend code
  const handleResend = async () => {
    setIsLoading(true);
    setError('');

    try {
      await axios.post(
        `${AUTH_BASE}/api/v1/auth/send-code`,
        { email },
        {
          withCredentials: true,
          headers: {
            'X-Require-Existing': 'true',
            'X-Require-Role': 'Author',
            'X-Device-Id': getDeviceId(),
          },
        }
      );
      setOtp(new Array(OTP_LENGTH).fill(''));
      otpRefs.current[0]?.focus();
      setCountdown(CODE_EXPIRY_SECONDS);
      setCanResend(false);
    } catch (e: any) {
      setError(e?.response?.data?.message || 'Failed to resend code');
    } finally {
      setIsLoading(false);
    }
  };

  // Handle back to email
  const handleBack = () => {
    setStep('email');
    setOtp(new Array(OTP_LENGTH).fill(''));
    setError('');
  };

  return (
    <ThemeProvider theme={muiTheme}>
      <CssBaseline />
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
              Ebook Editor
            </Typography>
          </Box>

          {/* Error Alert */}
          {error && (
            <Alert severity="error" sx={{ mb: 3 }}>
              {error}
            </Alert>
          )}

          {/* Step 1: Email Entry */}
          <Fade in={step === 'email'} unmountOnExit>
            <Box component="form" onSubmit={handleEmailSubmit}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Enter your author email to receive a verification code.
              </Typography>

              <TextField
                fullWidth
                label="Author Email"
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
                  'Send Verification Code'
                )}
              </Button>
            </Box>
          </Fade>

          {/* Step 2: OTP Entry */}
          <Fade in={step === 'otp'} unmountOnExit>
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
                Enter the 6-digit code sent to
              </Typography>
              <Typography variant="body2" fontWeight={500} sx={{ mb: 3 }}>
                {email}
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
                    Code expires in {formatCountdown(countdown)}
                  </Typography>
                ) : (
                  <Typography variant="body2" color="error">
                    Code has expired
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
                    Resend Code
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
                  'Verify & Sign In'
                )}
              </Button>
            </Box>
          </Fade>
        </CardContent>
      </Card>
    </Box>
    </ThemeProvider>
  );
}

