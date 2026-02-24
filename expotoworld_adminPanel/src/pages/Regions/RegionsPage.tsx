import React, { useMemo, useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Card,
  CardContent,
  TextField,
  InputAdornment,
  IconButton,
  Tooltip,
  Chip,
  CircularProgress,
} from '@mui/material';
import {
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  LocationOn as LocationIcon,
  Add as AddIcon,
  Upload as UploadIcon,
} from '@mui/icons-material';
import { GoogleMap, useJsApiLoader, Marker } from '@react-google-maps/api';
import { DataTable, ConfirmDialog, ActionMenu, PageTitle, type Column } from '@components/common';

// NOTE: The Marker component uses the deprecated google.maps.Marker under the hood.
// When @react-google-maps/api adds support for AdvancedMarkerElement, or when migrating
// to @vis.gl/react-google-maps (Google's recommended React library), update this file.
// See: https://developers.google.com/maps/documentation/javascript/advanced-markers/migration

interface Region {
  id: string;
  name: string;
  deliveryFee: number;
  storeCount: number;
  lat: number;
  lng: number;
  description?: string;
  createdAt: string;
  updatedAt: string;
}

// TODO: DUMMY DATA - Replace with actual API calls
const mockRegions: Region[] = [
  { id: '1', name: 'Manhattan', deliveryFee: 5.99, storeCount: 12, lat: 40.7831, lng: -73.9712, description: 'Central Manhattan area', createdAt: '2024-01-01T00:00:00Z', updatedAt: '2024-01-15T10:00:00Z' },
  { id: '2', name: 'Brooklyn', deliveryFee: 7.99, storeCount: 8, lat: 40.6782, lng: -73.9442, description: 'Brooklyn borough coverage', createdAt: '2024-01-02T00:00:00Z', updatedAt: '2024-01-14T11:00:00Z' },
  { id: '3', name: 'Queens', deliveryFee: 8.99, storeCount: 5, lat: 40.7282, lng: -73.7949, description: 'Queens service area', createdAt: '2024-01-03T00:00:00Z', updatedAt: '2024-01-13T12:00:00Z' },
  { id: '4', name: 'Bronx', deliveryFee: 9.99, storeCount: 3, lat: 40.8448, lng: -73.8648, description: 'Bronx region', createdAt: '2024-01-04T00:00:00Z', updatedAt: '2024-01-12T13:00:00Z' },
  { id: '5', name: 'Staten Island', deliveryFee: 12.99, storeCount: 2, lat: 40.5795, lng: -74.1502, description: 'Staten Island delivery zone', createdAt: '2024-01-05T00:00:00Z', updatedAt: '2024-01-11T14:00:00Z' },
  { id: '6', name: 'Hoboken', deliveryFee: 10.99, storeCount: 4, lat: 40.7440, lng: -74.0324, description: 'New Jersey Hoboken area', createdAt: '2024-01-06T00:00:00Z', updatedAt: '2024-01-10T15:00:00Z' },
  { id: '7', name: 'Jersey City', deliveryFee: 11.99, storeCount: 3, lat: 40.7178, lng: -74.0431, description: 'Jersey City coverage', createdAt: '2024-01-07T00:00:00Z', updatedAt: '2024-01-09T16:00:00Z' },
];

const RegionsPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [selectedRegion, setSelectedRegion] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [regionToDelete, setRegionToDelete] = useState<Region | null>(null);

  // Google Maps API loading
  const { isLoaded, loadError } = useJsApiLoader({
    googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY || '',
  });

  // Map container style
  const mapContainerStyle = useMemo(() => ({
    height: '300px',
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

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const onMapLoad = useCallback((_map: google.maps.Map) => {
    // Map loaded - can add additional setup here if needed
  }, []);

  const handleMarkerClick = (regionId: string) => {
    setSelectedRegion(regionId === selectedRegion ? null : regionId);
  };

  const columns: Column<Region>[] = [
    {
      id: 'name',
      label: t('regions.region') || 'Region',
      minWidth: 200,
      format: (_, row) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Box
            sx={{
              width: 40,
              height: 40,
              borderRadius: 2,
              bgcolor: 'primary.light',
              color: 'primary.main',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <LocationIcon />
          </Box>
          <Box>
            <Typography variant="body2" fontWeight={500}>
              {row.name}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {row.description}
            </Typography>
          </Box>
        </Box>
      ),
    },
    {
      id: 'deliveryFee',
      label: t('regions.deliveryFee') || 'Delivery Fee',
      minWidth: 120,
      format: (value) => (
        <Typography variant="body2" fontWeight={500}>
          {formatCurrency(value)}
        </Typography>
      ),
    },
    {
      id: 'storeCount',
      label: t('regions.storesInRegion') || 'Stores',
      minWidth: 100,
      align: 'center',
      format: (value) => (
        <Chip label={value} size="small" variant="outlined" />
      ),
    },
    {
      id: 'updatedAt',
      label: t('common.date'),
      minWidth: 120,
      format: (value) => formatDate(value),
    },
    {
      id: 'actions',
      label: t('common.actions'),
      minWidth: 120,
      format: (_, row) => (
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <Tooltip title={t('regions.showOnMap') || 'Show on map'}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                handleMarkerClick(row.id);
              }}
            >
              <ViewIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title={t('common.edit')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                navigate(`/regions/${row.id}/edit`);
              }}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title={t('common.delete')}>
            <IconButton
              size="small"
              color="error"
              onClick={(e) => {
                e.stopPropagation();
                setRegionToDelete(row);
                setDeleteDialogOpen(true);
              }}
            >
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      ),
    },
  ];

  // Filter regions
  const filteredRegions = mockRegions.filter((region) => {
    const matchesSearch =
      region.name.toLowerCase().includes(search.toLowerCase()) ||
      (region.description?.toLowerCase().includes(search.toLowerCase()) ?? false);
    return matchesSearch;
  });

  const handleDeleteConfirm = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call delete API
    // TODO: Implement delete region API call for region: ${regionToDelete?.id}
    setDeleteDialogOpen(false);
    setRegionToDelete(null);
  };

  const renderMap = () => {
    if (loadError) {
      return (
        <Box
          sx={{
            height: 300,
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
            height: 300,
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
            animation={selectedRegion === region.id ? google.maps.Animation.BOUNCE : undefined}
          />
        ))}
      </GoogleMap>
    );
  };

  const actionMenuItems = [
    {
      label: t('regions.create'),
      icon: <AddIcon />,
      onClick: () => navigate('/regions/new'),
    },
    {
      label: t('regions.upload'),
      icon: <UploadIcon />,
      onClick: () => {
        // TODO: NEED TO FULLY IMPLEMENT - Upload from file
      },
    },
  ];

  return (
    <Box>
      {/* Page Title */}
      <PageTitle title={t('regions.title')} actions={<ActionMenu actions={actionMenuItems} />} />

      {/* Filters */}
      <Card elevation={0} sx={{ mb: 3 }}>
        <CardContent>
          <Box
            sx={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: 2,
              alignItems: 'center',
            }}
          >
            <TextField
              placeholder={t('regions.searchPlaceholder') || 'Search regions...'}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              size="small"
              sx={{ minWidth: 280 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon color="action" />
                  </InputAdornment>
                ),
              }}
            />
          </Box>
        </CardContent>
      </Card>

      {/* Map Section */}
      <Box sx={{ mb: 3 }}>
        {renderMap()}
      </Box>

      {/* Regions Table */}
      <DataTable
        columns={columns}
        data={filteredRegions}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredRegions.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('regions.noRegions') || 'No regions found'}
        onRowClick={(row) => {
          handleMarkerClick(row.id);
          navigate(`/regions/${row.id}`);
        }}
        selectable
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={t('regions.deleteTitle') || 'Delete Region'}
        message={t('regions.deleteMessage', { name: regionToDelete?.name }) || `Are you sure you want to delete "${regionToDelete?.name}"?`}
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setRegionToDelete(null);
        }}
      />

    </Box>
  );
};

export default RegionsPage;
