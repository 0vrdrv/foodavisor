<template>
  <div>
    <h2>Carte Utilisateur</h2>

    <div v-if="loading" class="loading">Chargement...</div>

    <div v-else-if="error" class="error">{{ error }}</div>

    <div v-else-if="user" class="user-info">
      <p><strong>Nom:</strong> {{ user.nom }}</p>
      <p><strong>Prénom:</strong> {{ user.prenom }}</p>
      <p><strong>Email:</strong> {{ user.email }}</p>
      <p><strong>Date de Naissance:</strong> {{ formatDate(user.date_naissance) }}</p>
      <p><strong>Ville:</strong> {{ user.ville }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const user = ref(null)
const loading = ref(true)
const error = ref('')

const formatDate = (date) => {
  if (!date) return 'N/A'
  return new Date(date).toLocaleDateString('fr-FR')
}

onMounted(async () => {
  try {
    const token = localStorage.getItem('token')
    if (!token) {
      error.value = 'Aucun token trouvé. Veuillez vous reconnecter.'
      loading.value = false
      return
    }

    const res = await axios.get('http://localhost:3000/api/user/profile', {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })

    user.value = res.data
    error.value = ''
  } catch (err) {
    error.value = err.response?.data?.message || 'Erreur de récupération du profil'
    user.value = null
  } finally {
    loading.value = false
  }
})
</script>
