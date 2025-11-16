<template>
  <div>
    <h1 class="text-xl font-semibold mb-6">
      {{ isEdit ? "Modifier un ingrédient" : "Ajouter un ingrédient" }}
    </h1>

    <form @submit.prevent="submit" class="space-y-6 max-w-xl">

      <!-- Nom -->
      <div>
        <label class="form-label">Nom</label>
        <input v-model="form.nom" class="form-input" required />
      </div>

      <!-- Catégorie -->
      <div>
        <label class="form-label">Catégorie</label>
        <select v-model="form.categorie_id" class="form-input" required>
          <option disabled value="">Sélectionner...</option>
          <option v-for="c in categories" :value="c.id">
            {{ c.libelle }}
          </option>
        </select>
      </div>

      <!-- Prix -->
      <div>
        <label class="form-label">Prix estimé (€)</label>
        <input v-model.number="form.prix_unitaire" type="number" step="0.01" class="form-input" />
      </div>

      <!-- Nutrition -->
      <h2 class="text-lg font-medium">Valeurs nutritionnelles (pour 100 g)</h2>

      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="form-label">Calories</label>
          <input v-model.number="form.kcal_100g" class="form-input" />
        </div>
        <div>
          <label class="form-label">Protéines</label>
          <input v-model.number="form.prot_100g" class="form-input" />
        </div>
        <div>
          <label class="form-label">Glucides</label>
          <input v-model.number="form.gluc_100g" class="form-input" />
        </div>
        <div>
          <label class="form-label">Lipides</label>
          <input v-model.number="form.lip_100g" class="form-input" />
        </div>
      </div>

      <!-- Allergènes -->
      <div v-if="auth.isAdmin()">
        <h2 class="text-lg font-medium mt-6">Allergènes</h2>

        <div class="flex flex-wrap gap-2 max-w-md">
          <label v-for="al in allergenesList" :key="al.id" class="flex items-center gap-2 text-sm">
            <input type="checkbox" :value="al.id" v-model="selectedAllergenes" />
            {{ al.libelle }}
          </label>
        </div>
      </div>

      <button class="px-6 py-2 bg-emerald-500 hover:bg-emerald-400 rounded text-slate-900">
        {{ isEdit ? "Modifier" : "Créer" }}
      </button>

    </form>
  </div>
</template>

<script setup>
import api from "../../services/api";
import { ref, onMounted, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useAuthStore } from "../../services/store";
import { useToast } from "../../composables/useToast"; // GOOD
const { showToast } = useToast();

const auth = useAuthStore();
const route = useRoute();
const router = useRouter();

const isEdit = computed(() => !!route.params.id);

const form = ref({
  nom: "",
  categorie_id: "",
  prix_unitaire: null,
  kcal_100g: null,
  prot_100g: null,
  gluc_100g: null,
  lip_100g: null,
});

const categories = ref([]);
const allergenesList = ref([]);
const selectedAllergenes = ref([]);

const loadCategories = async () => {
  const { data } = await api.get("/categories");
  categories.value = data;
};

const loadAllergenes = async () => {
  const { data } = await api.get("/allergenes");
  allergenesList.value = data;
};

const loadIngredient = async () => {
  if (!isEdit.value) return;

  const id = route.params.id;

  const { data } = await api.get(`/ingredients/${id}`);
  form.value = data;

  const { data: al } = await api.get(`/allergenes/ingredient/${id}`);
  selectedAllergenes.value = al.map(a => a.id);
};

const submit = async () => {
  try {
    // --- VALIDATION MANUELLE ---
    if (!form.value.nom.trim()) {
      showToast("Le nom est obligatoire !");
      return;
    }

    if (!form.value.categorie_id) {
      showToast("Sélectionne une catégorie !");
      return;
    }

    let id = route.params.id;

    if (isEdit.value) {
      await api.put(`/ingredients/${id}`, form.value);
      showToast("Ingrédient modifié !");
    } else {
      const { data } = await api.post(`/ingredients`, form.value);
      id = data.id;
      showToast("Ingrédient créé !");
    }

    // --- Allergènes (admin uniquement) ---
    if (auth.isAdmin()) {
      await api.delete(`/allergenes/ingredient/${id}/all`).catch(() => {});

      for (const alId of selectedAllergenes.value) {
        await api.post(`/allergenes/ingredient/${id}`, { allergene_id: alId });
      }
      showToast("Allergènes mis à jour !");
    }

    router.push("/ingredients");

  } catch (e) {
    showToast("Erreur lors de l’enregistrement", "error");
    console.error(e);
  }
};

onMounted(async () => {
  await loadCategories();
  await loadAllergenes();
  await loadIngredient();
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
