const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/ingredients.controller");
const { authRequired, requireRole } = require("../middlewares/auth");

const router = express.Router();

router.get("/", authRequired, controller.list);

router.get("/:id", authRequired, controller.getById);

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
    body("prix_ref").optional().isFloat(),
  ],
  controller.create
);

router.put("/:id", authRequired, requireRole("ADMIN"), controller.update);

router.delete("/:id", authRequired, requireRole("ADMIN"), controller.remove);

module.exports = router;
