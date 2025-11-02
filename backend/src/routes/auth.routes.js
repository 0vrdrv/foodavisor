const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/auth.controller");
const { authRequired } = require("../middlewares/auth");

const router = express.Router();

// POST /api/auth/register
router.post(
  "/register",
  [
    body("email").isEmail().withMessage("Email invalide"),
    body("password").isLength({ min: 6 }).withMessage("6 caractères min"),
    body("nom").notEmpty(),
    body("prenom").notEmpty(),
  ],
  controller.register
);

// POST /api/auth/login
router.post(
  "/login",
  [
    body("email").isEmail(),
    body("password").notEmpty()
  ],
  controller.login
);

// GET /api/auth/me
router.get("/me", authRequired, controller.me);

module.exports = router;
