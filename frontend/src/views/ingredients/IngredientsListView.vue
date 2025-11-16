<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-xl font-semibold text-slate-100">Ingrédients</h1>

      <button
        @click="$router.push({ name: 'ingredient-new' })"
        class="px-4 py-2 rounded bg-emerald-500 hover:bg-emerald-400 text-slate-900"
      >
        + Ajouter un ingrédient
      </button>
    </div>

    <div v-if="loading" class="text-slate-400">Chargement...</div>

    <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div
        v-for="ing in ingredients"
        :key="ing.id"
        class="bg-slate-900 border border-slate-800 rounded-lg p-4"
      >
        <h2 class="font-medium text-slate-100 text-lg">{{ ing.nom }}</h2>

        <p class="text-sm text-slate-400 mt-1">{{ ing.categorie_libelle }}</p>

        <div class="flex gap-2 mt-3">
          <button
            class="flex-1 px-3 py-1 bg-slate-800 hover:bg-slate-700 rounded text-sm"
            @click="$router.push({ name: 'ingredient-detail', params: { id: ing.id } })"
          >
            Détails
          </button>

          <button
            v-if="auth.isAdmin()"
            class="px-3 py-1 bg-blue-600 hover:bg-blue-500 rounded text-sm"
            @click="$router.push({ name: 'ingredient-edit', params: { id: ing.id } })"
          >
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
const ingredients = ref([]);
const loading = ref(true);

const load = async () => {
  const { data } = await api.get("/ingredients"); 
  ingredients.value = data;
  loading.value = false;
};

onMounted(load);
</script>
