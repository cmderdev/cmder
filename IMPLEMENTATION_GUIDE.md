# Session Validation Implementation Guide

## Overview

This document describes the implementation of session validation and welcome screen logic for the Cmder mobile application.

## Requirements Addressed

✅ **Welcome Screen Check**: If welcome screen isn't shown, display it first, then navigate to the intended page
✅ **Session Validation**: Check if session is valid/available on tab navigation
✅ **Splash Screen Redirect**: Redirect to splash screen when session is invalid or missing
✅ **Socket.IO Integration**: Listen for server-side session revocation events
✅ **Error Display**: Show error messages on splash screen when session creation fails
✅ **Refresh Handling**: Skip checks on page refresh to avoid disrupting user experience

## Implementation Details

### 1. Route Guard (`RouteGuard.jsx`)

**Purpose**: Protects tab routes by checking welcome screen status and session validity.

**Logic Flow**:
```
1. Is current page public (splash/welcome)? → Yes → Allow access
2. Is this a page refresh? → Yes → Allow access (skip checks)
3. Has welcome been shown? → No → Navigate to /welcome
4. Is session valid? → No → Navigate to /splash
5. All checks passed → Allow access
```

**Key Features**:
- Uses `sessionStorage` to detect refresh vs initial load
- Saves intended route before redirecting
- Only runs checks on initial app load
- Listens for Socket.IO session revocation events

### 2. Session Service (`sessionService.js`)

**Purpose**: Manages session tokens, validates sessions, and handles Socket.IO communication.

**Key Methods**:
- `acquireSession()`: Get new session from backend
- `validateSession()`: Check if current session is valid
- `handleSessionRevoked()`: Handle server-side session revocation
- `initializeSocket()`: Setup Socket.IO connection

**Socket.IO Events**:
- Listens for: `session:revoked` from server
- Auto-reconnection enabled
- Sends token on connection

### 3. Storage Service (`storageService.js`)

**Purpose**: Manages localStorage for persistent data.

**Stored Data**:
- `cmder_welcome_shown`: Boolean flag for welcome screen
- `sessionToken`: Current session authentication token

### 4. Splash Screen (`SplashScreen.jsx`)

**Purpose**: Acquire new session and display errors.

**Features**:
- Automatic session acquisition on load
- Error message display from backend
- Retry button for failed attempts
- Navigates to intended route on success

### 5. Welcome Screen (`WelcomeScreen.jsx`)

**Purpose**: Onboarding experience for first-time users.

**Features**:
- Shows app features
- Marks welcome as shown on completion
- Navigates to intended route

## Navigation Scenarios

### Scenario 1: First App Launch (No Welcome, No Session)
```
User opens /tabs/home
  ↓
RouteGuard detects no welcome shown
  ↓
Navigate to /welcome (save intended: /tabs/home)
  ↓
User completes welcome
  ↓
Navigate to /tabs/home
  ↓
RouteGuard detects no valid session
  ↓
Navigate to /splash (save intended: /tabs/home)
  ↓
Splash acquires session
  ↓
Navigate to /tabs/home
  ↓
Success!
```

### Scenario 2: Returning User (Has Welcome, Has Session)
```
User opens /tabs/home
  ↓
RouteGuard checks welcome shown: ✓
  ↓
RouteGuard validates session: ✓
  ↓
Display /tabs/home
```

### Scenario 3: Page Refresh
```
User refreshes /tabs/home
  ↓
RouteGuard detects refresh (via sessionStorage)
  ↓
Skip all checks
  ↓
Display /tabs/home
```

### Scenario 4: Server Revokes Session
```
User browsing app
  ↓
Server sends 'session:revoked' event via Socket.IO
  ↓
sessionService.handleSessionRevoked() called
  ↓
Session cleared
  ↓
Navigate to /splash
  ↓
User sees splash screen to re-acquire session
```

### Scenario 5: Session Acquisition Fails
```
User at /splash
  ↓
Splash calls sessionService.acquireSession()
  ↓
Backend returns error: "Server at capacity"
  ↓
Splash displays error message
  ↓
User clicks "Retry"
  ↓
Try again
```

## Backend Integration

### Required Endpoints

#### POST `/api/session/acquire`
Creates a new session.

**Request**: 
```json
{
  "method": "POST",
  "headers": {
    "Content-Type": "application/json"
  }
}
```

**Success Response (200)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Response (4xx/5xx)**:
```json
{
  "message": "User-friendly error message"
}
```

#### GET `/api/session/validate`
Validates existing session.

**Request**:
```json
{
  "method": "GET",
  "headers": {
    "Authorization": "Bearer <token>",
    "Content-Type": "application/json"
  }
}
```

**Success Response (200)**:
```json
{
  "valid": true
}
```

**Invalid Response (401)**:
```json
{
  "valid": false
}
```

### Socket.IO Integration

**Server Setup**:
```javascript
io.on('connection', (socket) => {
  // Authenticate socket connection
  const token = socket.handshake.auth.token;
  
  // When revoking a session
  socket.emit('session:revoked');
});
```

**Client Setup** (already implemented):
```javascript
socket.on('session:revoked', () => {
  // Automatically handled by sessionService
});
```

## Testing

### Manual Testing Checklist

- [ ] First launch shows welcome screen
- [ ] Welcome screen navigates to intended page after completion
- [ ] Invalid session redirects to splash
- [ ] Splash screen acquires session successfully
- [ ] Splash screen displays error on failure
- [ ] Retry button works on splash screen
- [ ] Page refresh skips validation checks
- [ ] Socket.IO receives session revocation
- [ ] Session revocation redirects to splash
- [ ] Multiple tabs navigate correctly

### Unit Tests

Run tests with:
```bash
npm test
```

Tests cover:
- Session acquisition (success/failure)
- Session validation (valid/invalid)
- Token storage/retrieval
- Error handling
- Network failures

## Environment Setup

1. Copy environment template:
```bash
cp .env.example .env
```

2. Configure backend URL:
```bash
REACT_APP_BACKEND_URL=http://your-backend:port
```

3. Install dependencies:
```bash
npm install
```

4. Start development server:
```bash
npm start
```

## Troubleshooting

### Issue: Welcome screen shows every time
**Solution**: Check localStorage is not being cleared. Verify `cmder_welcome_shown` is set to 'true'.

### Issue: Session validation fails immediately
**Solution**: Check backend is running and `/api/session/validate` endpoint exists.

### Issue: Socket.IO not connecting
**Solution**: Verify `REACT_APP_BACKEND_URL` is correct and backend supports Socket.IO.

### Issue: Checks run on every refresh
**Solution**: Verify browser allows sessionStorage. Check `app_initialized` flag is set.

## Security Considerations

1. **Token Storage**: Tokens stored in localStorage (persistent across sessions)
2. **Token Transmission**: Tokens sent via Authorization header
3. **HTTPS**: Use HTTPS in production for secure token transmission
4. **Token Expiration**: Backend should implement token expiration
5. **Session Revocation**: Server can revoke sessions via Socket.IO

## Future Enhancements

- [ ] Add biometric authentication option
- [ ] Implement token refresh mechanism
- [ ] Add offline mode support
- [ ] Enhanced error messages with troubleshooting steps
- [ ] Session timeout warnings
- [ ] Multi-device session management
