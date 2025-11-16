const db = require("../config/db");

module.exports = async function ownerOrAdmin(req, res, next) {
  try {
    const recetteId = req.params.id;

    const [rows] = await db.query(
      "SELECT auteur_id FROM recette WHERE id = ?",
      [recetteId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "Recette introuvable" });
    }

    const auteurId = rows[0].auteur_id;

    // Admin OK
    if (req.user.roles.includes("ADMIN")) return next();

    // Propriétaire OK
    if (req.user.id === auteurId) return next();

    return res.status(403).json({ message: "Accès refusé." });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Erreur serveur." });
  }
};
