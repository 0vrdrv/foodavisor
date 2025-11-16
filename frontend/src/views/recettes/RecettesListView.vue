<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-xl font-semibold">Recettes</h1>

      <button class="px-4 py-2 bg-emerald-500 hover:bg-emerald-400 rounded text-slate-900"
        @click="$router.push({ name: 'recette-new' })">
        + Nouvelle recette
      </button>
    </div>

    <div v-if="loading" class="text-slate-400">Chargement...</div>

    <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="r in recettes" :key="r.id" class="bg-slate-900 border border-slate-800 p-4 rounded-xl">
        <h2 class="text-lg font-semibold">{{ r.titre }}</h2>

        <p class="text-sm text-slate-400 mt-1">{{ r.description }}</p>

        <p class="text-xs text-slate-500 mt-2">
          Auteur : {{ r.auteur_prenom }} {{ r.auteur_nom }}
        </p>

        <div class="flex gap-2 mt-4">
          <button class="flex-1 bg-slate-800 hover:bg-slate-700 px-3 py-1 rounded"
            @click="$router.push({ name: 'recette-detail', params: { id: r.id } })">
            Voir
          </button>

          <button v-if="auth.isAdmin() || auth.user?.id === r.auteur_id"
            class="bg-blue-600 hover:bg-blue-500 px-3 py-1 rounded"
            @click="$router.push({ name: 'recette-edit', params: { id: r.id } })">
            Modifier
          </button>

        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import api from "../../services/api";
import { ref, onMounted } from "vue";
import { useAuthStore } from "../../services/store";

const auth = useAuthStore();
const recettes = ref([]);
const loading = ref(true);

const load = async () => {
  try {
    const { data } = await api.get("/recettes");
    recettes.value = data;
  } catch (e) {
    console.error("Erreur /recettes :", e);
  }
  loading.value = false;
};

onMounted(load);
</script>
