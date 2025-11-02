const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/recettes.controllers");
const { authRequired, requireRole } = require("../middlewares/auth");

const router = express.Router();

// Liste des recettes
router.get("/", authRequired, controller.list);

// Détail complet d'une recette (avec ingrédients + étapes)
router.get("/:id", authRequired, controller.getById);

// Création d'une recette (ADMIN)
router.post(
  "/",
  authRequired,
  requireRole("ADMIN"),
  [
    body("nom").notEmpty(),
    body("description").notEmpty(),
    body("difficulte").isInt({ min: 1, max: 5 }),
    body("temps_preparation").isInt(),
    body("temps_cuisson").isInt()
  ],
  controller.create
);

// Modification d'une recette
router.put(
  "/:id",
  authRequired,
  requireRole("ADMIN"),
  controller.update
);

// Suppression d'une recette
router.delete(
  "/:id",
  authRequired,
  requireRole("ADMIN"),
  controller.remove
);

module.exports = router;
