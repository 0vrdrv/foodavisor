const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/auth.controller");
const { authRequired } = require("../middlewares/auth");

const router = express.Router();

// POST /auth/register
router.post(
  "/register",
  [
    body("email").isEmail().withMessage("Email invalide"),
    body("password").isLength({ min: 6 }).withMessage("6 caractères min"),
    body("nom").notEmpty(),
    body("prenom").notEmpty(),
    body("date_naissance").optional().isDate(),
    body("ville").optional().isString(),
  ],
  controller.register
);

// POST /auth/login
router.post(
  "/login",
  [body("email").isEmail(), body("password").notEmpty()],
  controller.login
);

// GET /auth/me
router.get("/me", authRequired, controller.me);

module.exports = router;
