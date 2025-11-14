<template>
  <div class="home">
    <h1>Welcome to Mobile App</h1>
    <p>This is the home page.</p>
    <p>Try visiting a non-existent page like <router-link to="/nonexistent">/nonexistent</router-link> to see the 404 page.</p>
  </div>
</template>

<script setup>
</script>

<style scoped>
.home {
  padding: 2rem;
  text-align: center;
}

h1 {
  color: #2c3e50;
  margin-bottom: 1rem;
}

a {
  color: #42b983;
}
</style>
