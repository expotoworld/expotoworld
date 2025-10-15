# EXPO to World - Admin Panel

Admin panel for managing the EXPO to World platform.

## Technology Stack

- **React** 18.2.0
- **Material-UI** (@mui) 5.15.1
- **React Router** 6.20.1
- **Axios** for API calls
- **Create React App** (react-scripts 5.0.1)

## Features

- User Management
- Product Catalog Management
- Order Management
- Cart Management
- Store Management
- Category Management
- Organization Management
- Region Management
- Manufacturer Portal

## Environment Configuration

The admin panel uses environment variables to configure API endpoints:

### Development
```bash
REACT_APP_API_BASE_URL=http://127.0.0.1:8787
```

### Production
```bash
REACT_APP_API_BASE_URL=https://device-api.expotoworld.com
```

## Local Development

1. Install dependencies:
```bash
npm install
```

2. Copy environment file:
```bash
cp .env.development.example .env.development
```

3. Start development server:
```bash
npm start
```

The app will open at [http://localhost:3000](http://localhost:3000).

## Building for Production

```bash
npm run build
```

This creates an optimized production build in the `build/` directory.

## Deployment

The admin panel is automatically deployed to AWS S3 + CloudFront when changes are pushed to the `main` branch.

- **Production URL**: https://admin.expotoworld.com
- **CloudFront Distribution**: E2JL3VLX19R2ZH
- **S3 Bucket**: expotoworld-editor-site
- **Region**: eu-central-1

## API Integration

The admin panel connects to backend services through a Cloudflare Worker gateway:

- **Production Gateway**: https://device-api.expotoworld.com
- **Development Gateway**: http://127.0.0.1:8787 (local Cloudflare Worker)

### Backend Services

- **Auth Service**: `/api/auth/*`
- **User Service**: `/api/admin/users/*`
- **Catalog Service**: `/api/v1/*`
- **Order Service**: `/api/admin/orders/*`
- **Cart Service**: `/api/admin/carts/*`
- **Manufacturer Service**: `/api/admin/manufacturer/*`

## Testing

```bash
npm test
```

## Available Scripts

- `npm start` - Start development server
- `npm run build` - Build for production
- `npm test` - Run tests
- `npm run eject` - Eject from Create React App (one-way operation)

## Project Structure

```
admin-panel/
├── public/           # Static files
├── src/
│   ├── components/   # Reusable React components
│   ├── contexts/     # React contexts (Auth, etc.)
│   ├── pages/        # Page components
│   ├── services/     # API service layer
│   ├── theme/        # Material-UI theme configuration
│   ├── App.js        # Main app component
│   └── index.js      # Entry point
├── .env.development  # Development environment variables
├── .env.production   # Production environment variables
└── package.json      # Dependencies and scripts
```

## Authentication

The admin panel uses JWT-based authentication with refresh token support. Tokens are stored in localStorage and automatically refreshed when expired.

## License

Proprietary - EXPO to World

