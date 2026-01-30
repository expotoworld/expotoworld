import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import App from './App'
import VersionInspector from './VersionInspector'
import { installAxiosInterceptors } from './auth'
import './styles.css'

installAxiosInterceptors()

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/ebook-editor/:ebookId/versions/:id" element={<VersionInspector />} />
        <Route path="/ebook-editor/:ebookId" element={<App />} />
        {/* Redirect root to default ebook (slug: main) */}
        <Route path="/ebook-editor" element={<Navigate to="/ebook-editor/main" replace />} />
        <Route path="/*" element={<Navigate to="/ebook-editor/main" replace />} />
      </Routes>
    </BrowserRouter>
  </React.StrictMode>
)
