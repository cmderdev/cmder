<template>
  <div class="dashboard">
    <header class="dashboard-header">
      <h1>Admin Panel Dashboard</h1>
    </header>
    <main class="dashboard-content">
      <p>Welcome to the admin panel.</p>
      <p>Try visiting a non-existent page like <router-link to="/admin/nonexistent">/admin/nonexistent</router-link> to see the 404 page.</p>
    </main>
  </div>
</template>

<script setup>
</script>

<style scoped>
.dashboard {
  min-height: 100vh;
  background: #f5f5f5;
}

.dashboard-header {
  background: #2c3e50;
  color: white;
  padding: 1.5rem 2rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.dashboard-header h1 {
  margin: 0;
  font-size: 1.5rem;
}

.dashboard-content {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

a {
  color: #3498db;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}
</style>
