<template>
  <div class="px-6 py-4 max-w-4xl mx-auto" v-if="!loading">

    <!-- Titre + auteur -->
    <h1 class="text-3xl font-bold mb-1 text-slate-100 flex items-center gap-3">
      {{ recette.titre }}

      <!-- Badge réalisée -->
      <span v-if="aDejaRealisee" class="bg-emerald-600 text-slate-900 text-xs px-2 py-1 rounded-lg font-semibold">
        ✔ Déjà réalisée
      </span>
    </h1>

    <p class="text-slate-300 mb-3">{{ recette.description }}</p>

    <p class="text-slate-400 text-sm mb-6">
      Auteur : {{ recette.auteur_prenom }} {{ recette.auteur_nom }}
    </p>

    <!-- Boutons -->
    <div class="flex flex-wrap gap-3 mb-10">
      <button
        class="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded text-slate-900 font-medium"
        @click="realiserRecette"
      >
        🍳 Réaliser cette recette
      </button>

      <button
        v-if="auth.isAdmin() || auth.user?.id === recette.auteur_id"
        class="px-4 py-2 bg-blue-600 hover:bg-blue-500 rounded"
        @click="router.push({ name: 'recette-edit', params: { id: recette.id } })"
      >
        Modifier
      </button>

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
          class="border border-slate-700 bg-slate-800 p-3 rounded"
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
          class="border border-slate-700 bg-slate-800 p-3 rounded"
        >
          <span class="font-semibold">Étape {{ et.ord }} :</span><br />
          {{ et.description }}
        </li>
      </ul>
    </section>

    <!-- Avis -->
    <section class="mb-12">
      <h2 class="text-xl font-semibold mb-4">Laisser un avis</h2>

      <!-- BLOQUAGE SI NON REALISE -->
      <div
        v-if="!aDejaRealisee"
        class="bg-red-600/20 border border-red-600 text-red-400 p-4 rounded-lg mb-6"
      >
        ⚠ Vous devez d'abord <strong>réaliser cette recette</strong> avant de pouvoir laisser un avis.
      </div>

      <!-- Formulaire avis -->
      <form
        v-if="aDejaRealisee"
        @submit.prevent="saveAvis"
        class="space-y-4 bg-slate-800 border border-slate-700 p-5 rounded-xl shadow max-w-md"
      >
        <div>
          <label class="text-sm text-slate-300 mb-1 block">Note</label>
          <select v-model="avis.note" class="form-input" required>
            <option disabled value="">Choisir une note…</option>
            <option v-for="n in [1, 2, 3, 4, 5]" :value="n">⭐ {{ n }}</option>
          </select>
        </div>

        <div>
          <label class="text-sm text-slate-300 mb-1 block">Commentaire</label>
          <textarea v-model="avis.commentaire" class="form-input h-28" required></textarea>
        </div>

        <div class="flex gap-3">
          <button class="px-4 py-2 bg-emerald-500 hover:bg-emerald-400 rounded text-slate-900 font-semibold">
            {{ avisExiste ? "Modifier mon avis" : "Publier mon avis" }}
          </button>

          <button
            v-if="avisExiste"
            type="button"
            class="px-4 py-2 bg-red-600 hover:bg-red-500 rounded text-white"
            @click="deleteMyAvis"
          >
            Supprimer mon avis
          </button>
        </div>
      </form>
    </section>

    <!-- Liste des avis -->
    <section class="mb-10">
      <h2 class="text-xl font-semibold mb-3">Avis des utilisateurs</h2>

      <div v-if="recette.avis.length === 0" class="text-slate-400">
        Aucun avis pour cette recette.
      </div>

      <ul v-else class="space-y-3">
        <li
          v-for="av in recette.avis"
          :key="av.id"
          class="border border-slate-700 bg-slate-800 p-3 rounded relative"
        >
          <div class="flex justify-between">
            <div>
              <span class="font-semibold">{{ av.prenom }} {{ av.nom }}</span>
              — ⭐ {{ av.note }}/5
            </div>

            <!-- Options pour MON avis (nom + prénom) -->
            <div
              v-if="av.nom === auth.user?.nom && av.prenom === auth.user?.prenom"
              class="flex gap-2"
            >
              <button class="text-blue-400 hover:text-blue-300 text-sm" @click="editAvis(av)">
                📝 Modifier
              </button>

              <button class="text-red-400 hover:text-red-300 text-sm" @click="deleteMyAvis">
                🗑 Supprimer
              </button>
            </div>
          </div>

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
import { showToast } from "../../services/toast";

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();

