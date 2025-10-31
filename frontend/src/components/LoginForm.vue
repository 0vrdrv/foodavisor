<template>
  <form @submit.prevent="loginUser" class="form">
    <h2>Connexion</h2>

    <input v-model="email" type="email" placeholder="Email" required autocomplete="email" />

    <input
      v-model="password"
      type="password"
      placeholder="Mot de passe"
      required
      autocomplete="current-password"
    />

    <button type="submit" :disabled="loading">
      {{ loading ? 'Connexion...' : 'Se connecter' }}
    </button>

    <p v-if="message" class="message">{{ message }}</p>
  </form>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'

const router = useRouter()
const email = ref('')
const password = ref('')

const loading = ref(false)
const message = ref('')

const loginUser = async () => {
  loading.value = true
  message.value = ''

  try {
    const res = await axios.post('http://localhost:3000/api/auth/login', {
      email: email.value,
      password: password.value,
    })

    message.value = res.data.message || 'Connexion réussie !'

    if (res.status === 200) {
      router.push('/')
    }
  } catch (err) {
    message.value = err.response?.data?.message || 'Erreur serveur'
  } finally {
    loading.value = false
  }
}
</script>
