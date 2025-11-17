<template>
  <div class="px-6 py-4 max-w-5xl mx-auto">
    <h1 class="text-2xl font-semibold mb-6">Recettes recommandées</h1>

    <!-- -------------------- -->
    <!-- Filtres -->
    <!-- -------------------- -->
    <div class="flex flex-wrap items-center gap-4 mb-6">

      <!-- Tri -->
      <select v-model="order" class="form-input w-52" @change="load">
        <option value="recent">📅 Plus récentes</option>
        <option value="note">⭐ Meilleures notes</option>
        <option value="cout">💰 Moins coûteuses</option>
      </select>

      <!-- Stock only -->
      <label class="flex items-center gap-2">
        <input type="checkbox" v-model="stockOnly" @change="load" />
        <span>Seulement réalisables avec mon stock</span>
      </label>

    </div>

    <!-- Chargement -->
    <div v-if="loading" class="text-slate-400">Chargement...</div>

    <!-- Liste -->
    <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div
        v-for="r in recommandations"
        :key="r.id"
        class="bg-slate-900 border border-slate-800 p-4 rounded-xl flex flex-col"
      >
        <div class="flex justify-between items-start">
          <h2 class="text-lg font-semibold">{{ r.titre }}</h2>

          <!-- Favori -->
          <button
            v-if="auth.isAuthenticated()"
            @click="toggleFavorite(r.id)"
            class="text-2xl"
          >
            <span v-if="favRecipes.includes(r.id)" class="text-yellow-400">★</span>
            <span v-else class="text-slate-500 hover:text-yellow-400">☆</span>
          </button>
        </div>

        <p class="text-sm text-slate-400 mt-1 line-clamp-3">{{ r.description }}</p>

        <p class="text-xs text-slate-500 mt-2">
          Auteur : {{ r.auteur_prenom }} {{ r.auteur_nom }}
        </p>

        <div class="mt-3 text-sm text-slate-300 flex flex-col gap-1">
          <span>⭐ Note : {{ r.note_moyenne ?? "Aucune" }}</span>
          <span>💰 Coût : {{ r.cout_cache ?? "N/C" }}</span>
        </div>

        <button
          class="mt-4 px-3 py-1 bg-slate-800 hover:bg-slate-700 rounded text-sm"
          @click="$router.push({ name: 'recette-detail', params: { id: r.id } })"
        >
          Voir la recette
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import api from "../../services/api";
import { ref, onMounted } from "vue";
import { useAuthStore } from "../../services/store";
import { favRecipes, toggleFavorite } from "../../services/preferences";

const auth = useAuthStore();

const recommandations = ref([]);
const loading = ref(true);

const order = ref("recent");
const stockOnly = ref(false);

const load = async () => {
  loading.value = true;

  const { data } = await api.get("/recommandations", {
    params: {
      order: order.value,
      stock_only: stockOnly.value ? 1 : 0,
    },
  });

  recommandations.value = data;
  loading.value = false;
};

onMounted(load);
</script>

<style scoped>
.form-input {
  @apply w-full bg-slate-900 border border-slate-700 rounded px-3 py-2 text-slate-100;
}
</style>
