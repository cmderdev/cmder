import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import RouteGuard from './components/RouteGuard';
import SplashScreen from './pages/SplashScreen';
import WelcomeScreen from './pages/WelcomeScreen';
import HomePage from './pages/HomePage';
import sessionService from './services/sessionService';

// Initialize session service with backend URL
// In production, this should come from environment variables
const BACKEND_URL = process.env.REACT_APP_BACKEND_URL || 'http://localhost:3000';
sessionService.initializeSocket(BACKEND_URL);

/**
 * Main App Component
 * Sets up routing with route guards for session and welcome screen checks
 */
function App() {
  return (
    <Router>
      <Routes>
        {/* Public routes - no guard needed */}
        <Route path="/splash" element={<SplashScreen />} />
        <Route path="/welcome" element={<WelcomeScreen />} />
        
        {/* Protected routes - with route guard */}
        <Route 
          path="/tabs/home" 
          element={
            <RouteGuard>
              <HomePage />
            </RouteGuard>
          } 
        />
        
        {/* Add more tab routes here as needed */}
        <Route 
          path="/tabs/settings" 
          element={
            <RouteGuard>
              <div>Settings Page (placeholder)</div>
            </RouteGuard>
          } 
        />
        
        <Route 
          path="/tabs/profile" 
          element={
            <RouteGuard>
              <div>Profile Page (placeholder)</div>
            </RouteGuard>
          } 
        />
        
        {/* Default redirect */}
        <Route path="/" element={<Navigate to="/tabs/home" replace />} />
        
        {/* Catch all - redirect to home */}
        <Route path="*" element={<Navigate to="/tabs/home" replace />} />
      </Routes>
    </Router>
  );
}

export default App;
