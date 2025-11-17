import api from "./api";
import { reactive } from "vue";
import { showToast } from "./toast";

// ====== STATE RÉACTIF ======
const state = reactive({
  favRecipes: [],
  excludedIngredients: [],
  userAllergies: [],
});

// Export pour l’utiliser dans les components
export const favRecipes = state.favRecipes;
export const excludedIngredients = state.excludedIngredients;
export const userAllergies = state.userAllergies;

// ===================================================
// LOADER : charge depuis le backend
// ===================================================
export async function loadUserPreferences() {
  try {
    const { data } = await api.get("/preferences");

    // ⚠ On convertit bien en IDs !
    state.favRecipes.splice(
      0,
      state.favRecipes.length,
      ...data.favoris.map((f) => f.id)
    );

    state.excludedIngredients.splice(
      0,
      state.excludedIngredients.length,
      ...data.aliments_exclus.map((i) => i.id)
    );

    state.userAllergies.splice(
      0,
      state.userAllergies.length,
      ...data.allergies.map((a) => a.id)
    );

  } catch (e) {
    console.error("Erreur load prefs :", e);
  }
}

// ===================================================
// Sauvegarde toutes les préférences vers backend
// ===================================================
async function pushPreferences() {
  try {
    await api.put("/preferences", {
      allergies: [...state.userAllergies],
      exclus: [...state.excludedIngredients],
      favoris: [...state.favRecipes],
    });
  } catch (e) {
    console.error(e);
    showToast("Erreur synchro préférences", "error");
  }
}

// ===================================================
// FAVORIS
// ===================================================
export function isFavorite(recetteId) {
  return state.favRecipes.includes(recetteId);
}

export async function toggleFavorite(recetteId) {

  const index = state.favRecipes.indexOf(recetteId);

  if (index === -1) {
    state.favRecipes.push(recetteId);
    showToast("Ajouté aux favoris !");
  } else {
    state.favRecipes.splice(index, 1);
    showToast("Retiré des favoris !");
  }

  await pushPreferences();
}

// ===================================================
// EXCLUS (idem favoris)
// ===================================================
export function isExcluded(ingredientId) {
  return state.excludedIngredients.includes(ingredientId);
}

export async function toggleExcluded(ingredientId) {
  const index = state.excludedIngredients.indexOf(ingredientId);

  if (index === -1) {
    state.excludedIngredients.push(ingredientId);
    showToast("Ingrédient exclu !");
  } else {
    state.excludedIngredients.splice(index, 1);
    showToast("Exclusion retirée !");
  }

  await pushPreferences();
}


