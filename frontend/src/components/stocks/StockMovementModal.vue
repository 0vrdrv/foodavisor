<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
    <div class="bg-slate-900 border border-slate-700 rounded-xl w-full max-w-lg p-6">

      <!-- TITRE -->
      <h2 class="text-xl font-semibold mb-4">
        {{ titles[type] }}
      </h2>

      <!-- AJOUT / RETRAIT / CORRECTION -->
      <div v-if="type !== 'peremption'" class="mb-4">
        <label class="form-label">Quantité</label>
        <input
          type="number"
          min="0"
          step="0.001"
          v-model.number="form.quantite"
          class="form-input"
          required
        />
      </div>

      <!-- UNITE (uniquement pour ajout/retrait) -->
      <div v-if="type === 'add' || type === 'remove'" class="mb-4">
        <label class="form-label">Unité</label>
        <select v-model="form.unite_code" class="form-input" required>
          <option disabled value="">Choisir...</option>
          <option v-for="u in unites" :value="u.code" :key="u.code">
            {{ u.libelle }} ({{ u.type }})
          </option>
        </select>
      </div>

      <!-- DATE PEREMPTION -->
      <div v-if="type === 'peremption'">
        <label class="form-label">Nouvelle date de péremption</label>
        <input type="date" v-model="form.date_peremption" class="form-input" />
      </div>

      <!-- BOUTONS -->
      <div class="flex justify-end gap-3 mt-6">
        <button
          @click="$emit('close')"
          class="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded"
        >
          Annuler
        </button>

        <button
          @click="save"
          class="px-4 py-2 bg-emerald-500 hover:bg-emerald-400 text-slate-900 rounded"
        >
          Valider
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import api from "../../services/api";
import { useToast } from "../../composables/useToast";

const props = defineProps({
  type: { type: String, required: true }, // "add" | "remove" | "correct" | "peremption"
  ingredient: { type: Object, required: true },
});

const emit = defineEmits(["close", "saved"]);
const { showToast } = useToast();

const form = ref({
  quantite: null,
  unite_code: "",
  date_peremption: null,
});

const unites = ref([]);

const titles = {
  add: "Ajouter une quantité",
  remove: "Retirer une quantité",
  correct: "Corriger la quantité",
  peremption: "Modifier la date de péremption",
};

// Charger unités pour add/remove
const loadUnits = async () => {
  const { data } = await api.get("/unites");
  unites.value = data;
};

onMounted(loadUnits);

const save = async () => {
  try {
    // === AJOUT ===
    if (props.type === "add") {
      await api.post("/stocks/mvt", {
        ingredient_id: props.ingredient.ingredient_id,
        delta: form.value.quantite,
        unite_code: form.value.unite_code,
        raison: "ajout",
      });
      showToast("Quantité ajoutée !");
    }

    // === RETRAIT ===
    else if (props.type === "remove") {
      await api.post("/stocks/mvt", {
        ingredient_id: props.ingredient.ingredient_id,
        delta: -form.value.quantite,
        unite_code: form.value.unite_code,
        raison: "retrait",
      });
      showToast("Quantité retirée !");
    }

    // === CORRECTION ===
    else if (props.type === "correct") {
      await api.put(`/stocks/${props.ingredient.ingredient_id}`, {
        quantite: form.value.quantite,
        unite_code: props.ingredient.unite_code,
      });
      showToast("Quantité corrigée !");
    }

    // === MODIFICATION DATE PEREMPTION ===
    else if (props.type === "peremption") {
      await api.put(`/stocks/${props.ingredient.ingredient_id}`, {
        quantite: props.ingredient.quantite,
        date_peremption: form.value.date_peremption,
      });
      showToast("Date de péremption mise à jour !");
    }

    emit("saved");
  } catch (e) {
    console.error(e);
    showToast("Erreur lors de la modification", "error");
  }
};
</script>

<style scoped>
.form-label {
  @apply block text-slate-400 text-sm mb-1;
}
.form-input {
  @apply w-full bg-slate-800 border border-slate-700 rounded px-3 py-2 text-slate-100 text-sm;
}
</style>
