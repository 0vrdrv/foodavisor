const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/stocks.controller");
const { authRequired, requireRole } = require("../middlewares/auth");

const router = express.Router();

// Voir le stock de l’utilisateur connecté
router.get("/", authRequired, controller.list);

// Détail d’un ingrédient dans le stock utilisateur
router.get("/:ingredient_id", authRequired, controller.getById);

// Ajouter un mouvement (ajout, retrait, correction, cuisson, etc.)
router.post(
  "/mvt",
  authRequired,
  [
    body("ingredient_id").isInt(),
    body("delta").isFloat().notEmpty(),
    body("unite_code").isString().notEmpty(),
    body("raison").isIn(["ajout", "retrait", "correction", "cuisson", "peremption"]),
  ],
  controller.addMovement
);

// Mettre à jour manuellement une ligne de stock
router.put(
  "/:ingredient_id",
  authRequired,
  [
    body("quantite").isFloat({ min: 0 }),
    body("unite_code").optional().isString(),
    body("date_peremption").optional().isISO8601().toDate()
  ],
  controller.update
);

module.exports = router;
