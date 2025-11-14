import { storageService } from '../storageService';

describe('StorageService', () => {
  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear();
  });

  describe('Welcome Screen', () => {
    it('should return false when welcome screen has not been shown', () => {
      expect(storageService.isWelcomeShown()).toBe(false);
    });

    it('should return true after welcome screen is marked as shown', () => {
      storageService.setWelcomeShown();
      expect(storageService.isWelcomeShown()).toBe(true);
    });

    it('should persist welcome shown flag across service instances', () => {
      storageService.setWelcomeShown();
      expect(localStorage.getItem('cmder_welcome_shown')).toBe('true');
    });

    it('should reset welcome shown flag', () => {
      storageService.setWelcomeShown();
      expect(storageService.isWelcomeShown()).toBe(true);
      
      storageService.resetWelcomeShown();
      expect(storageService.isWelcomeShown()).toBe(false);
    });
  });

  describe('Session Token', () => {
    it('should return null when no token exists', () => {
      expect(storageService.getSessionToken()).toBeNull();
    });

    it('should store and retrieve session token', () => {
      const token = 'test-session-token-123';
      storageService.setSessionToken(token);
      expect(storageService.getSessionToken()).toBe(token);
    });

    it('should clear session token', () => {
      storageService.setSessionToken('test-token');
      expect(storageService.getSessionToken()).toBe('test-token');
      
      storageService.clearSessionToken();
      expect(storageService.getSessionToken()).toBeNull();
    });
  });

  describe('Clear All', () => {
    it('should clear all stored data', () => {
      storageService.setWelcomeShown();
      storageService.setSessionToken('test-token');
      
      storageService.clearAll();
      
      expect(storageService.isWelcomeShown()).toBe(false);
      expect(storageService.getSessionToken()).toBeNull();
    });
  });
});
