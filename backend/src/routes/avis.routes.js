const express = require("express");
const { body } = require("express-validator");
const controller = require("../controllers/avis.controller");
const { authRequired } = require("../middlewares/auth");

const router = express.Router();

router.get("/recette/:recette_id", authRequired, controller.listForRecipe);

router.post(
  "/recette/:recette_id",
  authRequired,
  [
    body("note").isInt({ min: 1, max: 5 }),
    body("commentaire").optional().isString()
  ],
  controller.create
);

router.put(
  "/recette/:recette_id",
  authRequired,
  [
    body("note").optional().isInt({ min: 1, max: 5 }),
    body("commentaire").optional().isString()
  ],
  controller.update
);

router.delete("/recette/:recette_id", authRequired, controller.remove);


module.exports = router;
