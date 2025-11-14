import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import sessionService from '../services/sessionService';

/**
 * Splash Screen Component
 * Handles session acquisition and displays error messages
 */
const SplashScreen = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    acquireNewSession();
  }, []);

  /**
   * Attempt to acquire a new session from backend
   */
  const acquireNewSession = async () => {
    setLoading(true);
    setError(null);

    const result = await sessionService.acquireSession();

    if (result.success) {
      // Session acquired successfully
      // Check if there was an intended route
      const intendedRoute = sessionStorage.getItem('intended_route');
      sessionStorage.removeItem('intended_route');
      
      // Mark app as initialized
      sessionStorage.setItem('app_initialized', 'true');
      
      // Navigate to intended route or default to home
      navigate(intendedRoute || '/tabs/home', { replace: true });
    } else {
      // Failed to acquire session
      setError(result.error || 'Failed to establish connection with server');
      setLoading(false);
    }
  };

  /**
   * Retry acquiring session
   */
  const handleRetry = () => {
    acquireNewSession();
  };

  return (
    <div style={styles.container}>
      <div style={styles.content}>
        <h1 style={styles.title}>Cmder</h1>
        
        {loading && (
          <div style={styles.loadingSection}>
            <div style={styles.spinner}></div>
            <p style={styles.loadingText}>Connecting to server...</p>
          </div>
        )}

        {error && (
          <div style={styles.errorSection}>
            <div style={styles.errorIcon}>⚠️</div>
            <p style={styles.errorTitle}>Connection Failed</p>
            <p style={styles.errorMessage}>{error}</p>
            <button 
              onClick={handleRetry}
              style={styles.retryButton}
            >
              Retry
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

const styles = {
  container: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    height: '100vh',
    backgroundColor: '#f5f5f5',
    fontFamily: 'system-ui, -apple-system, sans-serif'
  },
  content: {
    textAlign: 'center',
    padding: '40px',
    maxWidth: '400px'
  },
  title: {
    fontSize: '48px',
    fontWeight: 'bold',
    color: '#333',
    marginBottom: '40px',
    letterSpacing: '-1px'
  },
  loadingSection: {
    marginTop: '20px'
  },
  spinner: {
    border: '4px solid #f3f3f3',
    borderTop: '4px solid #007bff',
    borderRadius: '50%',
    width: '50px',
    height: '50px',
    animation: 'spin 1s linear infinite',
    margin: '0 auto 20px'
  },
  loadingText: {
    fontSize: '16px',
    color: '#666'
  },
  errorSection: {
    marginTop: '20px'
  },
  errorIcon: {
    fontSize: '48px',
    marginBottom: '15px'
  },
  errorTitle: {
    fontSize: '20px',
    fontWeight: 'bold',
    color: '#dc3545',
    marginBottom: '10px'
  },
  errorMessage: {
    fontSize: '14px',
    color: '#666',
    marginBottom: '25px',
    lineHeight: '1.5'
  },
  retryButton: {
    backgroundColor: '#007bff',
    color: 'white',
    border: 'none',
    borderRadius: '6px',
    padding: '12px 30px',
    fontSize: '16px',
    fontWeight: '500',
    cursor: 'pointer',
    transition: 'background-color 0.2s'
  }
};

export default SplashScreen;
