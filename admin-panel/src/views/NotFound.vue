<template>
  <div class="admin-not-found">
    <div class="container">
      <div class="error-header">
        <div class="status-code">
          <span class="digit">4</span>
          <div class="icon-wrapper">
            <svg viewBox="0 0 24 24" class="error-icon">
              <path fill="currentColor" d="M12,2C17.53,2 22,6.47 22,12C22,17.53 17.53,22 12,22C6.47,22 2,17.53 2,12C2,6.47 6.47,2 12,2M15.59,7L12,10.59L8.41,7L7,8.41L10.59,12L7,15.59L8.41,17L12,13.41L15.59,17L17,15.59L13.41,12L17,8.41L15.59,7Z" />
            </svg>
          </div>
          <span class="digit">4</span>
        </div>
        <h1 class="error-title">Resource Not Found</h1>
        <p class="error-subtitle">The requested resource could not be located on this server</p>
      </div>

      <div class="error-body">
        <div class="info-card">
          <div class="card-header">
            <svg viewBox="0 0 24 24" class="card-icon">
              <path fill="currentColor" d="M13,9H11V7H13M13,17H11V11H13M12,2A10,10 0 0,0 2,12A10,10 0 0,0 12,22A10,10 0 0,0 22,12A10,10 0 0,0 12,2Z" />
            </svg>
            <h2>Request Information</h2>
          </div>
          <div class="info-grid">
            <div class="info-item">
              <span class="label">Requested Path:</span>
              <span class="value code">{{ requestInfo.path }}</span>
            </div>
            <div class="info-item">
              <span class="label">Method:</span>
              <span class="value badge">{{ requestInfo.method }}</span>
            </div>
            <div class="info-item">
              <span class="label">Timestamp:</span>
              <span class="value">{{ requestInfo.timestamp }}</span>
            </div>
            <div class="info-item">
              <span class="label">User Agent:</span>
              <span class="value code small">{{ requestInfo.userAgent }}</span>
            </div>
            <div class="info-item">
              <span class="label">Referrer:</span>
              <span class="value code">{{ requestInfo.referrer || 'Direct access' }}</span>
            </div>
            <div class="info-item">
              <span class="label">Query Parameters:</span>
              <span class="value code">{{ requestInfo.queryParams || 'None' }}</span>
            </div>
          </div>
        </div>

        <div class="info-card">
          <div class="card-header">
            <svg viewBox="0 0 24 24" class="card-icon">
              <path fill="currentColor" d="M9,5V9H21V5M9,19H21V15H9M9,14H21V10H9M4,9H8V5H4M4,19H8V15H4M4,14H8V10H4V14Z" />
            </svg>
            <h2>Debug Information</h2>
          </div>
          <div class="debug-info">
            <div class="debug-item">
              <span class="label">Route Name:</span>
              <span class="value code">{{ route.name }}</span>
            </div>
            <div class="debug-item">
              <span class="label">Matched Pattern:</span>
              <span class="value code">/:pathMatch(.*)*</span>
            </div>
            <div class="debug-item">
              <span class="label">Full Path:</span>
              <span class="value code">{{ route.fullPath }}</span>
            </div>
            <div class="debug-item">
              <span class="label">Hash:</span>
              <span class="value code">{{ route.hash || 'N/A' }}</span>
            </div>
          </div>
        </div>

        <div class="info-card action-card">
          <div class="card-header">
            <svg viewBox="0 0 24 24" class="card-icon">
              <path fill="currentColor" d="M12,2A10,10 0 0,1 22,12A10,10 0 0,1 12,22A10,10 0 0,1 2,12A10,10 0 0,1 12,2M12,4A8,8 0 0,0 4,12A8,8 0 0,0 12,20A8,8 0 0,0 20,12A8,8 0 0,0 12,4M11,16.5L6.5,12L7.91,10.59L11,13.67L16.59,8.09L18,9.5L11,16.5Z" />
            </svg>
            <h2>What to Do Next</h2>
          </div>
          <ul class="action-list">
            <li>
              <svg viewBox="0 0 24 24" class="action-icon">
                <path fill="currentColor" d="M10,20V14H14V20H19V12H22L12,3L2,12H5V20H10Z" />
              </svg>
              <div>
                <strong>Return to Dashboard</strong>
                <p>Go back to the main admin panel</p>
              </div>
            </li>
            <li>
              <svg viewBox="0 0 24 24" class="action-icon">
                <path fill="currentColor" d="M20,11V13H8L13.5,18.5L12.08,19.92L4.16,12L12.08,4.08L13.5,5.5L8,11H20Z" />
              </svg>
              <div>
                <strong>Go Back</strong>
                <p>Return to the previous page</p>
              </div>
            </li>
            <li>
              <svg viewBox="0 0 24 24" class="action-icon">
                <path fill="currentColor" d="M9.5,3A6.5,6.5 0 0,1 16,9.5C16,11.11 15.41,12.59 14.44,13.73L14.71,14H15.5L20.5,19L19,20.5L14,15.5V14.71L13.73,14.44C12.59,15.41 11.11,16 9.5,16A6.5,6.5 0 0,1 3,9.5A6.5,6.5 0 0,1 9.5,3M9.5,5C7,5 5,7 5,9.5C5,12 7,14 9.5,14C12,14 14,12 14,9.5C14,7 12,5 9.5,5Z" />
              </svg>
              <div>
                <strong>Search Documentation</strong>
                <p>Check the docs for the correct path</p>
              </div>
            </li>
            <li>
              <svg viewBox="0 0 24 24" class="action-icon">
                <path fill="currentColor" d="M20,8L12,13L4,8V6L12,11L20,6M20,4H4C2.89,4 2,4.89 2,6V18A2,2 0 0,0 4,20H20A2,2 0 0,0 22,18V6C22,4.89 21.1,4 20,4Z" />
              </svg>
              <div>
                <strong>Report Issue</strong>
                <p>Contact support if you believe this is an error</p>
              </div>
            </li>
          </ul>
        </div>

        <div class="action-buttons">
          <button class="btn btn-primary" @click="goToDashboard">
            <svg viewBox="0 0 24 24" class="btn-icon">
              <path fill="currentColor" d="M10,20V14H14V20H19V12H22L12,3L2,12H5V20H10Z" />
            </svg>
            Dashboard
          </button>
          <button class="btn btn-secondary" @click="goBack">
            <svg viewBox="0 0 24 24" class="btn-icon">
              <path fill="currentColor" d="M20,11V13H8L13.5,18.5L12.08,19.92L4.16,12L12.08,4.08L13.5,5.5L8,11H20Z" />
            </svg>
            Go Back
          </button>
          <button class="btn btn-outline" @click="copyDebugInfo">
            <svg viewBox="0 0 24 24" class="btn-icon">
              <path fill="currentColor" d="M19,21H8V7H19M19,5H8A2,2 0 0,0 6,7V21A2,2 0 0,0 8,23H19A2,2 0 0,0 21,21V7A2,2 0 0,0 19,5M16,1H4A2,2 0 0,0 2,3V17H4V3H16V1Z" />
            </svg>
            Copy Debug Info
          </button>
        </div>
      </div>

      <div class="footer">
        <p>Error Code: 404 | Admin Panel v1.0.0</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

