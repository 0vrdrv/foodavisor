const express = require("express");
const { authRequired } = require("../middlewares/auth");
const controller = require("../controllers/preferences.controller");

const router = express.Router();

// Récupérer toutes les préférences utilisateur
router.get("/", authRequired, controller.getPreferences);

// Mettre à jour les préférences utilisateur
router.put("/", authRequired, controller.updatePreferences);

module.exports = router;
