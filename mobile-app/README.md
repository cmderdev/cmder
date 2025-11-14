# Cmder Mobile Application

## Overview

This is the mobile application companion for Cmder, implementing session management, welcome screens, and tab-based navigation.

## Architecture

### Key Features

1. **Welcome Screen Management**
   - Shows welcome screen on first app launch
   - Automatically navigates to intended page after completion
   - Persistent across app restarts using localStorage

2. **Session Validation**
   - Real-time session validation with backend
   - Automatic token management
   - Socket.IO integration for server-side session revocation

3. **Route Guards**
   - Protects all tab routes (`/tabs/*`)
   - Checks performed only on initial load (not on refresh)
   - Redirects to splash screen on invalid session
   - Redirects to welcome screen if not shown

## File Structure

```
mobile-app/
├── public/
│   └── index.html              # HTML template
├── src/
│   ├── components/
│   │   └── RouteGuard.jsx      # Route protection component
│   ├── pages/
│   │   ├── SplashScreen.jsx    # Session acquisition page
│   │   ├── WelcomeScreen.jsx   # Onboarding page
│   │   └── HomePage.jsx        # Home tab page
│   ├── services/
│   │   ├── sessionService.js   # Session & Socket.IO management
│   │   └── storageService.js   # localStorage utilities
│   ├── App.jsx                 # Main app with routing
│   └── index.js                # Entry point
```

## How It Works

### 1. Route Guard Logic

When navigating to any protected route (e.g., `/tabs/home`):

1. **Check if on public page**: Splash and welcome pages are not guarded
2. **Check if refresh**: Uses `sessionStorage` to detect app refresh
   - If refresh: Allow access (skip checks)
   - If initial load: Proceed with checks
3. **Check welcome screen**: 
   - If not shown: Navigate to `/welcome` (save intended route)
   - If shown: Continue to next check
4. **Check session validity**:
   - If valid: Allow access
   - If invalid/missing: Navigate to `/splash` (save intended route)

### 2. Session Management

The `sessionService` handles:
- **Token acquisition**: `/api/session/acquire` endpoint
- **Token validation**: `/api/session/validate` endpoint
- **Socket.IO connection**: Real-time session revocation events
- **Token storage**: localStorage for persistence

### 3. Socket.IO Integration

The app listens for `session:revoked` events from the server:
```javascript
socket.on('session:revoked', () => {
  // Clear session and redirect to splash
});
```

### 4. Error Handling

If session acquisition fails:
- Error message is displayed on splash screen
- User can retry manually
- Errors include server response messages

## Navigation Flow

### First App Launch
```
User opens app → Check welcome shown? (No) → Show welcome → 
User completes welcome → Navigate to intended route → Check session → 
Session valid? (No) → Splash screen → Acquire session → Navigate to intended route
```

### Subsequent Launches
```
User opens app → Check welcome shown? (Yes) → Check session → 
Session valid? (Yes) → Navigate to route
Session valid? (No) → Splash screen → Acquire session → Navigate to route
```

### On Refresh
```
User refreshes page → Detect refresh → Allow access (skip checks)
```

### Server Revokes Session
```
Socket receives 'session:revoked' → Clear session → Redirect to splash
```

## Backend API Requirements

The mobile app expects the following backend endpoints:

### POST /api/session/acquire
Acquires a new session token.

**Response (Success):**
```json
{
  "token": "session-token-here"
}
```

**Response (Error):**
```json
{
  "message": "Error message to display to user"
}
```

### GET /api/session/validate
Validates current session token.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (Success):**
```json
{
  "valid": true
}
```

**Response (Invalid):**
```json
{
  "valid": false
}
```

### Socket.IO Events

**Event: `session:revoked`**
Emitted by server when session is revoked.

```javascript
socket.emit('session:revoked');
```

## Environment Variables

Create a `.env` file in the root directory:

```
REACT_APP_BACKEND_URL=http://your-backend-url:port
```

## Installation

```bash
npm install
```

## Running the App

```bash
npm start
```

The app will open at `http://localhost:3000`

## Building for Production

```bash
npm run build
```

## Testing

```bash
npm test
```

## Notes

- Session tokens are stored in localStorage
- Welcome screen flag is stored in localStorage
- App initialization flag is stored in sessionStorage (cleared on browser close)
- All checks are skipped on page refresh to avoid disrupting user experience
- Socket.IO automatically reconnects on connection loss
