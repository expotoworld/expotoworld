import React, { useMemo, useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Box, Typography, Button, Card, CardContent, Grid, Chip, CircularProgress } from '@mui/material';
import { Add as AddIcon } from '@mui/icons-material';
import { PageHeader } from '@components/common';
import { GoogleMap, useJsApiLoader, Marker } from '@react-google-maps/api';

const RegionsPage: React.FC = () => {
  const { t } = useTranslation();
  const [selectedRegion, setSelectedRegion] = useState<string | null>(null);

  // Google Maps API loading
  const { isLoaded, loadError } = useJsApiLoader({
    googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY || '',
  });

  // Map container style
  const mapContainerStyle = useMemo(() => ({
    height: '350px',
    width: '100%',
    borderRadius: '12px',
  }), []);

  // Default center (New York City)
  const center = useMemo(() => ({
    lat: 40.7128,
    lng: -74.0060,
  }), []);

  // Map options for cleaner look
  const mapOptions = useMemo(() => ({
    disableDefaultUI: false,
    zoomControl: true,
    streetViewControl: false,
    mapTypeControl: false,
    fullscreenControl: true,
    styles: [
      {
        featureType: 'poi',
        elementType: 'labels',
        stylers: [{ visibility: 'off' }],
      },
    ],
  }), []);

  // TODO: DUMMY DATA - Replace with actual API calls
  const mockRegions = [
    { id: '1', name: 'Manhattan', deliveryFee: 5.99, storeCount: 12, isActive: true, lat: 40.7831, lng: -73.9712 },
    { id: '2', name: 'Brooklyn', deliveryFee: 7.99, storeCount: 8, isActive: true, lat: 40.6782, lng: -73.9442 },
    { id: '3', name: 'Queens', deliveryFee: 8.99, storeCount: 5, isActive: true, lat: 40.7282, lng: -73.7949 },
    { id: '4', name: 'Bronx', deliveryFee: 9.99, storeCount: 3, isActive: false, lat: 40.8448, lng: -73.8648 },
    { id: '5', name: 'Staten Island', deliveryFee: 12.99, storeCount: 2, isActive: true, lat: 40.5795, lng: -74.1502 },
  ];

  const onMapLoad = useCallback((_map: google.maps.Map) => {
    // Can add additional map setup here if needed
    console.log('Map loaded successfully');
  }, []);

  const handleMarkerClick = (regionId: string) => {
    setSelectedRegion(regionId === selectedRegion ? null : regionId);
  };

  const renderMap = () => {
    if (loadError) {
      return (
        <Box
          sx={{
            height: 350,
            bgcolor: 'action.hover',
            borderRadius: 3,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexDirection: 'column',
            gap: 2,
          }}
        >
          <Typography variant="body1" color="error">
            Error loading Google Maps
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Please check your API key configuration
          </Typography>
        </Box>
      );
    }

    if (!isLoaded) {
      return (
        <Box
          sx={{
            height: 350,
            bgcolor: 'action.hover',
            borderRadius: 3,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexDirection: 'column',
            gap: 2,
          }}
        >
          <CircularProgress size={48} />
          <Typography variant="body2" color="text.secondary">
            Loading map...
          </Typography>
        </Box>
      );
    }

    return (
      <GoogleMap
        mapContainerStyle={mapContainerStyle}
        center={center}
        zoom={10}
        onLoad={onMapLoad}
        options={mapOptions}
      >
        {mockRegions.map((region) => (
          <Marker
            key={region.id}
            position={{ lat: region.lat, lng: region.lng }}
            onClick={() => handleMarkerClick(region.id)}
            title={region.name}
            icon={region.isActive ? undefined : {
              url: 'http://maps.google.com/mapfiles/ms/icons/grey.png',
            }}
          />
        ))}
      </GoogleMap>
    );
  };

  return (
    <Box>
      <PageHeader
        title={t('regions.title')}
        subtitle={t('regions.subtitle')}
        breadcrumbs={[
          { label: t('nav.dashboard'), path: '/' },
          { label: t('nav.regions') },
        ]}
        actions={
          <Button
            variant="contained"
            startIcon={<AddIcon />}
          >
            {t('regions.addRegion')}
          </Button>
        }
      />

      {/* Map Section */}
      <Card elevation={0} sx={{ mb: 3 }}>
        <CardContent>
          {renderMap()}
        </CardContent>
      </Card>

      {/* Regions List */}
      <Grid container spacing={3}>
        {mockRegions.map((region) => (
          <Grid item xs={12} sm={6} md={4} lg={3} key={region.id}>
            <Card
              elevation={0}
              onClick={() => handleMarkerClick(region.id)}
              sx={{
                cursor: 'pointer',
                transition: 'all 0.2s',
                border: selectedRegion === region.id ? 2 : 0,
                borderColor: 'primary.main',
                '&:hover': { transform: 'translateY(-4px)' },
              }}
            >
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                  <Typography variant="h6" fontWeight={600}>
                    {region.name}
                  </Typography>
                  <Chip
                    label={region.isActive ? t('common.active') : t('common.inactive')}
                    size="small"
                    color={region.isActive ? 'success' : 'default'}
                  />
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2" color="text.secondary">
                    {t('regions.deliveryFee')}
                  </Typography>
                  <Typography variant="body2" fontWeight={500}>
                    ${region.deliveryFee.toFixed(2)}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2" color="text.secondary">
                    {t('regions.storesInRegion')}
                  </Typography>
                  <Typography variant="body2" fontWeight={500}>
                    {region.storeCount}
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

export default RegionsPage;