const loading = ref(true);
const recette = ref(null);

// avis dans le formulaire
const avis = ref({ note: "", commentaire: "" });
// mon avis (celui de l'utilisateur connecté)
const monAvis = ref(null);

/**
 * Est-ce que l'utilisateur connecté a déjà laissé un avis ?
 * -> basé sur nom + prénom (comme ce qui fonctionne chez toi)
 */
const avisExiste = computed(() =>
  recette.value?.avis.some(
    (a) => a.nom === auth.user?.nom && a.prenom === auth.user?.prenom
  )
);

// A-t-il réalisé la recette ?
const aDejaRealisee = ref(false);

const checkHistorique = async () => {
  try {
    const { data } = await api.get("/cuissons");
    aDejaRealisee.value = data.some(
      (c) => c.recette_id == route.params.id || c.utilisateur_id == auth.user?.id
    );
  } catch {
    aDejaRealisee.value = false;
  }
};

const loadRecette = async () => {
  try {
    const { data } = await api.get(`/recettes/${route.params.id}`);
    recette.value = data;

    // Trouver MON avis dans la liste (nom + prénom)
    monAvis.value =
      data.avis.find(
        (a) => a.nom === auth.user?.nom && a.prenom === auth.user?.prenom
      ) || null;

    if (monAvis.value) {
      avis.value.note = monAvis.value.note;
      avis.value.commentaire = monAvis.value.commentaire;
    } else {
      avis.value = { note: "", commentaire: "" };
    }

    await checkHistorique();
  } catch {
    showToast("Erreur chargement recette", "error");
  }
  loading.value = false;

  console.log("Avis reçus :", recette.value.avis);
  console.log("Utilisateur connecté :", auth.user);
};

// ► Réaliser recette
const realiserRecette = async () => {
  try {
    await api.post("/cuissons", {
      recette_id: recette.value.id,
      personnes: 1,
    });

    showToast("Recette réalisée ✔");
    await loadRecette();
  } catch {
    showToast("Erreur lors de la réalisation", "error");
  }
};

// ► Ajouter / Modifier un avis
const saveAvis = async () => {
  try {
    if (avisExiste.value) {
      // mon avis existe déjà → PUT
      await api.put(`/avis/recette/${recette.value.id}`, avis.value);
      showToast("Avis modifié !");
    } else {
      // pas encore d'avis → POST
      await api.post(`/avis/recette/${recette.value.id}`, avis.value);
      showToast("Avis ajouté !");
    }

    await loadRecette();
  } catch (e) {
    console.error(e);
    showToast("Erreur lors de l'envoi de l'avis", "error");
  }
};

// ► Supprimer recette
const deleteRecette = async () => {
  if (!confirm("Supprimer cette recette ?")) return;

  try {
    await api.delete(`/recettes/${recette.value.id}`);
    showToast("Recette supprimée !");
    router.push("/recettes");
  } catch {
    showToast("Erreur suppression", "error");
  }
};

// ► Mettre le formulaire en mode édition avec mon avis
const editAvis = (avisCourant) => {
  monAvis.value = avisCourant;
  avis.value.note = avisCourant.note;
  avis.value.commentaire = avisCourant.commentaire;
  showToast("Mode modification activé");
};

// ► Supprimer mon avis
const deleteMyAvis = async () => {
  if (!confirm("Supprimer votre avis ?")) return;
  try {
    await api.delete(`/avis/recette/${recette.value.id}`);
    showToast("Avis supprimé !");
    monAvis.value = null;
    avis.value = { note: "", commentaire: "" };
    await loadRecette();
  } catch {
    showToast("Erreur lors de la suppression de l'avis", "error");
  }
};

onMounted(loadRecette);
</script>

<style scoped>
.form-input {
  @apply w-full bg-slate-900 border border-slate-700 rounded px-3 py-2 text-slate-100 text-sm;
}
</style>
