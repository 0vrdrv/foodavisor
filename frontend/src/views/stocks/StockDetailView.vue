<template>
  <div class="px-6 py-4 max-w-3xl mx-auto">

    <!-- Retour -->
    <button @click="$router.push('/stocks')" class="text-slate-400 hover:text-slate-200 mb-4">
      ← Retour au stock
    </button>

    <!-- Carte info -->
    <div class="bg-slate-900 border border-slate-700 rounded-xl p-6 mb-10">
      <h1 class="text-3xl font-bold mb-2">{{ item.ingredient }}</h1>

      <p class="text-slate-300 text-lg font-semibold">
        Quantité :
        <span class="text-emerald-400">{{ item.quantite }}</span>
        {{ item.unite_code }}
      </p>

      <p class="mt-2 text-sm text-slate-400">
        <span v-if="item.date_peremption">
          🗓️ Péremption : {{ formatDate(item.date_peremption) }}
        </span>
        <span v-else>Aucune date de péremption enregistrée.</span>
      </p>

      <div class="mt-4 flex gap-3">
        <button
          @click="update(-1)"
          class="px-3 py-2 bg-red-600 hover:bg-red-500 rounded text-white"
        >
          Retirer 1
        </button>

        <button
          @click="update(+1)"
          class="px-3 py-2 bg-emerald-500 hover:bg-emerald-400 rounded text-slate-900"
        >
          Ajouter 1
        </button>
      </div>
    </div>

    <!-- Historique -->
    <h2 class="text-xl font-semibold mb-3">Historique des mouvements</h2>

    <div v-if="item.mouvements.length === 0" class="text-slate-500">
      Aucun mouvement enregistré.
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="m in item.mouvements"
        :key="m.id"
        class="p-4 bg-slate-900 border border-slate-700 rounded-lg"
      >
        <p class="font-semibold">
          {{ m.raison }} —
          <span :class="m.delta < 0 ? 'text-red-400' : 'text-emerald-400'">
            {{ m.delta }} {{ m.unite_code }}
          </span>
        </p>

        <p class="text-sm text-slate-500">
          {{ formatDateTime(m.ts) }}
        </p>
      </div>
    </div>

  </div>
</template>

<script setup>
import api from "../../services/api";
import { ref, onMounted } from "vue";
import { showToast } from "../../services/toast";
import { useRoute } from "vue-router";

const route = useRoute();
const item = ref(null);

const load = async () => {
  const { data } = await api.get(`/stocks/${route.params.id}`);
  item.value = data;
};

const update = async (delta) => {
  try {
    await api.post("/stocks/mvt", {
      ingredient_id: item.value.ingredient_id,
      delta,
      unite_code: item.value.unite_code,
      raison: delta > 0 ? "ajout" : "retrait"
    });

    showToast("Stock mis à jour !");
    await load();
  } catch (e) {
    console.error(e);
    showToast("Erreur modification stock", "error");
  }
};

const formatDate = (d) => new Date(d).toLocaleDateString("fr-FR");
const formatDateTime = (d) => new Date(d).toLocaleString("fr-FR");

onMounted(load);
</script>
