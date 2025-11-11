const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/recettes.controller");
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
    body("titre").notEmpty(),
    body("description").optional().isString(),
    body("image_url").optional().isString(),
    body("personnes_defaut").optional().isInt({ min: 1 }),
  ],
  controller.create
);

// Modification d'une recette (ADMIN)
router.put(
  "/:id",
  authRequired,
  requireRole("ADMIN"),
  controller.update
);

// Suppression d'une recette (ADMIN)
router.delete(
  "/:id",
  authRequired,
  requireRole("ADMIN"),
  controller.remove
);

module.exports = router;
