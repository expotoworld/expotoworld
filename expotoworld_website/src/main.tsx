import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import './index.css';
import './locales/i18n';

// Set document title based on region
// For CN: Must match ICP filing website name (网站名称)
const isChina = import.meta.env.VITE_REGION === 'china';
document.title = isChina 
  ? '爱科思堡沃尔德电子商务（温州市）有限公司' 
  : 'EXPO to WORLD';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </React.StrictMode>,
);
