const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/recettes.controller");
const { authRequired, requireRole } = require("../middlewares/auth");
const ownerOrAdmin = require("../middlewares/ownerOrAdmin");

const router = express.Router();

// Liste
router.get("/", authRequired, controller.list);

// Détail (avec ingrédients + étapes)
router.get("/:id", authRequired, controller.getById);

// Création — désormais USER + ADMIN
router.post(
  "/",
  authRequired,
  controller.create
);

// Modification — admin ou propriétaire
router.put("/:id", authRequired, ownerOrAdmin, controller.update);

// Suppression — admin ou propriétaire
router.delete("/:id", authRequired, ownerOrAdmin, controller.remove);

module.exports = router;
