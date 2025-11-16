const express = require("express");
const { authRequired, requireRole } = require("../middlewares/auth");
const controller = require("../controllers/allergenes.controller");
const router = express.Router();

// Liste
router.get("/", authRequired, controller.list);

// Création admin
router.post("/", authRequired, requireRole("ADMIN"), controller.create);

// Suppression admin
router.delete("/:id", authRequired, requireRole("ADMIN"), controller.remove);

// Ajouter un allergène à un ingrédient
router.post("/ingredient/:ingredient_id", authRequired, controller.addToIngredient);

// Supprimer un lien ingrédient → allergène
router.delete("/ingredient/:ingredient_id/:allergene_id", authRequired, controller.removeFromIngredient);

module.exports = router;
