const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/cuissons.controller");
const { authRequired } = require("../middlewares/auth");

const router = express.Router();

router.get("/", authRequired, controller.list);

router.post(
  "/",
  authRequired,
  [
    body("recette_id").isInt(),
    body("personnes").isInt({ min: 1 }).default(1)
  ],
  controller.cook
);

module.exports = router;
