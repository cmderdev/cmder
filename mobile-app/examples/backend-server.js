/**
 * Example Backend Server for Cmder Mobile App
 * 
 * This is a minimal implementation showing the required API endpoints
 * for session management and Socket.IO integration.
 * 
 * To run: node mobile-app/examples/backend-server.js
 */

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const crypto = require('crypto');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: ['http://localhost:3000', 'http://localhost:3001'],
    methods: ['GET', 'POST']
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// In-memory session storage (use a real database in production)
const sessions = new Map();

// Generate a simple token
function generateToken() {
  return crypto.randomBytes(32).toString('hex');
}

// Validate token format
function isValidToken(token) {
  return typeof token === 'string' && token.length === 64;
}

/**
 * POST /api/session/acquire
 * Acquire a new session token
 */
app.post('/api/session/acquire', (req, res) => {
  try {
    // Generate new token
    const token = generateToken();
    
    // Store session
    sessions.set(token, {
      createdAt: Date.now(),
      lastAccess: Date.now()
    });

    console.log(`✓ New session created: ${token.substring(0, 8)}...`);

    res.json({ token });
  } catch (error) {
    console.error('Error creating session:', error);
    res.status(500).json({
      message: 'Failed to create session. Please try again later.'
    });
  }
});

/**
 * GET /api/session/validate
 * Validate an existing session token
 */
app.get('/api/session/validate', (req, res) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ valid: false });
  }

  const token = authHeader.substring(7);
  
  if (!isValidToken(token)) {
    return res.status(401).json({ valid: false });
  }

  const session = sessions.get(token);
  
  if (!session) {
    console.log(`✗ Invalid session: ${token.substring(0, 8)}...`);
    return res.status(401).json({ valid: false });
  }

  // Update last access time
  session.lastAccess = Date.now();
  
  console.log(`✓ Valid session: ${token.substring(0, 8)}...`);
  res.json({ valid: true });
});

/**
 * DELETE /api/session/revoke (optional endpoint for testing)
 * Revoke a session and notify via Socket.IO
 */
app.delete('/api/session/revoke', (req, res) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No token provided' });
  }

  const token = authHeader.substring(7);
  
  if (sessions.has(token)) {
    sessions.delete(token);
    
    // Notify client via Socket.IO
    const socketId = tokenToSocketMap.get(token);
    if (socketId) {
      io.to(socketId).emit('session:revoked');
      tokenToSocketMap.delete(token);
    }
    
    console.log(`✓ Session revoked: ${token.substring(0, 8)}...`);
    res.json({ message: 'Session revoked' });
  } else {
    res.status(404).json({ message: 'Session not found' });
  }
});

// Map tokens to socket IDs for session revocation
const tokenToSocketMap = new Map();

/**
 * Socket.IO connection handler
 */
io.on('connection', (socket) => {
  console.log(`✓ Client connected: ${socket.id}`);

  // Authenticate socket connection
  const token = socket.handshake.auth.token;
  
  if (token && sessions.has(token)) {
    tokenToSocketMap.set(token, socket.id);
    console.log(`  Authenticated with token: ${token.substring(0, 8)}...`);
  } else {
    console.log(`  ⚠ Connected without valid token`);
  }

  socket.on('disconnect', () => {
    console.log(`✗ Client disconnected: ${socket.id}`);
    
    // Clean up token mapping
    if (token) {
      tokenToSocketMap.delete(token);
    }
  });
});

// Clean up old sessions every hour
setInterval(() => {
  const now = Date.now();
  const oneHour = 60 * 60 * 1000;
  
  for (const [token, session] of sessions.entries()) {
    if (now - session.lastAccess > oneHour) {
      sessions.delete(token);
      console.log(`Cleaned up old session: ${token.substring(0, 8)}...`);
    }
  }
}, 60 * 60 * 1000);

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log('\n' + '='.repeat(50));
  console.log('🚀 Cmder Backend Server');
  console.log('='.repeat(50));
  console.log(`Server running on http://localhost:${PORT}`);
  console.log('\nAvailable endpoints:');
  console.log(`  POST   http://localhost:${PORT}/api/session/acquire`);
  console.log(`  GET    http://localhost:${PORT}/api/session/validate`);
  console.log(`  DELETE http://localhost:${PORT}/api/session/revoke`);
  console.log('\nSocket.IO enabled for real-time session revocation');
  console.log('='.repeat(50) + '\n');
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n\nShutting down server...');
  server.close(() => {
    console.log('Server stopped');
    process.exit(0);
  });
});
