<template>
  <div class="min-h-screen flex items-center justify-center bg-slate-900 px-4">
    <div class="w-full max-w-md bg-white shadow-xl rounded-xl p-8">
      <h1 class="text-2xl font-bold text-slate-800 mb-6 text-center">
        Créer un compte
      </h1>

      <form @submit.prevent="register" class="space-y-4">
        <!-- Nom -->
        <div>
          <label class="label">Nom</label>
          <input v-model="nom" type="text" class="input" required />
        </div>

        <!-- Prénom -->
        <div>
          <label class="label">Prénom</label>
          <input v-model="prenom" type="text" class="input" required />
        </div>

        <!-- Email -->
        <div>
          <label class="label">Email</label>
          <input v-model="email" type="email" class="input" required />
        </div>

        <!-- Mot de passe -->
        <div>
          <label class="label">Mot de passe</label>
          <input v-model="password" type="password" class="input" required />
        </div>

        <!-- Sexe -->
        <div>
          <label class="label">Sexe</label>
          <select v-model="sexe" class="input">
            <option value="H">Homme</option>
            <option value="F">Femme</option>
          </select>
        </div>

        <!-- Ville -->
        <div>
          <label class="label">Ville</label>
          <input v-model="ville" type="text" class="input" />
        </div>

        <!-- Date de naissance -->
        <div>
          <label class="label">Date de naissance</label>
          <input v-model="date_naissance" type="date" class="input" />
        </div>

        <!-- Bouton -->
        <button class="btn-primary w-full mt-6">
          Créer mon compte
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";
import api from "../../services/api";
import { useAuthStore } from "../../services/store";
import { useRouter } from "vue-router";

const store = useAuthStore();
const router = useRouter();

const nom = ref("");
const prenom = ref("");
const email = ref("");
const password = ref("");
const sexe = ref("ND");
const ville = ref("");
const date_naissance = ref("");

const register = async () => {
  try {
    const payload = {
      nom: nom.value,
      prenom: prenom.value,
      email: email.value,
      password: password.value,
      sexe: sexe.value,
      ville: ville.value,
      date_naissance: date_naissance.value || null,
    };

    const { data } = await api.post("/auth/register", payload);

    // data = { token, user }
    store.setAuth(data.token, data.user);

    router.push("/");
  } catch (err) {
    console.error(err);
    alert(err.response?.data?.message || "Erreur à l'inscription");
  }
};
</script>

<style scoped>
.label {
  @apply block text-sm font-medium text-slate-700 mb-1;
}

.input {
  @apply w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 
         focus:ring-emerald-500 focus:border-emerald-500 outline-none
         bg-white text-slate-800;
}

.btn-primary {
  @apply bg-emerald-600 hover:bg-emerald-700 text-white font-semibold
         py-2.5 rounded-lg duration-150;
}
</style>
