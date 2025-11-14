/**
 * Storage utility for managing app state in localStorage
 */

const STORAGE_KEYS = {
  WELCOME_SHOWN: 'cmder_welcome_shown',
  SESSION_TOKEN: 'sessionToken'
};

class StorageService {
  /**
   * Check if welcome screen has been shown
   * @returns {boolean}
   */
  isWelcomeShown() {
    return localStorage.getItem(STORAGE_KEYS.WELCOME_SHOWN) === 'true';
  }

  /**
   * Mark welcome screen as shown
   */
  setWelcomeShown() {
    localStorage.setItem(STORAGE_KEYS.WELCOME_SHOWN, 'true');
  }

  /**
   * Reset welcome screen flag (for testing)
   */
  resetWelcomeShown() {
    localStorage.removeItem(STORAGE_KEYS.WELCOME_SHOWN);
  }

  /**
   * Get session token
   * @returns {string|null}
   */
  getSessionToken() {
    return localStorage.getItem(STORAGE_KEYS.SESSION_TOKEN);
  }

  /**
   * Set session token
   * @param {string} token
   */
  setSessionToken(token) {
    localStorage.setItem(STORAGE_KEYS.SESSION_TOKEN, token);
  }

  /**
   * Clear session token
   */
  clearSessionToken() {
    localStorage.removeItem(STORAGE_KEYS.SESSION_TOKEN);
  }

  /**
   * Clear all app data
   */
  clearAll() {
    Object.values(STORAGE_KEYS).forEach(key => {
      localStorage.removeItem(key);
    });
  }
}

export const storageService = new StorageService();
export default storageService;
