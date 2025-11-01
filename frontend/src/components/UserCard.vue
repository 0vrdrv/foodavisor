<template>
  <div class="user-card">
    <h2>Mon Profil</h2>

    <div v-if="loading" class="loading">Chargement...</div>

    <div v-else-if="error" class="error">{{ error }}</div>

    <div v-else-if="user" class="user-info">
      <!-- Nom -->
      <div class="info-field">
        <div>
          <strong>Nom:</strong>
          <span v-if="!editingField.includes('nom')">{{ user.nom }}</span>
          <input v-else v-model="tempValues.nom" type="text" />
        </div>
        <button v-if="!editingField.includes('nom')" @click="startEditing('nom')">✏️</button>
        <div v-else>
          <button @click="saveField('nom')" :disabled="saving">✓</button>
          <button @click="cancelEditing('nom')">✗</button>
        </div>
      </div>

      <!-- Prénom -->
      <div class="info-field">
        <div>
          <strong>Prénom:</strong>
          <span v-if="!editingField.includes('prenom')">{{ user.prenom }}</span>
          <input v-else v-model="tempValues.prenom" type="text" />
        </div>
        <button v-if="!editingField.includes('prenom')" @click="startEditing('prenom')">✏️</button>
        <div v-else>
          <button @click="saveField('prenom')" :disabled="saving">✓</button>
          <button @click="cancelEditing('prenom')">✗</button>
        </div>
      </div>

      <!-- Email -->
      <div class="info-field">
        <strong>Email:</strong>
        <span>{{ user.email }}</span>
      </div>

      <!-- Date de Naissance -->
      <div class="info-field">
        <div>
          <strong>Date de Naissance:</strong>
          <span v-if="!editingField.includes('date_naissance')">
            {{ formatDate(user.date_naissance) }}
          </span>
          <input v-else v-model="tempValues.date_naissance" type="date" />
        </div>
        <button
          v-if="!editingField.includes('date_naissance')"
          @click="startEditing('date_naissance')"
        >
          ✏️
        </button>
        <div v-else>
          <button @click="saveField('date_naissance')" :disabled="saving">✓</button>
          <button @click="cancelEditing('date_naissance')">✗</button>
        </div>
      </div>

      <!-- Ville -->
      <div class="info-field">
        <div>
          <strong>Ville:</strong>
          <span v-if="!editingField.includes('ville')">{{ user.ville }}</span>
          <input v-else v-model="tempValues.ville" type="text" />
        </div>
        <button v-if="!editingField.includes('ville')" @click="startEditing('ville')">✏️</button>
        <div v-else>
          <button @click="saveField('ville')" :disabled="saving">✓</button>
          <button @click="cancelEditing('ville')">✗</button>
        </div>
      </div>

      <p v-if="message" :class="['message', messageType]">{{ message }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const user = ref(null)
const loading = ref(true)
const error = ref('')
const message = ref('')
const messageType = ref('')
const saving = ref(false)
const editingField = ref([])
const tempValues = ref({
  nom: '',
  prenom: '',
  date_naissance: '',
  ville: '',
})

const formatDate = (date) => {
  if (!date) return 'N/A'
  return new Date(date).toLocaleDateString('fr-FR')
}

const formatDateForInput = (date) => {
  if (!date) return ''
  const d = new Date(date)
  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

const loadUserProfile = async () => {
  try {
    const token = localStorage.getItem('token')
    if (!token) {
      error.value = 'Aucun token trouvé. Veuillez vous reconnecter.'
      loading.value = false
      return
    }

    const res = await axios.get('http://localhost:3000/api/user/me', {
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
}

onMounted(() => {
  loadUserProfile()
})

const startEditing = (field) => {
  editingField.value.push(field)
  tempValues.value[field] = user.value[field]
  if (field === 'date_naissance') {
    tempValues.value[field] = formatDateForInput(user.value[field])
  }
}

const cancelEditing = (field) => {
  editingField.value = editingField.value.filter((f) => f !== field)
}

const saveField = async (field) => {
  saving.value = true
  message.value = ''

  try {
    const token = localStorage.getItem('token')
    if (!token) {
      message.value = 'Token manquant. Veuillez vous reconnecter.'
      messageType.value = 'error'
      return
    }

    const updateData = {
      [field]: tempValues.value[field],
    }

    const res = await axios.put('http://localhost:3000/api/user/me', updateData, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })

    user.value[field] = tempValues.value[field]
    editingField.value = editingField.value.filter((f) => f !== field)
    message.value = res.data.message || 'Mis à jour avec succès !'
    messageType.value = 'success'

    setTimeout(() => {
      message.value = ''
    }, 3000)
  } catch (err) {
    message.value = err.response?.data?.message || 'Erreur lors de la mise à jour'
    messageType.value = 'error'
  } finally {
    saving.value = false
  }
}
</script>
