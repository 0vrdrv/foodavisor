const { validationResult } = require("express-validator");
const db = require("../config/db");

async function list(req, res, next) {
  try {
    const [rows] = await db.query(
      `SELECT id, email, nom, prenom, age, ville, date_inscription, actif
       FROM utilisateur
       ORDER BY date_inscription DESC`
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  const id = req.params.id;
  try {
    const [rows] = await db.query(
      `SELECT id, email, nom, prenom, age, ville, date_inscription, actif
       FROM utilisateur
       WHERE id = ?`,
      [id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: "Utilisateur introuvable" });
    }

    // on ajoute ses rôles
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

async function update(req, res, next) {
  const id = req.params.id;
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const { nom, prenom, age, ville, actif } = req.body;

  try {
    const [result] = await db.query(
      `UPDATE utilisateur 
       SET nom = COALESCE(?, nom),
           prenom = COALESCE(?, prenom),
           age = COALESCE(?, age),
           ville = COALESCE(?, ville),
           actif = COALESCE(?, actif)
       WHERE id = ?`,
      [nom, prenom, age, ville, typeof actif === "boolean" ? (actif ? 1 : 0) : null, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Utilisateur introuvable" });
    }

    res.json({ message: "Utilisateur mis à jour" });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  const id = req.params.id;
  try {
    const [result] = await db.query(
      "DELETE FROM utilisateur WHERE id = ?",
      [id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Utilisateur introuvable" });
    }
    res.json({ message: "Utilisateur supprimé" });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  getById,
  update,
  remove,
};
