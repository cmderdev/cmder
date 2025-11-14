import React, { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import sessionService from '../services/sessionService';
import storageService from '../services/storageService';

/**
 * RouteGuard Component
 * Protects routes by checking session validity and welcome screen status
 * 
 * Requirements:
 * 1. If welcome screen hasn't been shown, show it (then navigate back to intended page)
 * 2. If session is not valid/available, redirect to splash screen
 * 3. Only perform checks on initial load, not on refreshes
 */
const RouteGuard = ({ children }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const [isChecking, setIsChecking] = useState(true);
  const [shouldRender, setShouldRender] = useState(false);

  useEffect(() => {
    checkRouteAccess();
  }, [location.pathname]);

  /**
   * Check if user can access the current route
   */
  const checkRouteAccess = async () => {
    // Don't check on splash or welcome pages
    if (location.pathname === '/splash' || location.pathname === '/welcome') {
      setShouldRender(true);
      setIsChecking(false);
      return;
    }

    // Check if this is a refresh (using sessionStorage to detect)
    const isRefresh = sessionStorage.getItem('app_initialized') === 'true';
    
    if (isRefresh) {
      // On refresh, skip welcome/session checks
      setShouldRender(true);
      setIsChecking(false);
      return;
    }

    // First time loading the app
    // Check 1: Welcome screen
    const welcomeShown = storageService.isWelcomeShown();
    if (!welcomeShown) {
      // Save intended destination
      sessionStorage.setItem('intended_route', location.pathname);
      navigate('/welcome', { replace: true });
      setIsChecking(false);
      return;
    }

    // Check 2: Session validation
    const isSessionValid = await sessionService.validateSession();
    
    if (!isSessionValid) {
      // Missing or invalid token: redirect to splash
      sessionStorage.setItem('intended_route', location.pathname);
      navigate('/splash', { replace: true });
      setIsChecking(false);
      return;
    }

    // All checks passed
    sessionStorage.setItem('app_initialized', 'true');
    setShouldRender(true);
    setIsChecking(false);
  };

  // Listen for session revocation
  useEffect(() => {
    const handleSessionRevoked = (isValid) => {
      if (!isValid && location.pathname !== '/splash') {
        navigate('/splash', { replace: true });
      }
    };

    sessionService.onSessionChange(handleSessionRevoked);
  }, [navigate, location.pathname]);

  if (isChecking) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        fontSize: '18px',
        color: '#666'
      }}>
        Loading...
      </div>
    );
  }

  return shouldRender ? children : null;
};

export default RouteGuard;
