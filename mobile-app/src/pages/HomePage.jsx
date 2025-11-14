import React from 'react';

/**
 * Home Tab Component
 */
const HomePage = () => {
  return (
    <div style={styles.container}>
      <div style={styles.content}>
        <h1 style={styles.title}>Home</h1>
        <p style={styles.subtitle}>Welcome to your Cmder mobile terminal</p>
        
        <div style={styles.infoBox}>
          <p style={styles.infoText}>
            This is the home tab. Your session is active and validated.
          </p>
          <p style={styles.infoText}>
            Session checks are performed automatically in the background.
          </p>
        </div>
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
    fontSize: '32px',
    fontWeight: 'bold',
    color: '#333',
    marginBottom: '10px'
  },
  subtitle: {
    fontSize: '16px',
    color: '#666',
    marginBottom: '30px'
  },
  infoBox: {
    backgroundColor: 'white',
    padding: '25px',
    borderRadius: '12px',
    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
    textAlign: 'left'
  },
  infoText: {
    fontSize: '14px',
    color: '#333',
    lineHeight: '1.6',
    marginBottom: '10px'
  }
};

export default HomePage;
