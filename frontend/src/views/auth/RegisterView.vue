<template>
  <div class="flex items-center justify-center h-screen">
    <form
      class="bg-slate-800 p-8 rounded-xl border border-slate-700 w-full max-w-md space-y-4"
      @submit.prevent="submit"
    >
      <h1 class="text-xl font-semibold text-center">Créer un compte</h1>

      <div>
        <label class="form-label">Nom</label>
        <input v-model="form.nom" class="form-input" required>
      </div>

      <div>
        <label class="form-label">Prénom</label>
        <input v-model="form.prenom" class="form-input" required>
      </div>

      <div>
        <label class="form-label">Email</label>
        <input v-model="form.email" type="email" class="form-input" required>
      </div>

      <div>
        <label class="form-label">Mot de passe</label>
        <input v-model="form.password" type="password" class="form-input" required>
      </div>

      <button
        class="w-full bg-emerald-500 hover:bg-emerald-400 py-2 rounded text-slate-900 font-bold"
      >
        S'inscrire
      </button>

      <p class="text-center text-sm text-slate-400">
        Déjà un compte ?
        <a href="/login" class="text-emerald-400 hover:underline">Connexion</a>
      </p>
    </form>
  </div>
</template>

<script setup>
import { ref } from "vue";
import api from "../../services/api";
import { useAuthStore } from "../../services/store";
import { useRouter } from "vue-router";
import { useToast } from "../../composables/useToast";

const router = useRouter();
const auth = useAuthStore();
const { showToast } = useToast();

const form = ref({
  nom: "",
  prenom: "",
  email: "",
  password: "",
  ville: "",
  date_naissance: null,
});

const submit = async () => {
  try {
    await api.post("/auth/register", form.value);

    await auth.login(form.value.email, form.value.password);

    showToast("Compte créé !");
    router.push("/recettes");

  } catch (e) {
    showToast("Erreur lors de l'inscription", "error");
  }
};
</script>
