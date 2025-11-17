<template>
  <div class="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
    <div class="bg-slate-900 border border-slate-700 rounded-xl p-6 w-full max-w-md">

      <h2 class="text-xl font-semibold mb-4">
        Ajouter au stock
      </h2>

      <!-- Ingredient -->
      <div class="mb-4">
        <label class="form-label">Ingrédient</label>
        <select v-model="form.ingredient_id" class="form-input">
          <option v-for="i in ingredients" :value="i.id" :key="i.id">
            {{ i.nom }}
          </option>
        </select>
      </div>

      <!-- Quantité -->
      <div class="mb-4">
        <label class="form-label">Quantité</label>
        <input v-model.number="form.quantite" type="number" min="0" step="0.001" class="form-input" />
      </div>

      <!-- Unité -->
      <div class="mb-4">
        <label class="form-label">Unité</label>
        <select v-model="form.unite_code" class="form-input">
          <option v-for="u in unites" :value="u.code" :key="u.code">
            {{ u.code }} — {{ u.libelle }}
          </option>
        </select>
      </div>

      <!-- Péremption -->
      <div class="mb-6">
        <label class="form-label">Date de péremption (optionnel)</label>
        <input type="date" v-model="form.date_peremption" class="form-input" />
      </div>

      <!-- Actions -->
      <div class="flex justify-end gap-3">
        <button @click="$emit('close')" class="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded">
          Annuler
        </button>

        <button @click="save" class="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded text-slate-900">
          Enregistrer
        </button>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import api from "../../services/api";
import { showToast } from "../../services/toast";

const props = defineProps({
  ingredientId: { type: Number, default: null }
});

const emit = defineEmits(["close", "saved"]);

const ingredients = ref([]);
const unites = ref([]);

const form = ref({
  ingredient_id: null,
  quantite: 0,
  unite_code: "",
  date_peremption: null
});

const loadOptions = async () => {
  ingredients.value = (await api.get("/ingredients")).data;
  unites.value = (await api.get("/unites")).data;

  if (props.ingredientId) {
    form.value.ingredient_id = props.ingredientId;
  }
};

const save = async () => {
  if (!form.value.ingredient_id || !form.value.quantite || !form.value.unite_code) {
    return showToast("Veuillez remplir tous les champs", "error");
  }

  try {
    // Ajout mouvement
    await api.post("/stocks/mvt", {
      ingredient_id: form.value.ingredient_id,
      delta: form.value.quantite,
      unite_code: form.value.unite_code,
      raison: "ajout"
    });

    // Mise à jour péremption si fournie
    if (form.value.date_peremption) {
      await api.put(`/stocks/${form.value.ingredient_id}`, {
        quantite: form.value.quantite,
        unite_code: form.value.unite_code,
        date_peremption: form.value.date_peremption
      });
    }

    showToast("Stock ajouté !");
    emit("saved");
  } catch (e) {
    console.error(e);
    showToast("Erreur lors de l'ajout au stock", "error");
  }
};
onMounted(loadOptions);
</script>

<style scoped>
.form-label {
  @apply block text-slate-300 text-sm mb-1;
}
.form-input {
  @apply w-full bg-slate-800 border border-slate-700 rounded px-3 py-2 text-slate-100;
}
</style>
