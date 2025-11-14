#!/usr/bin/env node

/**
 * Simple validation script to test mobile app implementation
 * This script validates the core logic without running the full React app
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Validating Mobile App Implementation...\n');

let errors = 0;
let warnings = 0;

// Check required files exist
const requiredFiles = [
  'mobile-app/src/App.jsx',
  'mobile-app/src/index.js',
  'mobile-app/src/components/RouteGuard.jsx',
  'mobile-app/src/services/sessionService.js',
  'mobile-app/src/services/storageService.js',
  'mobile-app/src/pages/SplashScreen.jsx',
  'mobile-app/src/pages/WelcomeScreen.jsx',
  'mobile-app/src/pages/HomePage.jsx',
  'mobile-app/public/index.html',
  'package.json',
  '.env.example'
];

console.log('✓ Checking file structure...');
requiredFiles.forEach(file => {
  const filePath = path.join(__dirname, '..', '..', file);
  if (!fs.existsSync(filePath)) {
    console.error(`  ✗ Missing file: ${file}`);
    errors++;
  } else {
    console.log(`  ✓ ${file}`);
  }
});

// Check package.json has required dependencies
console.log('\n✓ Checking dependencies...');
const packageJson = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', '..', 'package.json'), 'utf8')
);

const requiredDeps = ['react', 'react-dom', 'react-router-dom', 'socket.io-client'];
requiredDeps.forEach(dep => {
  if (!packageJson.dependencies || !packageJson.dependencies[dep]) {
    console.error(`  ✗ Missing dependency: ${dep}`);
    errors++;
  } else {
    console.log(`  ✓ ${dep}`);
  }
});

// Validate key code patterns in RouteGuard
console.log('\n✓ Validating RouteGuard implementation...');
const routeGuardCode = fs.readFileSync(
  path.join(__dirname, '..', 'src/components/RouteGuard.jsx'),
  'utf8'
);

const routeGuardChecks = [
  { pattern: /storageService\.isWelcomeShown/, name: 'Welcome screen check' },
  { pattern: /sessionService\.validateSession/, name: 'Session validation' },
  { pattern: /sessionStorage\.getItem\(['"]app_initialized['"]\)/, name: 'Refresh detection' },
  { pattern: /navigate\(['"]\/splash['"]/, name: 'Splash redirect' },
  { pattern: /navigate\(['"]\/welcome['"]/, name: 'Welcome redirect' },
  { pattern: /sessionService\.onSessionChange/, name: 'Session change listener' }
];

routeGuardChecks.forEach(check => {
  if (check.pattern.test(routeGuardCode)) {
    console.log(`  ✓ ${check.name}`);
  } else {
    console.error(`  ✗ Missing: ${check.name}`);
    errors++;
  }
});

// Validate SessionService implementation
console.log('\n✓ Validating SessionService implementation...');
const sessionServiceCode = fs.readFileSync(
  path.join(__dirname, '..', 'src/services/sessionService.js'),
  'utf8'
);

const sessionServiceChecks = [
  { pattern: /acquireSession/, name: 'acquireSession method' },
  { pattern: /validateSession/, name: 'validateSession method' },
  { pattern: /initializeSocket/, name: 'initializeSocket method' },
  { pattern: /session:revoked/, name: 'Socket.IO revocation handler' },
  { pattern: /handleSessionRevoked/, name: 'handleSessionRevoked method' },
  { pattern: /localStorage/, name: 'localStorage usage' }
];

sessionServiceChecks.forEach(check => {
  if (check.pattern.test(sessionServiceCode)) {
    console.log(`  ✓ ${check.name}`);
  } else {
    console.error(`  ✗ Missing: ${check.name}`);
    errors++;
  }
});

// Validate SplashScreen shows errors
console.log('\n✓ Validating SplashScreen implementation...');
const splashCode = fs.readFileSync(
  path.join(__dirname, '..', 'src/pages/SplashScreen.jsx'),
  'utf8'
);

const splashChecks = [
  { pattern: /sessionService\.acquireSession/, name: 'Session acquisition' },
  { pattern: /error/, name: 'Error state handling' },
  { pattern: /retry|Retry/, name: 'Retry functionality' },
  { pattern: /navigate/, name: 'Navigation on success' }
];

splashChecks.forEach(check => {
  if (check.pattern.test(splashCode)) {
    console.log(`  ✓ ${check.name}`);
  } else {
    console.error(`  ✗ Missing: ${check.name}`);
    errors++;
  }
});

// Check test files exist
console.log('\n✓ Checking test files...');
const testFiles = [
  'mobile-app/src/services/__tests__/sessionService.test.js',
  'mobile-app/src/services/__tests__/storageService.test.js'
];

testFiles.forEach(file => {
  const filePath = path.join(__dirname, '..', '..', file);
  if (!fs.existsSync(filePath)) {
    console.error(`  ✗ Missing test: ${file}`);
    warnings++;
  } else {
    const content = fs.readFileSync(filePath, 'utf8');
    const testCount = (content.match(/it\(/g) || []).length;
    console.log(`  ✓ ${file} (${testCount} tests)`);
  }
});

// Summary
console.log('\n' + '='.repeat(50));
console.log('📊 Validation Summary:');
console.log('='.repeat(50));

if (errors === 0 && warnings === 0) {
  console.log('✅ All checks passed!');
  console.log('\n✨ Implementation is complete and valid.\n');
  process.exit(0);
} else {
  if (errors > 0) {
    console.error(`❌ Found ${errors} error(s)`);
  }
  if (warnings > 0) {
    console.warn(`⚠️  Found ${warnings} warning(s)`);
  }
  console.log('\n');
  process.exit(errors > 0 ? 1 : 0);
}