const requestInfo = ref({
  path: '',
  method: 'GET',
  timestamp: '',
  userAgent: '',
  referrer: '',
  queryParams: ''
})

onMounted(() => {
  requestInfo.value = {
    path: route.fullPath,
    method: 'GET',
    timestamp: new Date().toLocaleString(),
    userAgent: navigator.userAgent,
    referrer: document.referrer,
    queryParams: Object.keys(route.query).length > 0 
      ? JSON.stringify(route.query, null, 2) 
      : 'None'
  }
})

const goToDashboard = () => {
  router.push('/')
}

const goBack = () => {
  router.back()
}

const copyDebugInfo = () => {
  const debugInfo = `
404 Error Debug Information
===========================
Path: ${requestInfo.value.path}
Timestamp: ${requestInfo.value.timestamp}
User Agent: ${requestInfo.value.userAgent}
Referrer: ${requestInfo.value.referrer}
Query Parameters: ${requestInfo.value.queryParams}
Route Name: ${route.name}
Full Path: ${route.fullPath}
Hash: ${route.hash || 'N/A'}
  `.trim()
  
  navigator.clipboard.writeText(debugInfo).then(() => {
    alert('Debug information copied to clipboard!')
  })
}
</script>

<style scoped>
.admin-not-found {
  min-height: 100vh;
  background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
  padding: 2rem 1rem;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

.container {
  max-width: 1000px;
  margin: 0 auto;
}

.error-header {
  text-align: center;
  margin-bottom: 3rem;
  animation: fadeInDown 0.6s ease-out;
}

@keyframes fadeInDown {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.status-code {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.digit {
  font-size: 6rem;
  font-weight: 800;
  color: white;
  text-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  animation: pulse 2s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

.icon-wrapper {
  width: 80px;
  height: 80px;
  background: rgba(231, 76, 60, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  animation: rotate 3s linear infinite;
}

@keyframes rotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.error-icon {
  width: 48px;
  height: 48px;
  color: #e74c3c;
}

.error-title {
  color: white;
  font-size: 2.5rem;
  margin: 0 0 0.5rem 0;
  font-weight: 700;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.error-subtitle {
  color: rgba(255, 255, 255, 0.9);
  font-size: 1.125rem;
  margin: 0;
}

.error-body {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  animation: fadeInUp 0.6s ease-out 0.2s both;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.info-card {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.info-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.2);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
  padding-bottom: 1rem;
  border-bottom: 2px solid #f0f0f0;
}

.card-icon {
  width: 28px;
  height: 28px;
  color: #3498db;
}

.card-header h2 {
  margin: 0;
  font-size: 1.25rem;
  color: #2c3e50;
  font-weight: 600;
}

.info-grid {
  display: grid;
  gap: 1rem;
}

.info-item,
.debug-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.label {
  font-size: 0.875rem;
  color: #7f8c8d;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.value {
  font-size: 1rem;
  color: #2c3e50;
  word-break: break-all;
}

.value.code {
  background: #f8f9fa;
  padding: 0.5rem;
  border-radius: 6px;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 0.875rem;
  border-left: 3px solid #3498db;
}

.value.code.small {
  font-size: 0.75rem;
}

.value.badge {
  display: inline-block;
  background: #3498db;
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 600;
  width: fit-content;
}

.debug-info {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.action-card {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
}

.action-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.action-list li {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  padding: 1rem;
  background: white;
  border-radius: 8px;
  transition: all 0.3s ease;
  cursor: pointer;
}

.action-list li:hover {
  transform: translateX(8px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.action-icon {
  width: 24px;
  height: 24px;
  color: #3498db;
  flex-shrink: 0;
  margin-top: 2px;
}

.action-list li strong {
  display: block;
  color: #2c3e50;
  font-size: 1rem;
  margin-bottom: 0.25rem;
}

.action-list li p {
  margin: 0;
  color: #7f8c8d;
  font-size: 0.875rem;
}

.action-buttons {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  margin-top: 1rem;
}

.btn {
  flex: 1;
  min-width: 140px;
  padding: 0.875rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.btn-icon {
  width: 20px;
  height: 20px;
}

.btn-primary {
  background: #3498db;
  color: white;
  box-shadow: 0 4px 12px rgba(52, 152, 219, 0.3);
}

.btn-primary:hover {
  background: #2980b9;
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(52, 152, 219, 0.4);
}

.btn-secondary {
  background: #95a5a6;
  color: white;
  box-shadow: 0 4px 12px rgba(149, 165, 166, 0.3);
}

.btn-secondary:hover {
  background: #7f8c8d;
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(149, 165, 166, 0.4);
}

.btn-outline {
  background: white;
  color: #3498db;
  border: 2px solid #3498db;
}

.btn-outline:hover {
  background: #3498db;
  color: white;
  transform: translateY(-2px);
}

.btn:active {
  transform: translateY(0);
}

.footer {
  text-align: center;
  margin-top: 3rem;
  padding-top: 2rem;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
}

.footer p {
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.875rem;
  margin: 0;
}

/* Responsive design */
@media (max-width: 768px) {
  .admin-not-found {
    padding: 1rem 0.5rem;
  }
  
  .digit {
    font-size: 4rem;
  }
  
  .icon-wrapper {
    width: 60px;
    height: 60px;
  }
  
  .error-icon {
    width: 36px;
    height: 36px;
  }
  
  .error-title {
    font-size: 1.75rem;
  }
  
  .error-subtitle {
    font-size: 1rem;
  }
  
  .info-card {
    padding: 1.25rem;
  }
  
  .action-buttons {
    flex-direction: column;
  }
  
  .btn {
    width: 100%;
  }
  
  .action-list li {
    flex-direction: column;
    align-items: flex-start;
  }
}

@media (min-width: 769px) {
  .error-body {
    animation-delay: 0.3s;
  }
}
</style>
