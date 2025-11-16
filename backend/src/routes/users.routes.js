const express = require("express");
const { body } = require("express-validator");
const { authRequired, requireRole } = require("../middlewares/auth");
const controller = require("../controllers/users.controller");

const router = express.Router();

// ----------------------------------------------
// 🔥 ROUTES UTILISATEUR CONNECTÉ
// ----------------------------------------------
router.get("/me", authRequired, controller.getMe);

router.put(
  "/me",
  authRequired,
  [
    body("nom").optional().notEmpty(),
    body("prenom").optional().notEmpty(),
    body("email").optional().isEmail(),
    body("ville").optional(),
    body("date_naissance").optional().isDate(),
  ],
  controller.updateMe
);

// ----------------------------------------------
// 🔥 ROUTES ADMIN
// ----------------------------------------------
router.get("/", authRequired, requireRole("ADMIN"), controller.list);

router.get("/:id", authRequired, requireRole("ADMIN"), controller.getById);

router.put(
  "/:id",
  authRequired,
  requireRole("ADMIN"),
  [
    body("nom").optional().notEmpty(),
    body("prenom").optional().notEmpty(),
    body("ville").optional(),
    body("date_naissance").optional().isDate(),
    body("actif").optional().isBoolean(),
  ],
  controller.update
);

router.delete(
  "/:id",
  authRequired,
  requireRole("ADMIN"),
  controller.remove
);

module.exports = router;
