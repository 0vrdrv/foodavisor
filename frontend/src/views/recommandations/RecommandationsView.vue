<template>
  <div>
    <h1 class="text-xl font-semibold mb-4">Recommandations</h1>

    <div class="flex gap-3 items-center mb-4 text-sm">
      <label class="flex items-center gap-2">
        <input type="checkbox" v-model="stockOnly" class="rounded border-slate-600 bg-slate-800" />
        <span>Uniquement réalisables avec mon stock</span>
      </label>

      <select v-model="trier" class="bg-slate-900 border border-slate-700 rounded px-2 py-1 text-sm">
        <option value="note">Trier par note</option>
        <option value="cout">Trier par coût</option>
      </select>

      <button
        @click="load"
        class="px-3 py-1 rounded bg-slate-800 border border-slate-700 hover:bg-slate-700 text-sm"
      >
        Rafraîchir
      </button>
    </div>

    <div v-if="loading" class="text-sm text-slate-400">Chargement...</div>

    <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="r in recommandations" :key="r.id"
           class="bg-slate-900 border border-slate-800 rounded-lg p-4 flex flex-col justify-between">
        <div>
          <h2 class="font-medium text-slate-50 mb-1">{{ r.titre }}</h2>
          <p class="text-xs text-slate-400 mb-2 line-clamp-2">{{ r.description }}</p>
        </div>
        <div class="flex items-center justify-between text-xs text-slate-400 mt-3">
          <span>Note : <span class="text-emerald-400">{{ r.note_moy ?? '–' }}</span></span>
          <span>Coût : <span class="text-emerald-400">{{ r.cout_estime ?? 'N/A' }} €</span></span>
        </div>
        <button
          class="mt-3 text-xs bg-emerald-500 hover:bg-emerald-400 text-slate-950 rounded px-3 py-1"
          @click="$router.push({ name: 'recette-detail', params: { id: r.id } })"
        >
          Voir la recette
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import api from "../../services/api";

const recommandations = ref([]);
const loading = ref(false);
const stockOnly = ref(false);
const trier = ref("note");

const load = async () => {
  loading.value = true;
  try {
    const { data } = await api.get("/recommandations", {
      params: {
        stock_only: stockOnly.value,
        trier: trier.value,
        limite: 12,
      },
    });
    recommandations.value = data;
  } finally {
    loading.value = false;
  }
};

onMounted(load);
</script>
