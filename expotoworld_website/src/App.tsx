import { Routes, Route } from 'react-router-dom';
import { Layout } from '@components';
import { Home, Privacy, Terms } from './pages';
import './index.css';

/**
 * Main App Component with Routing
 * EXPO to WORLD Website
 */
function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/privacy" element={<Privacy />} />
        <Route path="/terms" element={<Terms />} />
      </Routes>
    </Layout>
  );
}

export default App;
