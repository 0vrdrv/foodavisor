const express = require("express");
const { body } = require("express-validator");
const { authRequired } = require("../middlewares/auth");
const controller = require("../controllers/preferences.controller");

const router = express.Router();

// --------------------------------------------------
// Vue globale de toutes les préférences
// --------------------------------------------------
router.get("/", authRequired, controller.getAllPreferences);

// --------------------------------------------------
// Informations générales (ville, date_naissance, sexe)
// --------------------------------------------------
router.get("/general", authRequired, controller.getGeneral);

router.put(
  "/general",
  authRequired,
  [
    body("ville").optional().isString(),
    body("date_naissance").optional().isDate(),
    body("sexe").optional().isIn(["H", "F", "NB", "ND"]),
  ],
  controller.updateGeneral
);

// --------------------------------------------------
// Allergies
// --------------------------------------------------
router.get("/allergies", authRequired, controller.getAllergies);

router.post(
  "/allergies",
  authRequired,
  [body("allergene_id").isInt()],
  controller.addAllergie
);

router.delete(
  "/allergies/:allergene_id",
  authRequired,
  controller.removeAllergie
);

// --------------------------------------------------
// Régimes alimentaires
// --------------------------------------------------
router.get("/regimes", authRequired, controller.getRegimes);

router.post(
  "/regimes",
  authRequired,
  [body("regime_id").isInt()],
  controller.addRegime
);

router.delete(
  "/regimes/:regime_id",
  authRequired,
  controller.removeRegime
);

// --------------------------------------------------
// Aliments exclus
// --------------------------------------------------
router.get("/exclus", authRequired, controller.getExclusions);

router.post(
  "/exclus",
  authRequired,
  [body("ingredient_id").isInt()],
  controller.addExclusion
);

router.delete(
  "/exclus/:ingredient_id",
  authRequired,
  controller.removeExclusion
);

// --------------------------------------------------
// Favoris recettes
// --------------------------------------------------
router.get("/favoris", authRequired, controller.getFavoris);

router.post(
  "/favoris",
  authRequired,
  [body("recette_id").isInt()],
  controller.addFavori
);

router.delete(
  "/favoris/:recette_id",
  authRequired,
  controller.removeFavori
);

module.exports = router;
