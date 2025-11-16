const express = require("express");
const { authRequired, requireRole } = require("../middlewares/auth");
const controller = require("../controllers/etapes.controller");

const router = express.Router();

// Liste des étapes
router.get("/:recette_id", authRequired, controller.list);

// Ajout (admin)
router.post("/:recette_id", authRequired, requireRole("ADMIN"), controller.create);

// Update (admin)
router.put("/:recette_id/:ord", authRequired, requireRole("ADMIN"), controller.update);

// Suppression (admin)
router.delete("/:recette_id/:ord", authRequired, requireRole("ADMIN"), controller.remove);

module.exports = router;
