import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import './index.css';

import UsuarioPage from './pages/usuario';
import AdminPage from './pages/admin';
import GerentePage from './pages/gerente';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: 1, staleTime: 1000 * 60 * 5 },
  },
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Navigate to="/login" replace />} />
          <Route
            path="/login"
            element={
              <div className="min-h-screen bg-surface flex items-center justify-center">
                <p className="text-white text-lg">Login — se implementa en Grupo 1</p>
              </div>
            }
          />
          <Route path="/usuario/*" element={<UsuarioPage />} />
          <Route path="/admin/*" element={<AdminPage />} />
          <Route path="/gerente/*" element={<GerentePage />} />
          <Route
            path="*"
            element={
              <div className="min-h-screen bg-surface flex items-center justify-center">
                <p className="text-white">404 — Página no encontrada</p>
              </div>
            }
          />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  </React.StrictMode>,
);
