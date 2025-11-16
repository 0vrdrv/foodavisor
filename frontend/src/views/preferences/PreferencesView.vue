<template>
  <div class="max-w-5xl mx-auto p-6">
    <h1 class="text-3xl font-bold mb-10 text-slate-100 text-center">
      Préférences utilisateur
    </h1>

    <!-- ====== INFORMATIONS GÉNÉRALES ====== -->
    <section class="card">
      <h2 class="title">Informations générales</h2>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div>
          <label class="label">Ville</label>
          <input v-model="general.ville" class="input" />
        </div>

        <div>
          <label class="label">Date de naissance</label>
          <input v-model="general.date_naissance" type="date" class="input" />
        </div>

        <div>
          <label class="label">Sexe</label>
          <select v-model="general.sexe" class="input">
            <option value="H">Homme</option>
            <option value="F">Femme</option>
            <option value="NB">Non-binaire</option>
            <option value="ND">Ne souhaite pas dire</option>
          </select>
        </div>
      </div>

      <button class="btn-primary mt-6 w-full md:w-auto" @click="saveGeneral">
        Enregistrer
      </button>
    </section>

    <!-- ====== ALLERGIES ====== -->
    <section class="card">
      <h2 class="title">Allergies</h2>

      <ul class="list">
        <li v-for="a in allergies" :key="a.id" class="list-item">
          {{ a.libelle }}
          <button class="btn-danger" @click="removeAllergie(a.id)">✕</button>
        </li>
      </ul>

      <div class="flex gap-2 mt-4">
        <select v-model="newAllergie" class="input flex-1">
          <option value="" disabled>Ajouter une allergie...</option>
          <option v-for="a in allAllergenes" :value="a.id" :key="a.id">
            {{ a.libelle }}
          </option>
        </select>
        <button class="btn-primary" @click="addAllergie">Ajouter</button>
      </div>
    </section>

    <!-- ====== RÉGIMES ====== -->
    <section class="card">
      <h2 class="title">Régimes alimentaires</h2>

      <ul class="list">
        <li v-for="r in regimes" :key="r.id" class="list-item">
          {{ r.libelle }}
          <button class="btn-danger" @click="removeRegime(r.id)">✕</button>
        </li>
      </ul>

      <div class="flex gap-2 mt-4">
        <select v-model="newRegime" class="input flex-1">
          <option value="" disabled>Ajouter un régime...</option>
          <option v-for="r in allRegimes" :value="r.id" :key="r.id">
            {{ r.libelle }}
          </option>
        </select>

        <button class="btn-primary" @click="addRegime">Ajouter</button>
      </div>
    </section>

    <!-- ====== ALIMENTS EXCLUS ====== -->
    <section class="card">
      <h2 class="title">Aliments exclus</h2>

      <ul class="list">
        <li v-for="i in exclusions" :key="i.id" class="list-item">
          {{ i.nom }}
          <button class="btn-danger" @click="removeExclusion(i.id)">✕</button>
        </li>
      </ul>

      <div class="flex gap-2 mt-4">
        <select v-model="newExclusion" class="input flex-1">
          <option value="" disabled>Ajouter un aliment...</option>
          <option v-for="i in allIngredients" :value="i.id" :key="i.id">
            {{ i.nom }}
          </option>
        </select>

        <button class="btn-primary" @click="addExclusion">Ajouter</button>
      </div>
    </section>

    <!-- ====== FAVORIS ====== -->
    <section class="card">
      <h2 class="title">Recettes favorites</h2>

      <ul class="list">
        <li v-for="r in favoris" :key="r.id" class="list-item">
          {{ r.titre }}
          <button class="btn-danger" @click="removeFavori(r.id)">✕</button>
        </li>
      </ul>

      <div class="flex gap-2 mt-4">
        <select v-model="newFavori" class="input flex-1">
          <option value="" disabled>Ajouter une recette...</option>
          <option v-for="r in allRecettes" :value="r.id" :key="r.id">
            {{ r.titre }}
          </option>
        </select>

        <button class="btn-primary" @click="addFavori">Ajouter</button>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import api from "../../services/api";
import { showToast } from "../../services/toast.js";


// --- STATE ---
const general = ref({
  ville: "",
  date_naissance: "",
  sexe: "ND",
});

const allergies = ref([]);
const regimes = ref([]);
const exclusions = ref([]);
const favoris = ref([]);

