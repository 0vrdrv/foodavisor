<template>
  <form @submit.prevent="registerUser" class="form">
    <input v-model="email" type="email" placeholder="Email" required />
    <input v-model="password" type="password" placeholder="Mot de passe" required />
    <input v-model="nom" placeholder="Nom" required />
    <input v-model="prenom" placeholder="Prénom" required />
    <input v-model="date_naissance" type="date" placeholder="Date de naissance" required />
    <input v-model="ville" placeholder="Ville" required />
    <button type="submit">S'inscrire</button>
    <p class="message">{{ message }}</p>
  </form>
</template>

<script setup>
import { ref } from 'vue'
import axios from 'axios'

const email = ref('')
const password = ref('')
const nom = ref('')
const prenom = ref('')
const date_naissance = ref('')
const ville = ref('')
const message = ref('')

const registerUser = async () => {
  try {
    const res = await axios.post('http://localhost:3000/api/auth/register', {
      email: email.value,
      password: password.value,
      nom: nom.value,
      prenom: prenom.value,
      date_naissance: date_naissance.value,
      ville: ville.value,
    })
    message.value = res.data.message
  } catch (err) {
    message.value = err.response?.data?.message || 'Erreur serveur'
  }
}
</script>
