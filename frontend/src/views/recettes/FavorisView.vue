<template>
  <div class="p-6">
    <h1 class="text-xl font-semibold mb-6">Mes recettes favorites</h1>

    <div v-if="favoris.length === 0" class="text-slate-400">
      Vous n'avez pas encore de recettes favorites.
    </div>

    <div class="grid grid-cols-3 gap-6">
      <div
        v-for="r in favoris"
        :key="r.id"
        class="bg-slate-800 rounded border border-slate-700 p-4"
      >
        <h3 class="font-semibold">{{ r.titre }}</h3>
        <button
          class="mt-3 px-3 py-1 bg-red-600 hover:bg-red-500 rounded"
          @click="remove(r.id)"
        >
          Retirer
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import api from "../../services/api";
import { ref, onMounted } from "vue";
import { useToast } from "../../composables/useToast";

const favoris = ref([]);
const { showToast } = useToast();

onMounted(async () => {
  const { data } = await api.get("/preferences");
  favoris.value = data.favoris_recettes ?? [];
});

const remove = async (id) => {
  await api.delete(`/preferences/favori/${id}`);
  favoris.value = favoris.value.filter(f => f.id !== id);
  showToast("Recette retirée des favoris");
};
</script>