const allAllergenes = ref([]);
const allRegimes = ref([]);
const allIngredients = ref([]);
const allRecettes = ref([]);

const newAllergie = ref("");
const newRegime = ref("");
const newExclusion = ref("");
const newFavori = ref("");

// ------ FORMAT DATE -------
function toDateInput(value) {
  if (!value) return "";
  return value.split("T")[0];
}

// ------ LOAD ------
onMounted(async () => {
  try {
    const { data: pref } = await api.get("/preferences");

    general.value = {
      ville: pref.general?.ville || "",
      sexe: pref.general?.sexe || "ND",
      date_naissance: toDateInput(pref.general?.date_naissance),
    };

    allergies.value = pref.allergies || [];
    regimes.value = pref.regimes || [];
    exclusions.value = pref.aliments_exclus || [];
    favoris.value = pref.favoris || [];

    allAllergenes.value = (await api.get("/allergenes")).data;

    // si /regimes n’existe pas → ignore
    try {
      allRegimes.value = (await api.get("/regimes")).data;
    } catch {
      allRegimes.value = [];
    }

    allIngredients.value = (await api.get("/ingredients")).data;
    allRecettes.value = (await api.get("/recettes")).data;
  } catch (err) {
    console.error(err);
  }
});

// ====== GENERAL ======
const saveGeneral = async () => {
  await api.put("/preferences/general", general.value);
  showToast("Informations générales mises à jour !");
};

// ====== ALLERGIES ======
const addAllergie = async () => {
  if (!newAllergie.value) return;
  await api.post("/preferences/allergies", { allergene_id: newAllergie.value });
  allergies.value = (await api.get("/preferences/allergies")).data;
  newAllergie.value = "";
  showToast("Allergie ajoutée !");
};

const removeAllergie = async (id) => {
  await api.delete(`/preferences/allergies/${id}`);
  allergies.value = allergies.value.filter((a) => a.id !== id);
  showToast("Allergie supprimée !");
};

// ====== REGIMES ======
const addRegime = async () => {
  if (!newRegime.value) return;
  await api.post("/preferences/regimes", { regime_id: newRegime.value });
  regimes.value = (await api.get("/preferences/regimes")).data;
  newRegime.value = "";
  showToast("Régime ajouté !");
};

const removeRegime = async (id) => {
  await api.delete(`/preferences/regimes/${id}`);
  regimes.value = regimes.value.filter((r) => r.id !== id);
  showToast("Régime supprimé !");
};

// ====== EXCLUSIONS ======
const addExclusion = async () => {
  if (!newExclusion.value) return;
  await api.post("/preferences/exclus", { ingredient_id: newExclusion.value });
  exclusions.value = (await api.get("/preferences/exclus")).data;
  newExclusion.value = "";
  showToast("Aliment exclu ajouté !");
};

const removeExclusion = async (id) => {
  await api.delete(`/preferences/exclus/${id}`);
  exclusions.value = exclusions.value.filter((i) => i.id !== id);
  showToast("Aliment exclu supprimé !");
};

// ====== FAVORIS ======
const addFavori = async () => {
  if (!newFavori.value) return;
  await api.post("/preferences/favoris", { recette_id: newFavori.value });
  favoris.value = (await api.get("/preferences/favoris")).data;
  newFavori.value = "";
  showToast("Recette ajoutée aux favoris !");
};

const removeFavori = async (id) => {
  await api.delete(`/preferences/favoris/${id}`);
  favoris.value = favoris.value.filter((r) => r.id !== id);
  showToast("Favori supprimé !");
};
</script>

<style scoped>
.card {
  @apply bg-slate-800 p-8 shadow-xl rounded-xl mb-10 border border-slate-700;
}

.title {
  @apply text-xl font-semibold mb-6 text-slate-200;
}

.label {
  @apply block text-sm font-medium text-slate-300 mb-1;
}

.input {
  @apply w-full p-2.5 border border-slate-700 rounded-lg
         focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500
         bg-slate-900 text-slate-200;
}

.btn-primary {
  @apply bg-emerald-600 hover:bg-emerald-700 text-white font-semibold
         px-5 py-2.5 rounded-lg duration-150;
}

.btn-danger {
  @apply bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded-lg text-xs;
}

.list {
  @apply space-y-3;
}

.list-item {
  @apply flex justify-between items-center bg-slate-900 px-4 py-2 rounded-lg border border-slate-700;
}
</style>
