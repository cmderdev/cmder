/**
 * Session Service
 * Handles session validation, token management, and Socket.IO communication
 */

import io from 'socket.io-client';

class SessionService {
  constructor() {
    this.socket = null;
    this.sessionToken = null;
    this.sessionCallbacks = [];
  }

  /**
   * Initialize Socket.IO connection
   * @param {string} serverUrl - Backend server URL
   */
  initializeSocket(serverUrl) {
    if (this.socket) {
      return;
    }

    this.socket = io(serverUrl, {
      autoConnect: false,
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5
    });

    // Listen for session revocation events from server
    this.socket.on('session:revoked', () => {
      console.log('Session revoked by server');
      this.handleSessionRevoked();
    });

    this.socket.on('connect', () => {
      console.log('Connected to server');
    });

    this.socket.on('disconnect', () => {
      console.log('Disconnected from server');
    });

    this.socket.on('error', (error) => {
      console.error('Socket error:', error);
    });
  }

  /**
   * Handle session revoked event
   */
  handleSessionRevoked() {
    this.clearSession();
    this.sessionCallbacks.forEach(callback => callback(false));
  }

  /**
   * Register a callback for session changes
   * @param {Function} callback - Function to call when session status changes
   */
  onSessionChange(callback) {
    this.sessionCallbacks.push(callback);
  }

  /**
   * Acquire a new session from the backend
   * @returns {Promise<{success: boolean, token?: string, error?: string}>}
   */
  async acquireSession() {
    try {
      const response = await fetch('/api/session/acquire', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          success: false,
          error: errorData.message || `Server error: ${response.status}`
        };
      }

      const data = await response.json();
      
      if (data.token) {
        this.sessionToken = data.token;
        localStorage.setItem('sessionToken', data.token);
        
        // Connect socket with the new session token
        if (this.socket && !this.socket.connected) {
          this.socket.auth = { token: data.token };
          this.socket.connect();
        }

        return { success: true, token: data.token };
      }

      return {
        success: false,
        error: 'No token received from server'
      };
    } catch (error) {
      console.error('Failed to acquire session:', error);
      return {
        success: false,
        error: error.message || 'Network error occurred'
      };
    }
  }

  /**
   * Validate current session with backend
   * @returns {Promise<boolean>}
   */
  async validateSession() {
    const token = this.getSessionToken();
    
    if (!token) {
      return false;
    }

    try {
      const response = await fetch('/api/session/validate', {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        this.clearSession();
        return false;
      }

      const data = await response.json();
      return data.valid === true;
    } catch (error) {
      console.error('Session validation failed:', error);
      return false;
    }
  }

  /**
   * Get current session token
   * @returns {string|null}
   */
  getSessionToken() {
    if (!this.sessionToken) {
      this.sessionToken = localStorage.getItem('sessionToken');
    }
    return this.sessionToken;
  }

  /**
   * Clear current session
   */
  clearSession() {
    this.sessionToken = null;
    localStorage.removeItem('sessionToken');
    
    if (this.socket && this.socket.connected) {
      this.socket.disconnect();
    }
  }

  /**
   * Disconnect socket
   */
  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
  }
}

// Export singleton instance
export const sessionService = new SessionService();
export default sessionService;
