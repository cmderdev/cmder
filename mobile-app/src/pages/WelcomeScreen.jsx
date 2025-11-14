import React from 'react';
import { useNavigate } from 'react-router-dom';
import storageService from '../services/storageService';

/**
 * Welcome Screen Component
 * Shows app introduction and onboarding
 */
const WelcomeScreen = () => {
  const navigate = useNavigate();

  /**
   * Complete welcome screen and navigate to intended route
   */
  const handleComplete = () => {
    // Mark welcome as shown
    storageService.setWelcomeShown();
    
    // Get intended route or default to home
    const intendedRoute = sessionStorage.getItem('intended_route');
    sessionStorage.removeItem('intended_route');
    
    // Navigate to the intended page
    navigate(intendedRoute || '/tabs/home', { replace: true });
  };

  return (
    <div style={styles.container}>
      <div style={styles.content}>
        <h1 style={styles.title}>Welcome to Cmder</h1>
        
        <div style={styles.features}>
          <div style={styles.feature}>
            <div style={styles.featureIcon}>🚀</div>
            <h3 style={styles.featureTitle}>Fast & Powerful</h3>
            <p style={styles.featureText}>
              Experience lightning-fast command execution with a powerful terminal
            </p>
          </div>
          
          <div style={styles.feature}>
            <div style={styles.featureIcon}>🔒</div>
            <h3 style={styles.featureTitle}>Secure Sessions</h3>
            <p style={styles.featureText}>
              Your sessions are protected with real-time validation
            </p>
          </div>
          
          <div style={styles.feature}>
            <div style={styles.featureIcon}>📱</div>
            <h3 style={styles.featureTitle}>Mobile Ready</h3>
            <p style={styles.featureText}>
              Access your terminal from anywhere, anytime
            </p>
          </div>
        </div>

        <button 
          onClick={handleComplete}
          style={styles.continueButton}
        >
          Get Started
        </button>
      </div>
    </div>
  );
};

const styles = {
  container: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: '100vh',
    backgroundColor: '#f5f5f5',
    fontFamily: 'system-ui, -apple-system, sans-serif',
    padding: '20px'
  },
  content: {
    textAlign: 'center',
    maxWidth: '600px',
    width: '100%'
  },
  title: {
    fontSize: '36px',
    fontWeight: 'bold',
    color: '#333',
    marginBottom: '50px'
  },
  features: {
    display: 'flex',
    flexDirection: 'column',
    gap: '30px',
    marginBottom: '50px'
  },
  feature: {
    backgroundColor: 'white',
    padding: '25px',
    borderRadius: '12px',
    boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
  },
  featureIcon: {
    fontSize: '48px',
    marginBottom: '15px'
  },
  featureTitle: {
    fontSize: '20px',
    fontWeight: '600',
    color: '#333',
    marginBottom: '10px'
  },
  featureText: {
    fontSize: '14px',
    color: '#666',
    lineHeight: '1.6'
  },
  continueButton: {
    backgroundColor: '#007bff',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    padding: '15px 40px',
    fontSize: '18px',
    fontWeight: '600',
    cursor: 'pointer',
    transition: 'background-color 0.2s',
    width: '100%',
    maxWidth: '300px'
  }
};

export default WelcomeScreen;
