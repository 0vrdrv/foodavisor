const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/listes.controller");
const { authRequired } = require("../middlewares/auth");

const router = express.Router();

router.get("/", authRequired, controller.list);

router.get("/:liste_id", authRequired, controller.getById);

router.post(
  "/",
  authRequired,
  [
    body("libelle").notEmpty(),
    body("recette_id").optional().isInt()
  ],
  controller.create
);

router.post(
  "/:liste_id/item",
  authRequired,
  [
    body("ingredient_id").isInt(),
    body("quantite").isFloat({ gt: 0 }),
    body("unite_code").isString().notEmpty()
  ],
  controller.addItem
);

router.delete(
  "/:liste_id/item/:ingredient_id",
  authRequired,
  controller.removeItem
);

router.delete("/:liste_id", authRequired, controller.removeList);

module.exports = router;
