const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/ingredients.controller");
const { authRequired, requireRole } = require("../middlewares/auth");

const router = express.Router();

// Liste
router.get("/", authRequired, controller.list);

// Détail
router.get("/:id", authRequired, controller.getById);

// Création (ADMIN)
router.post(
  "/",
  authRequired,
  requireRole("ADMIN"),
  [
    body("nom").notEmpty(),
    body("categorie_id").isInt(),
    body("kcal_100g").optional().isFloat(),
    body("prot_100g").optional().isFloat(),
    body("gluc_100g").optional().isFloat(),
    body("lip_100g").optional().isFloat(),
    body("prix_unitaire").optional().isFloat(),
    body("image_url").optional().isString(),
  ],
  controller.create
);

// Modification (ADMIN)
router.put(
  "/:id",
  authRequired,
  requireRole("ADMIN"),
  [
    body("image_url").optional().isString(),
    body("prix_unitaire").optional().isFloat(),
  ],
  controller.update
);

// Suppression (ADMIN)
router.delete("/:id", authRequired, requireRole("ADMIN"), controller.remove);

module.exports = router;
