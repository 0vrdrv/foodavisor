<template>
  <div class="p-6">
    <h1 class="text-xl font-semibold mb-6">Mes Statistiques</h1>

    <div class="grid grid-cols-2 gap-6">

      <div class="p-4 bg-slate-800 rounded border border-slate-700">
        <h2 class="font-semibold mb-2">Recettes réalisées</h2>
        <p class="text-2xl">{{ stats.nb_cuissons }}</p>
      </div>

      <div class="p-4 bg-slate-800 rounded border border-slate-700">
        <h2 class="font-semibold mb-2">Avis déposés</h2>
        <p class="text-2xl">{{ stats.nb_avis }}</p>
      </div>

    </div>
  </div>
</template>

<script setup>
import api from "../../services/api";
import { ref, onMounted } from "vue";

const stats = ref({});

onMounted(async () => {
  const { data } = await api.get("/stats/user");
  stats.value = data;
});
</script>
