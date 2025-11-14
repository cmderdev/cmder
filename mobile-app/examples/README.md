# Backend Server Example

This directory contains an example backend server implementation that demonstrates the API endpoints required by the Cmder mobile application.

## Quick Start

```bash
# Install dependencies
npm install express socket.io cors

# Run the example server
node mobile-app/examples/backend-server.js
```

The server will start on `http://localhost:3000`

## Endpoints

### POST /api/session/acquire
Creates a new session token.

**Response (Success)**:
```json
{
  "token": "generated-jwt-token-here"
}
```

**Response (Error)**:
```json
{
  "message": "Error message to display"
}
```

### GET /api/session/validate
Validates an existing session token.

**Headers**:
```
Authorization: Bearer <token>
```

**Response (Success)**:
```json
{
  "valid": true
}
```

**Response (Invalid)**:
```json
{
  "valid": false
}
```

## Socket.IO Events

### server → client: `session:revoked`
Emitted when server wants to revoke a client's session.

```javascript
socket.emit('session:revoked');
```

## Testing the Server

1. Start the example server:
```bash
node mobile-app/examples/backend-server.js
```

2. In another terminal, test the endpoints:

```bash
# Acquire session
curl -X POST http://localhost:3000/api/session/acquire

# Validate session (replace TOKEN with actual token)
curl -H "Authorization: Bearer TOKEN" http://localhost:3000/api/session/validate
```

3. Start the mobile app:
```bash
npm start
```

The app should now connect to the backend and acquire a session successfully.
