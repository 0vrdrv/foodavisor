const express = require("express");
const { authRequired } = require("../middlewares/auth");
const ownerOrAdmin = require("../middlewares/ownerOrAdmin");
const controller = require("../controllers/recetteIngredients.controller");
const { body } = require("express-validator");

const router = express.Router();

// Ajouter un ingrédient à une recette
router.post(
  "/:recette_id",
  authRequired,
  ownerOrAdmin,
  [
    body("ingredient_id")
      .isInt({ min: 1 })
      .withMessage("ingredient_id invalide."),
    body("quantite")
      .isFloat({ gt: 0 })
      .withMessage("La quantité doit être > 0."),
    body("unite_code")
      .isString()
      .notEmpty()
      .withMessage("unite_code manquant."),
  ],
  controller.add
);

// Modifier un ingrédient d’une recette
router.put(
  "/:recette_id/:ingredient_id",
  authRequired,
  ownerOrAdmin,
  [
    body("quantite")
      .optional()
      .isFloat({ gt: 0 })
      .withMessage("La quantité doit être > 0."),
    body("unite_code")
      .optional()
      .isString()
      .notEmpty(),
  ],
  controller.update
);

router.delete(
  "/:recette_id/:ingredient_id",
  authRequired,
  ownerOrAdmin,
  controller.remove
);

module.exports = router;
