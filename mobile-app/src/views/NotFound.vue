<template>
  <div class="not-found-container">
    <div class="not-found-content">
      <div class="error-animation">
        <div class="number-wrapper">
          <span class="number">4</span>
          <div class="phone-icon">
            <div class="phone-screen">
              <div class="sad-face">:(</div>
            </div>
          </div>
          <span class="number">4</span>
        </div>
      </div>
      
      <h1 class="error-title">Page Not Found</h1>
      <p class="error-message">
        Oops! The page you're looking for seems to have wandered off.
      </p>
      
      <div class="error-details">
        <p class="path-info">
          <strong>Requested path:</strong> {{ currentPath }}
        </p>
      </div>
      
      <div class="actions">
        <button class="primary-button" @click="goHome">
          <span class="icon">🏠</span>
          Go Home
        </button>
        <button class="secondary-button" @click="goBack">
          <span class="icon">←</span>
          Go Back
        </button>
      </div>
      
      <div class="suggestions">
        <p class="suggestions-title">What can you do?</p>
        <ul>
          <li>Check the URL for typos</li>
          <li>Return to the home page</li>
          <li>Use the navigation menu</li>
          <li>Contact support if you believe this is an error</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

const currentPath = computed(() => route.path)

const goHome = () => {
  router.push('/')
}

const goBack = () => {
  router.back()
}
</script>

<style scoped>
.not-found-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 1rem;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
}

.not-found-content {
  background: white;
  border-radius: 24px;
  padding: 2.5rem 1.5rem;
  max-width: 480px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  text-align: center;
  animation: slideUp 0.6s ease-out;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.error-animation {
  margin-bottom: 2rem;
}

.number-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.number {
  font-size: 5rem;
  font-weight: 800;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
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

.phone-icon {
  width: 70px;
  height: 120px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  padding: 6px;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
  animation: wobble 3s ease-in-out infinite;
}

@keyframes wobble {
  0%, 100% {
    transform: rotate(0deg);
  }
  25% {
    transform: rotate(-5deg);
  }
  75% {
    transform: rotate(5deg);
  }
}

.phone-screen {
  width: 100%;
  height: 100%;
  background: white;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.sad-face {
  font-size: 2rem;
  animation: blink 3s ease-in-out infinite;
}

@keyframes blink {
  0%, 90%, 100% {
    opacity: 1;
  }
  95% {
    opacity: 0.3;
  }
}

.error-title {
  font-size: 2rem;
  color: #2d3748;
  margin: 0 0 0.75rem 0;
  font-weight: 700;
}

.error-message {
  font-size: 1.125rem;
  color: #4a5568;
  margin: 0 0 1.5rem 0;
  line-height: 1.6;
}

.error-details {
  background: #f7fafc;
  border-radius: 12px;
  padding: 1rem;
  margin-bottom: 1.5rem;
  border-left: 4px solid #667eea;
}

.path-info {
  margin: 0;
  font-size: 0.875rem;
  color: #4a5568;
  word-break: break-all;
}

.path-info strong {
  color: #2d3748;
  display: block;
  margin-bottom: 0.25rem;
}

.actions {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.primary-button,
.secondary-button {
  flex: 1;
  min-width: 120px;
  padding: 0.875rem 1.5rem;
  border: none;
  border-radius: 12px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.primary-button {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.primary-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.5);
}

.primary-button:active {
  transform: translateY(0);
}

.secondary-button {
  background: white;
  color: #667eea;
  border: 2px solid #667eea;
}

.secondary-button:hover {
  background: #f7fafc;
  transform: translateY(-2px);
}

.secondary-button:active {
  transform: translateY(0);
}

.suggestions {
  background: #fef5e7;
  border-radius: 12px;
  padding: 1.25rem;
  border-left: 4px solid #f39c12;
  text-align: left;
}

.suggestions-title {
  font-weight: 600;
  color: #2d3748;
  margin: 0 0 0.75rem 0;
  font-size: 1rem;
}

.suggestions ul {
  margin: 0;
  padding-left: 1.25rem;
  color: #4a5568;
  font-size: 0.875rem;
  line-height: 1.8;
}

.suggestions li {
  margin-bottom: 0.25rem;
}

/* Mobile optimizations */
@media (max-width: 480px) {
  .not-found-content {
    padding: 2rem 1.25rem;
  }
  
  .number {
    font-size: 4rem;
  }
  
  .phone-icon {
    width: 60px;
    height: 100px;
  }
  
  .sad-face {
    font-size: 1.5rem;
  }
  
  .error-title {
    font-size: 1.75rem;
  }
  
  .error-message {
    font-size: 1rem;
  }
  
  .actions {
    flex-direction: column;
  }
  
  .primary-button,
  .secondary-button {
    width: 100%;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .not-found-container {
    background: linear-gradient(135deg, #1a202c 0%, #2d3748 100%);
  }
}
</style>
