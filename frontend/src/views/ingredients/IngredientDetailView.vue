<template>
  <div v-if="loading" class="text-slate-400">Chargement...</div>

  <div v-else class="space-y-6">

    <h1 class="text-2xl font-semibold">{{ ing.nom }}</h1>

    <div class="grid md:grid-cols-2 gap-6">

      <!-- Infos générales -->
      <div class="bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-2">
        <p><span class="text-slate-400">Catégorie :</span> {{ ing.categorie_libelle }}</p>
        <p><span class="text-slate-400">Prix estimé :</span> {{ ing.prix_unitaire ?? "N/A" }} €</p>

        <div class="pt-3 text-slate-400 text-sm">
          Valeurs nutritionnelles (pour 100g)
        </div>

        <ul class="text-sm mt-1 space-y-1">
          <li>Kcal : <span class="text-emerald-400">{{ ing.kcal_100g }}</span></li>
          <li>Protéines : {{ ing.prot_100g }} g</li>
          <li>Glucides : {{ ing.gluc_100g }} g</li>
          <li>Lipides : {{ ing.lip_100g }} g</li>
        </ul>
      </div>

      <!-- Allergènes -->
      <div class="bg-slate-900 border border-slate-800 p-4 rounded-xl">
        <h2 class="font-medium mb-2">Allergènes</h2>

        <div v-if="allergenes.length === 0" class="text-slate-500 text-sm">
          Aucun allergène enregistré
        </div>

        <div class="flex flex-wrap gap-2">
          <span
            v-for="al in allergenes"
            :key="al.id"
            class="px-3 py-1 bg-red-600/20 border border-red-500/30 text-red-300 text-sm rounded"
          >
            {{ al.libelle }}
          </span>
        </div>

        <button
          v-if="auth.isAdmin()"
          @click="$router.push({ name: 'ingredient-edit', params: { id: ing.id } })"
          class="mt-4 px-3 py-2 bg-blue-600 hover:bg-blue-500 rounded text-sm"
        >
          Gérer les allergènes
        </button>
      </div>

    </div>

  </div>
</template>

<script setup>
import api from "../../services/api";
import { ref, onMounted } from "vue";
import { useRoute } from "vue-router";
import { useAuthStore } from "../../services/store";

const auth = useAuthStore();
const route = useRoute();

const ing = ref({});
const allergenes = ref([]);
const loading = ref(true);

const load = async () => {
  const id = route.params.id;

  // Ingrédient détaillé avec categorie_libelle
  const { data } = await api.get(`/ingredients/${id}`);
  ing.value = data;

  // Aller chercher les allergènes de l’ingrédient
  const { data: al } = await api.get(`/allergenes/ingredient/${id}`);
  allergenes.value = al;

  loading.value = false;
};

onMounted(load);
</script>
