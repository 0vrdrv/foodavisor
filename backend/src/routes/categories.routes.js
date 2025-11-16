const express = require("express");
const router = express.Router();
const db = require("../config/db");
const { authRequired } = require("../middlewares/auth");

router.get("/", authRequired, async (req, res) => {
  try {
    const [rows] = await db.query(
      "SELECT id, libelle FROM categorie_ingredient ORDER BY libelle ASC"
    );
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Erreur serveur." });
  }
});

module.exports = router;
