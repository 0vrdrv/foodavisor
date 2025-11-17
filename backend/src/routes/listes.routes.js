const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/listes.controller");
const { authRequired } = require("../middlewares/auth");

const router = express.Router();

// Liste des listes de courses
router.get("/", authRequired, controller.list);

// Détails d’une liste
router.get("/:liste_id", authRequired, controller.getById);

// Créer une liste (avec ou sans recette_id)
router.post(
  "/",
  authRequired,
  [
    body("libelle").optional().isString(),
    body("recette_id").optional().isInt(),
  ],
  controller.create
);

// Ajouter un ingrédient à la liste
router.post(
  "/:liste_id/items",
  authRequired,
  [
    body("ingredient_id").isInt(),
    body("quantite").isFloat({ gt: 0 }),
    body("unite_code").isString().notEmpty(),
  ],
  controller.addItem
);

// Modifier la quantité d’un item (optionnel mais conseillé)
router.put(
  "/:liste_id/items/:ingredient_id",
  authRequired,
  [
    body("quantite").isFloat({ gt: 0 }),
    body("unite_code").optional().isString(),
  ],
  controller.updateItem
);

// Supprimer un ingrédient d’une liste
router.delete(
  "/:liste_id/items/:ingredient_id",
  authRequired,
  controller.removeItem
);

// Supprimer la liste entière
router.delete("/:liste_id", authRequired, controller.remove);

module.exports = router;
