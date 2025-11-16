<template>
  <div class="px-6 py-4 max-w-4xl">
    <h1 class="text-xl font-semibold mb-6">
      {{ isEdit ? "Modifier la recette" : "Créer la recette" }}
    </h1>

    <form @submit.prevent="submit" class="space-y-8">

      <!-- Infos générales -->
      <section class="space-y-4">
        <div>
          <label class="form-label">Titre</label>
          <input v-model="form.titre" class="form-input" required />
        </div>

        <div>
          <label class="form-label">Description</label>
          <textarea v-model="form.description" class="form-input h-28" placeholder="Décris ta recette..."></textarea>
        </div>
      </section>

      <!-- Ingrédients -->
      <section class="space-y-3">
        <h2 class="text-lg font-semibold">Ingrédients</h2>

        <div class="space-y-2">
          <div v-for="(ing, i) in ingredients" :key="i"
            class="grid grid-cols-[1.5fr_0.5fr_0.5fr_auto] gap-2 items-center">

            <!-- Sélection ingrédient -->
            <select v-model="ing.ingredient_id" class="form-input" required>
              <option disabled value="">Choisir un ingrédient...</option>
              <option v-for="opt in allIngredients" :key="opt.id" :value="opt.id">
                {{ opt.nom }}
              </option>
            </select>

            <!-- Quantité -->
            <input
              v-model.number="ing.quantite"
              type="number"
              min="0"
              step="0.001"
              class="form-input"
              placeholder="Qté"
              required
            />

            <!-- Unité -->
            <select v-model="ing.unite_code" class="form-input w-28" required>
              <option disabled value="">Unité…</option>
              <option v-for="u in allUnits" :value="u.code" :key="u.code">
                {{ u.libelle }} ({{ u.type }})
              </option>
            </select>

            <button
              type="button"
              class="bg-red-600 hover:bg-red-500 text-white px-3 py-1 rounded"
              @click="removeIngredient(i)"
            >
              ✕
            </button>
          </div>
        </div>

        <button type="button" class="mt-2 bg-slate-800 hover:bg-slate-700 text-sm px-4 py-2 rounded"
          @click="addIngredient">
          + Ajouter un ingrédient
        </button>
      </section>

      <!-- Étapes -->
      <section class="space-y-3">
        <h2 class="text-lg font-semibold">Étapes</h2>

        <div class="space-y-2">
          <div v-for="(et, i) in etapes" :key="i" class="grid grid-cols-[1fr_auto] gap-2 items-start">
            <textarea v-model="et.description" class="form-input h-20" placeholder="Décris l’étape..."
              required></textarea>

            <button
              type="button"
              class="bg-red-600 hover:bg-red-500 text-white px-3 py-1 rounded mt-1"
              @click="removeEtape(i)"
            >
              ✕
            </button>
          </div>
        </div>

        <button type="button" class="mt-2 bg-slate-800 hover:bg-slate-700 text-sm px-4 py-2 rounded" @click="addEtape">
          + Ajouter une étape
        </button>
      </section>

      <!-- Bouton submit -->
      <div class="pt-4">
        <button class="px-6 py-3 bg-emerald-500 hover:bg-emerald-400 rounded text-slate-900 font-medium">
          {{ isEdit ? "Enregistrer la recette" : "Créer la recette" }}
        </button>
      </div>

    </form>
  </div>
</template>

<script setup>
import api from "../../services/api";
import { ref, onMounted, computed } from "vue";
import { useRoute, useRouter } from "vue-router";

const route = useRoute();
const router = useRouter();

const isEdit = computed(() => !!route.params.id);

const form = ref({
  titre: "",
  description: "",
  personnes_defaut: 2,
  image_url: null,
});

const allIngredients = ref([]);
const ingredients = ref([]);
const etapes = ref([]);
const allUnits = ref([]);

const loadUnits = async () => {
  const { data } = await api.get("/unites");
  allUnits.value = data;
};

const loadAllIngredients = async () => {
  const { data } = await api.get("/ingredients");
  allIngredients.value = data;
};

const loadRecette = async () => {
  if (!isEdit.value) return;

  const { data } = await api.get(`/recettes/${route.params.id}`);

  form.value = {
    titre: data.titre,
    description: data.description ?? "",
    personnes_defaut: data.personnes_defaut ?? 2,
    image_url: data.image_url ?? null,
  };

  ingredients.value = data.ingredients.map((ing) => ({
    ingredient_id: ing.id,
    quantite: ing.quantite,
    unite_code: ing.unite_code,
  }));

  etapes.value = data.etapes.map((et) => ({
    description: et.description,
  }));
};

const addIngredient = () => {
  ingredients.value.push({
    ingredient_id: "",
    quantite: null,
    unite_code: "",
  });
};

const removeIngredient = (index) => {
  ingredients.value.splice(index, 1);
};

const addEtape = () => {
  etapes.value.push({ description: "" });
};

const removeEtape = (index) => {
  etapes.value.splice(index, 1);
};

const submit = async () => {
  if (!form.value.titre.trim()) {
    showToast("Le titre est obligatoire !");
    return;
  }

  if (ingredients.value.length < 1) {
    showToast("Ajoute au moins un ingrédient.");
    return;
  }

  if (etapes.value.length < 1) {
    showToast("Ajoute au moins une étape.");
    return;
  }

  const payload = {
    ...form.value,
    ingredients: ingredients.value,
    etapes: etapes.value,
  };

  let id;

  if (!isEdit.value) {
    const { data } = await api.post("/recettes", payload);
    id = data.id;
    showToast("Recette créée !");
  } else {
    id = route.params.id;
    await api.put(`/recettes/${id}`, payload);
    showToast("Recette modifiée !");
  }

  router.push("/recettes");
};

onMounted(async () => {
  await loadAllIngredients();
  await loadUnits();
  await loadRecette();
});
</script>

<style scoped>
.form-label {
  @apply block mb-1 text-sm text-slate-300;
}

.form-input {
  @apply w-full bg-slate-800 border border-slate-700 rounded px-3 py-2 text-slate-100 text-sm;
}
</style>
