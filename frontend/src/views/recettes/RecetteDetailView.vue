<template>
  <div class="px-6 py-4 max-w-4xl" v-if="!loading">
    <!-- Titre -->
    <h1 class="text-2xl font-semibold mb-2">{{ recette.titre }}</h1>

    <p class="text-slate-300 mb-3">{{ recette.description }}</p>

    <p class="text-slate-400 text-sm mb-6">
      Auteur : {{ recette.auteur_prenom }} {{ recette.auteur_nom }}
    </p>

    <!-- Boutons actions -->
    <div class="flex flex-wrap gap-3 mb-8">

      <!-- Réaliser la recette -->
      <button
        class="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded text-slate-900 font-medium"
        @click="realiserRecette"
      >
        🍳 Réaliser cette recette
      </button>

      <!-- Modifier -->
      <button
        v-if="auth.isAdmin() || auth.user?.id === recette.auteur_id"
        class="px-4 py-2 bg-blue-600 hover:bg-blue-500 rounded"
        @click="router.push({ name: 'recette-edit', params: { id: recette.id } })"
      >
        Modifier
      </button>

      <!-- Supprimer -->
      <button
        v-if="auth.isAdmin() || auth.user?.id === recette.auteur_id"
        class="px-4 py-2 bg-red-600 hover:bg-red-500 rounded"
        @click="deleteRecette"
      >
        Supprimer
      </button>
    </div>

    <!-- Ingrédients -->
    <section class="mb-10">
      <h2 class="text-xl font-semibold mb-3">Ingrédients</h2>

      <ul class="space-y-2">
        <li
          v-for="ing in recette.ingredients"
          :key="ing.id"
          class="border border-slate-700 bg-slate-800/40 p-3 rounded"
        >
          <span class="font-semibold">{{ ing.nom }}</span>
          — {{ ing.quantite }} {{ ing.unite_code }}
        </li>
      </ul>
    </section>

    <!-- Étapes -->
    <section class="mb-10">
      <h2 class="text-xl font-semibold mb-3">Étapes</h2>

      <ul class="space-y-3">
        <li
          v-for="et in recette.etapes"
          :key="et.ord"
          class="border border-slate-700 bg-slate-800/40 p-3 rounded"
        >
          <span class="font-semibold">Étape {{ et.ord }} :</span><br />
          {{ et.description }}
        </li>
      </ul>
    </section>

    <!-- Laisser un avis -->
    <section class="mb-12">
      <h2 class="text-xl font-semibold mb-3">Laisser un avis</h2>

      <form
        @submit.prevent="saveAvis"
        class="space-y-4 bg-slate-800 border border-slate-700 p-5 rounded-xl shadow max-w-md"
      >
        <!-- Note -->
        <div>
          <label class="text-sm text-slate-300 mb-1 block">Note</label>
          <select v-model="avis.note" class="form-input" required>
            <option disabled value="">Choisir une note…</option>
            <option v-for="n in [1,2,3,4,5]" :value="n">⭐ {{ n }}</option>
          </select>
        </div>

        <!-- Commentaire -->
        <div>
          <label class="text-sm text-slate-300 mb-1 block">Commentaire</label>
          <textarea
            v-model="avis.commentaire"
            class="form-input h-28"
            required
          ></textarea>
        </div>

        <button
          class="px-4 py-2 bg-emerald-500 hover:bg-emerald-400 rounded text-slate-900 font-semibold"
        >
          {{ avisExiste ? "Modifier mon avis" : "Publier mon avis" }}
        </button>
      </form>
    </section>

    <!-- Avis existants -->
    <section class="mb-10">
      <h2 class="text-xl font-semibold mb-3">Avis des utilisateurs</h2>

      <div
        v-if="recette.avis.length === 0"
        class="text-slate-400"
      >
        Aucun avis pour cette recette.
      </div>

      <ul v-else class="space-y-3">
        <li
          v-for="av in recette.avis"
          :key="av.id"
          class="border border-slate-700 bg-slate-800/40 p-3 rounded"
        >
          <span class="font-semibold">{{ av.prenom }} {{ av.nom }}</span>
          — ⭐ {{ av.note }}/5
          <p class="text-slate-300 mt-1">{{ av.commentaire }}</p>
        </li>
      </ul>
    </section>

  </div>

  <div v-else class="text-slate-400 p-6">Chargement...</div>
</template>

<script setup>
import api from "../../services/api";
import { ref, onMounted, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useAuthStore } from "../../services/store";
import { useToast } from "../../composables/useToast";

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const { showToast } = useToast();

const loading = ref(true);
const recette = ref(null);

const avis = ref({
  note: "",
  commentaire: "",
});

// Vérifie si l'utilisateur a déjà laissé un avis
const avisExiste = computed(() =>
  recette.value?.avis.some(a => a.utilisateur_id === auth.user?.id)
);

const loadRecette = async () => {
  try {
    const { data } = await api.get(`/recettes/${route.params.id}`);
    recette.value = data;

    // Pré-remplir le formulaire si l'avis existe déjà
    const monAvis = recette.value.avis.find(a => a.utilisateur_id === auth.user?.id);
    if (monAvis) {
      avis.value.note = monAvis.note;
      avis.value.commentaire = monAvis.commentaire;
    }
  } catch {
    showToast("Erreur lors du chargement de la recette", "error");
  }
  loading.value = false;
};

// --- Réaliser la recette ---
const realiserRecette = async () => {
  try {
    await api.post("/cuissons", {
      recette_id: recette.value.id,
      personnes: 1,
    });

    showToast("Recette réalisée ! Stock mis à jour 👍");
    await loadRecette();
  } catch (e) {
    console.error(e);
    showToast("Impossible de réaliser la recette", "error");
  }
};

// --- Ajouter / Modifier un avis ---
const saveAvis = async () => {
  try {
    await api.post(`/avis/${recette.value.id}`, avis.value);
    showToast(avisExiste.value ? "Avis modifié !" : "Avis ajouté !");
    await loadRecette();
  } catch {
    showToast("Erreur lors de l'envoi de l'avis", "error");
  }
};

// --- Supprimer une recette ---
const deleteRecette = async () => {
  if (!confirm("Supprimer cette recette ?")) return;

  try {
    await api.delete(`/recettes/${recette.value.id}`);
    showToast("Recette supprimée !");
    router.push("/recettes");
  } catch {
    showToast("Erreur lors de la suppression", "error");
  }
};

onMounted(loadRecette);
</script>

<style scoped>
.form-input {
  @apply w-full bg-slate-900 border border-slate-700 rounded px-3 py-2 text-slate-100 text-sm;
}
</style>
