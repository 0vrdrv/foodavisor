const { validationResult } = require("express-validator");
const db = require("../config/db");

// ----------------------------------------------------
// GET /api/users (ADMIN)
// ----------------------------------------------------
async function list(req, res, next) {
  try {
    const [rows] = await db.query(
      `SELECT id, email, nom, prenom, date_naissance, ville, date_inscription, actif
       FROM utilisateur
       ORDER BY date_inscription DESC`
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// GET /api/users/:id (ADMIN)
// ----------------------------------------------------
async function getById(req, res, next) {
  const id = req.params.id;
  try {
    const [rows] = await db.query(
      `SELECT id, email, nom, prenom, date_naissance, ville, date_inscription, actif
       FROM utilisateur
       WHERE id = ?`,
      [id]
    );
    if (rows.length === 0)
      return res.status(404).json({ message: "Utilisateur introuvable" });

    const [roles] = await db.query(
      `SELECT r.code
       FROM utilisateur_role ur
       JOIN role r ON r.id = ur.role_id
       WHERE ur.utilisateur_id = ?`,
      [id]
    );

    res.json({
      ...rows[0],
      roles: roles.map((r) => r.code),
    });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// PUT /api/users/:id (ADMIN)
// ----------------------------------------------------
async function update(req, res, next) {
  const id = req.params.id;
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

  const { nom, prenom, date_naissance, ville, actif } = req.body;

  try {
    const [result] = await db.query(
      `UPDATE utilisateur 
       SET nom = COALESCE(?, nom),
           prenom = COALESCE(?, prenom),
           date_naissance = COALESCE(?, date_naissance),
           ville = COALESCE(?, ville),
           actif = COALESCE(?, actif)
       WHERE id = ?`,
      [
        nom,
        prenom,
        date_naissance,
        ville,
        typeof actif === "boolean" ? (actif ? 1 : 0) : null,
        id,
      ]
    );

    if (result.affectedRows === 0)
      return res.status(404).json({ message: "Utilisateur introuvable" });

    res.json({ message: "Utilisateur mis à jour" });
  } catch (err) {
    next(err);
  }
}

// ----------------------------------------------------
// DELETE /api/users/:id (ADMIN)
// ----------------------------------------------------
async function remove(req, res, next) {
  const id = req.params.id;
  try {
    const [result] = await db.query("DELETE FROM utilisateur WHERE id = ?", [id]);
    if (result.affectedRows === 0)
      return res.status(404).json({ message: "Utilisateur introuvable" });
    res.json({ message: "Utilisateur supprimé" });
  } catch (err) {
    next(err);
  }
}

module.exports = { list, getById, update, remove };
