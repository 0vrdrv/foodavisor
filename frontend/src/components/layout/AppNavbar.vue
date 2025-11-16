<template>
  <nav class="flex justify-between items-center px-6 py-3 bg-slate-900 border-b border-slate-800">
    <div class="text-lg font-semibold">FoodAdvisor</div>

    <div class="flex items-center gap-3">
      <button class="bg-blue-600 hover:bg-blue-500 text-white rounded px-4 py-1 mr-4"
        @click="$router.push('/preferences')">
        Profil
      </button>


      <!-- Déconnexion -->
      <button v-if="auth.isAuthenticated()" class="px-4 py-1 rounded bg-red-700 hover:bg-red-600 text-sm"
        @click="logout">
        Déconnexion
      </button>

      <!-- Sinon, bouton connexion -->
      <RouterLink v-else to="/login" class="px-4 py-1 rounded bg-emerald-600 hover:bg-emerald-500 text-sm">
        Connexion
      </RouterLink>
    </div>
  </nav>
</template>

<script setup>
import { useRouter, RouterLink } from "vue-router";
import { useAuthStore } from "../../services/store";

const router = useRouter();
const auth = useAuthStore();

const logout = () => {
  auth.logout();
  router.push("/login");
};
</script>
