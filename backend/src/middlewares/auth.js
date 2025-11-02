// src/middlewares/auth.js
const jwt = require("jsonwebtoken");
const db = require("../config/db");

async function authRequired(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Token manquant" });
  }

  const token = header.split(" ")[1];

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    // payload contient userId
    // on recharge l'utilisateur pour avoir les infos fraîches
    const [rows] = await db.query(
      "SELECT id, email, nom, prenom, actif FROM utilisateur WHERE id = ?",
      [payload.userId]
    );
    if (rows.length === 0) {
      return res.status(401).json({ message: "Utilisateur introuvable" });
    }

    const user = rows[0];

    // on récupère ses rôles
    const [roleRows] = await db.query(
      `SELECT r.code 
       FROM utilisateur_role ur 
       JOIN role r ON r.id = ur.role_id 
       WHERE ur.utilisateur_id = ?`,
      [user.id]
    );

    user.roles = roleRows.map((r) => r.code);
    req.user = user;
    next();
  } catch (err) {
    console.error(err);
    return res.status(401).json({ message: "Token invalide" });
  }
}

function requireRole(roleCode) {
  return (req, res, next) => {
    if (!req.user || !req.user.roles.includes(roleCode)) {
      return res.status(403).json({ message: "Accès interdit" });
    }
    next();
  };
}

module.exports = {
  authRequired,
  requireRole,
};
