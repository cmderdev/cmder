import { sessionService } from '../sessionService';

// Mock fetch globally
global.fetch = jest.fn();

// Mock Socket.IO
jest.mock('socket.io-client', () => {
  return jest.fn(() => ({
    on: jest.fn(),
    connect: jest.fn(),
    disconnect: jest.fn(),
    connected: false,
    auth: {}
  }));
});

describe('SessionService', () => {
  beforeEach(() => {
    // Clear all mocks
    jest.clearAllMocks();
    
    // Clear localStorage
    localStorage.clear();
    
    // Reset session service state
    sessionService.sessionToken = null;
    sessionService.sessionCallbacks = [];
  });

  describe('acquireSession', () => {
    it('should successfully acquire a session token', async () => {
      const mockToken = 'test-token-123';
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ token: mockToken })
      });

      const result = await sessionService.acquireSession();

      expect(result.success).toBe(true);
      expect(result.token).toBe(mockToken);
      expect(sessionService.sessionToken).toBe(mockToken);
      expect(localStorage.getItem('sessionToken')).toBe(mockToken);
    });

    it('should handle server error when acquiring session', async () => {
      const errorMessage = 'Server rejected session creation';
      global.fetch.mockResolvedValueOnce({
        ok: false,
        status: 403,
        json: async () => ({ message: errorMessage })
      });

      const result = await sessionService.acquireSession();

      expect(result.success).toBe(false);
      expect(result.error).toBe(errorMessage);
      expect(sessionService.sessionToken).toBeNull();
    });

    it('should handle network error', async () => {
      global.fetch.mockRejectedValueOnce(new Error('Network error'));

      const result = await sessionService.acquireSession();

      expect(result.success).toBe(false);
      expect(result.error).toBe('Network error');
    });

    it('should handle missing token in response', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({}) // No token field
      });

      const result = await sessionService.acquireSession();

      expect(result.success).toBe(false);
      expect(result.error).toBe('No token received from server');
    });
  });

  describe('validateSession', () => {
    it('should validate a valid session', async () => {
      const mockToken = 'valid-token';
      sessionService.sessionToken = mockToken;

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ valid: true })
      });

      const result = await sessionService.validateSession();

      expect(result).toBe(true);
      expect(global.fetch).toHaveBeenCalledWith(
        '/api/session/validate',
        expect.objectContaining({
          headers: expect.objectContaining({
            'Authorization': `Bearer ${mockToken}`
          })
        })
      );
    });

    it('should return false for invalid session', async () => {
      sessionService.sessionToken = 'invalid-token';

      global.fetch.mockResolvedValueOnce({
        ok: false,
        status: 401
      });

      const result = await sessionService.validateSession();

      expect(result).toBe(false);
      expect(sessionService.sessionToken).toBeNull();
    });

    it('should return false when no token exists', async () => {
      sessionService.sessionToken = null;

      const result = await sessionService.validateSession();

      expect(result).toBe(false);
      expect(global.fetch).not.toHaveBeenCalled();
    });

    it('should handle validation network error', async () => {
      sessionService.sessionToken = 'some-token';
      global.fetch.mockRejectedValueOnce(new Error('Network error'));

      const result = await sessionService.validateSession();

      expect(result).toBe(false);
    });
  });

  describe('getSessionToken', () => {
    it('should return token from memory', () => {
      sessionService.sessionToken = 'memory-token';
      expect(sessionService.getSessionToken()).toBe('memory-token');
    });

    it('should retrieve token from localStorage if not in memory', () => {
      localStorage.setItem('sessionToken', 'stored-token');
      sessionService.sessionToken = null;

      expect(sessionService.getSessionToken()).toBe('stored-token');
      expect(sessionService.sessionToken).toBe('stored-token');
    });

    it('should return null if no token exists', () => {
      expect(sessionService.getSessionToken()).toBeNull();
    });
  });

  describe('clearSession', () => {
    it('should clear session token from memory and storage', () => {
      sessionService.sessionToken = 'test-token';
      localStorage.setItem('sessionToken', 'test-token');

      sessionService.clearSession();

      expect(sessionService.sessionToken).toBeNull();
      expect(localStorage.getItem('sessionToken')).toBeNull();
    });
  });

  describe('handleSessionRevoked', () => {
    it('should clear session and notify callbacks', () => {
      sessionService.sessionToken = 'test-token';
      const callback = jest.fn();
      sessionService.onSessionChange(callback);

      sessionService.handleSessionRevoked();

      expect(sessionService.sessionToken).toBeNull();
      expect(callback).toHaveBeenCalledWith(false);
    });
  });
});
