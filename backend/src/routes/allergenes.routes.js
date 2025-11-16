const express = require("express");
const { authRequired, requireRole } = require("../middlewares/auth");
const controller = require("../controllers/allergenes.controller");
const router = express.Router();
const db = require("../config/db");

// Liste
router.get("/", authRequired, controller.list);

// Création admin
router.post("/", authRequired, requireRole("ADMIN"), controller.create);

// Suppression admin
router.delete("/:id", authRequired, requireRole("ADMIN"), controller.remove);

router.get("/ingredient/:ingredient_id", authRequired, async (req, res) => {
  try {
    const { ingredient_id } = req.params;

    const [rows] = await db.query(
      `SELECT a.*
       FROM allergene a
       JOIN ingredient_allergene ia ON ia.allergene_id = a.id
       WHERE ia.ingredient_id = ?`,
      [ingredient_id]
    );

    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Erreur serveur." });
  }
});


// Ajouter un allergène à un ingrédient
router.post(
  "/ingredient/:ingredient_id",
  authRequired,
  controller.addToIngredient
);

// Supprimer un lien ingrédient → allergène
router.delete(
  "/ingredient/:ingredient_id/all",
  authRequired,
  requireRole("ADMIN"),
  async (req, res) => {
    const { ingredient_id } = req.params;
    await db.query("DELETE FROM ingredient_allergene WHERE ingredient_id = ?", [
      ingredient_id,
    ]);
    res.json({ message: "Allergènes supprimés." });
  }
);

module.exports = router;
