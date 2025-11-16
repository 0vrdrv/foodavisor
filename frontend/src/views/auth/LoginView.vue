<template>
  <div class="flex items-center justify-center h-screen">
    <form
      class="bg-slate-800 p-8 rounded-xl border border-slate-700 w-full max-w-md space-y-4"
      @submit.prevent="submit"
    >
      <h1 class="text-xl font-semibold text-center">Connexion</h1>

      <div>
        <label class="form-label">Email</label>
        <input v-model="email" type="email" class="form-input" required>
      </div>

      <div>
        <label class="form-label">Mot de passe</label>
        <input v-model="password" type="password" class="form-input" required>
      </div>

      <button
        class="w-full bg-emerald-500 hover:bg-emerald-400 py-2 rounded text-slate-900 font-bold"
      >
        Se connecter
      </button>

      <p class="text-center text-sm text-slate-400">
        Pas encore de compte ?
        <a href="/register" class="text-emerald-400 hover:underline">Créer un compte</a>
      </p>
    </form>
  </div>
</template>

<script setup>
import { ref } from "vue";
import { useAuthStore } from "../../services/store";
import { useRouter } from "vue-router";
import { useToast } from "../../composables/useToast";

const email = ref("");
const password = ref("");

const auth = useAuthStore();
const router = useRouter();
const { showToast } = useToast();

const submit = async () => {
  try {
    await auth.login(email.value, password.value);
    showToast("Connexion réussie !");
    router.push("/recettes");
  } catch (e) {
    showToast("Identifiants incorrects", "error");
  }
};
</script>

<style scoped>
.form-label { @apply block text-sm text-slate-300 mb-1; }
.form-input { @apply w-full bg-slate-900 border border-slate-700 rounded px-3 py-2 text-slate-100; }
</style>
