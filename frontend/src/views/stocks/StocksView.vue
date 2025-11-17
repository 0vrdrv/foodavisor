<template>
  <div class="px-6 py-4">

    <!-- Titre + bouton ajout -->
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-xl font-semibold">Mon stock</h1>

      <button
        @click="showAddModal = true"
        class="px-4 py-2 bg-emerald-500 hover:bg-emerald-400 text-slate-900 rounded"
      >
        + Ajouter un ingrédient
      </button>
    </div>

    <!-- Barre de recherche -->
    <input
      v-model="search"
      type="text"
      placeholder="Rechercher un ingrédient..."
      class="form-input w-full max-w-md mb-6"
    />

    <!-- Onglets -->
    <div class="flex gap-4 mb-6">
      <button
        :class="tab === 'dispo' ? activeTab : tabBtn"
        @click="tab = 'dispo'"
      >🟢 Disponibles</button>

      <button
        :class="tab === 'rupture' ? activeTab : tabBtn"
        @click="tab = 'rupture'"
      >🔴 À racheter</button>
    </div>

    <!-- Chargement -->
    <div v-if="loading" class="text-slate-400">Chargement...</div>

    <!-- Liste -->
    <div v-else class="space-y-3">

      <!-- INGREDIENTS DISPONIBLES -->
      <div
        v-if="tab === 'dispo'"
        v-for="s in filteredDispo"
        :key="s.ingredient_id"
        class="p-4 border border-slate-800 bg-slate-900 rounded-xl flex justify-between items-center"
      >
        <div @click="openDetail(s.ingredient_id)" class="cursor-pointer">
          <p class="font-medium">{{ s.ingredient }}</p>
          <p class="text-sm text-slate-400">{{ s.quantite }} {{ s.unite_code }}</p>
          <p v-if="s.date_peremption" class="text-xs text-slate-500 mt-1">
            🗓️ Péremption : {{ formatDate(s.date_peremption) }}
          </p>
        </div>

        <!-- Modification rapide -->
        <QuickUpdate :item="s" @updated="refresh" />
      </div>

      <!-- INGREDIENTS À RACHETER -->
      <div
        v-if="tab === 'rupture'"
        v-for="s in filteredRupture"
        :key="s.ingredient_id"
        class="p-4 border border-slate-800 bg-red-900/40 rounded-xl flex justify-between items-center"
      >
        <div @click="openDetail(s.ingredient_id)" class="cursor-pointer">
          <p class="font-medium">{{ s.ingredient }}</p>
          <p class="text-sm text-red-300">Rupture de stock</p>
        </div>

        <!-- Bouton ajouter -->
        <button
          @click="openAdd(s.ingredient_id)"
          class="px-3 py-1 bg-emerald-500 hover:bg-emerald-400 text-slate-900 rounded text-sm"
        >
          ➕ Ajouter
        </button>
      </div>

    </div>

    <!-- Modal "Ajouter un ingrédient" -->
    <AddStockModal
      v-if="showAddModal"
      :ingredientId="modalIngredient"
      @close="closeAdd"
      @saved="refresh"
    />

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from "vue";
import api from "../../services/api";
import AddStockModal from "../../components/stocks/AddStockModal.vue";
import QuickUpdate from "../../components/stocks/QuickUpdate.vue";

const stock = ref([]);
const loading = ref(true);
const search = ref("");
const tab = ref("dispo"); // dispo | rupture

const showAddModal = ref(false);
const modalIngredient = ref(null);

// Charger stock
const loadStock = async () => {
  const { data } = await api.get("/stocks");
  stock.value = data;
  loading.value = false;
};

const refresh = async () => {
  await loadStock();
  showAddModal.value = false;
};

// Rechercher
const searchFilter = (list) =>
  list.filter((s) =>
    s.ingredient.toLowerCase().includes(search.value.toLowerCase())
  );

// Séparer dispo / rupture
const filteredDispo = computed(() =>
  searchFilter(stock.value.filter((s) => s.quantite > 0))
);

const filteredRupture = computed(() =>
  searchFilter(stock.value.filter((s) => s.quantite <= 0))
);

const openDetail = (id) => {
  window.location.href = `/stocks/${id}`;
};

const openAdd = (id) => {
  modalIngredient.value = id;
  showAddModal.value = true;
};

const closeAdd = () => {
  showAddModal.value = false;
  modalIngredient.value = null;
};

const formatDate = (d) => new Date(d).toLocaleDateString("fr-FR");

const tabBtn =
  "px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded text-slate-300";
const activeTab =
  "px-4 py-2 bg-emerald-600 text-slate-900 rounded font-semibold";

onMounted(loadStock);
</script>

<style scoped>
.form-input {
  @apply bg-slate-900 border border-slate-700 rounded px-3 py-2 text-slate-100;
}
</style>
