<template>
  <div class="flex gap-2 items-center">
    <!-- Bouton retirer -->
    <button
      @click="update(-1)"
      class="px-2 py-1 bg-red-600 hover:bg-red-500 text-white rounded text-sm"
      title="Retirer 1 unité"
    >
      ➖
    </button>

    <!-- Bouton ajouter -->
    <button
      @click="update(+1)"
      class="px-2 py-1 bg-emerald-500 hover:bg-emerald-400 text-slate-900 rounded text-sm"
      title="Ajouter 1 unité"
    >
      ➕
    </button>
  </div>
</template>

<script setup>
import api from "../../services/api";
import { showToast } from "../../services/toast";

const props = defineProps({
  item: { type: Object, required: true }
});

const emit = defineEmits(["updated"]);

const update = async (delta) => {
  try {
    await api.post("/stocks/mvt", {
      ingredient_id: props.item.ingredient_id,
      delta,
      unite_code: props.item.unite_code,
      raison: delta > 0 ? "ajout" : "retrait"
    });

    showToast("Stock mis à jour !");
    emit("updated");
  } catch (e) {
    console.error(e);
    showToast("Erreur lors de la modification du stock", "error");
  }
};
</script>
