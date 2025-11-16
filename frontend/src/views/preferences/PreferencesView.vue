<template>
  <div class="px-8 py-6 max-w-4xl">
    <h1 class="text-2xl font-semibold mb-8">Mon Profil</h1>

    <!-- ======================== -->
    <!-- Informations générales   -->
    <!-- ======================== -->
    <section class="space-y-4 mb-10">
      <h2 class="text-lg font-semibold">Informations générales</h2>

      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="form-label">Nom</label>
          <input v-model="profile.nom" class="form-input" required />
        </div>

        <div>
          <label class="form-label">Prénom</label>
          <input v-model="profile.prenom" class="form-input" required />
        </div>

        <div class="col-span-2">
          <label class="form-label">Adresse mail</label>
          <input v-model="profile.email" class="form-input" type="email" required />
        </div>

        <div>
          <label class="form-label">Date de naissance</label>
          <input
            type="date"
            v-model="profile.date_naissance"
            class="form-input"
          />
        </div>

        <div>
          <label class="form-label">Ville</label>
          <input v-model="profile.ville" class="form-input" />
        </div>
      </div>
    </section>

    <!-- ======================== -->
    <!-- Allergies                -->
    <!-- ======================== -->
    <section class="space-y-3 mb-10">
      <h2 class="text-lg font-semibold">Allergies</h2>

      <div class="flex flex-wrap gap-4">
        <label
          v-for="a in allergenes"
          :key="a.id"
          class="flex items-center gap-2 text-sm"
        >
          <input type="checkbox" :value="a.id" v-model="form.allergies" />
          {{ a.libelle }}
        </label>
      </div>
    </section>

    <!-- ======================== -->
    <!-- Aliments exclus + favoris -->
    <!-- ======================== -->
    <section class="space-y-3">
      <h2 class="text-lg font-semibold">Préférences alimentaires</h2>

      <div class="grid grid-cols-2 gap-6">
        <div>
          <label class="form-label">Ingrédients exclus</label>
          <select v-model="form.exclus" multiple size="10" class="form-input h-48">
            <option v-for="i in ingredients" :value="i.id" :key="i.id">
              {{ i.nom }}
            </option>
          </select>
        </div>

        <div>
          <label class="form-label">Recettes favorites</label>
          <select v-model="form.favoris" multiple size="10" class="form-input h-48">
            <option v-for="r in recettes" :value="r.id" :key="r.id">
              {{ r.titre }}
            </option>
          </select>
        </div>
      </div>
    </section>

    <!-- ======================== -->
    <!-- Bouton d’enregistrement  -->
    <!-- ======================== -->
    <div class="mt-10">
      <button
        @click="save"
        class="px-6 py-3 bg-emerald-500 hover:bg-emerald-400 rounded text-slate-900 font-medium"
      >
        Enregistrer mes préférences
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import api from "../../services/api";
import { showToast } from "../../services/toast";

// ===============================
// Profil utilisateur
// ===============================
const profile = ref({
  nom: "",
  prenom: "",
  email: "",
  date_naissance: "",
  ville: "",
});

// ===============================
// Préférences
// ===============================
const form = ref({
  allergies: [],
  exclus: [],
  favoris: [],
});

// ===============================
// Listes pour les selects
// ===============================
const allergenes = ref([]);
const ingredients = ref([]);
const recettes = ref([]);

// Charger les options disponibles
const loadOptions = async () => {
  allergenes.value = (await api.get("/allergenes")).data;
  ingredients.value = (await api.get("/ingredients")).data;
  recettes.value = (await api.get("/recettes")).data;
};

// Charger l'utilisateur + ses préférences
const loadData = async () => {
  // Profil
  const me = await api.get("/users/me");
  profile.value = {
    ...me.data,
    date_naissance: me.data.date_naissance
      ? me.data.date_naissance.substring(0, 10)
      : "",
  };

  // Préférences
  const pref = await api.get("/preferences");
  form.value.allergies = pref.data.allergies;
  form.value.exclus = pref.data.aliments_exclus;
  form.value.favoris = pref.data.favoris;
};

// Enregistrement
const save = async () => {
  // Sauvegarde préférences
  await api.put("/preferences", form.value);

  // Sauvegarde profil utilisateur
  await api.put("/users/me", profile.value);

  showToast("Profil mis à jour !");
};

onMounted(async () => {
  await loadOptions();
  await loadData();
});
</script>

<style scoped>
.form-label {
  @apply block text-slate-400 text-sm mb-1;
}
.form-input {
  @apply w-full bg-slate-800 border border-slate-700 rounded px-3 py-2 text-slate-100 text-sm;
}
</style>
