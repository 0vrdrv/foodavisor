<template>
  <div class="auth-page">
    <div class="auth-card">
      <h1>{{ isLogin ? 'Connexion' : 'Inscription' }}</h1>

      <!-- Affichage conditionnel des formulaires -->
      <LoginForm v-if="isLogin" />
      <RegisterForm v-else />

      <!-- Bouton de bascule -->
      <p class="toggle-text">
        {{ isLogin ? 'Pas encore de compte ?' : 'Déjà inscrit ?' }}
        <button @click="toggleForm">
          {{ isLogin ? 'Créer un compte' : 'Se connecter' }}
        </button>
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import LoginForm from '../components/LoginForm.vue'
import RegisterForm from '../components/RegisterForm.vue'

const isLogin = ref(true)

const toggleForm = () => {
  isLogin.value = !isLogin.value
}
</script>
