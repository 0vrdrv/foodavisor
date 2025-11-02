const { validationResult } = require("express-validator");
const db = require("../config/db");
const { hashPassword, comparePassword } = require("../utils/password");
const { signToken } = require("../utils/jwt");

async function register(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const { email, password, nom, prenom, age, ville } = req.body;

  try {
    // 1. vérifier si email déjà pris
    const [exists] = await db.query(
      "SELECT id FROM utilisateur WHERE email = ?",
      [email]
    );
    if (exists.length > 0) {
      return res.status(400).json({ message: "Email déjà utilisé" });
    }

    // 2. hash mdp
    const hashed = await hashPassword(password);

    // 3. créer utilisateur
    const [result] = await db.query(
      `INSERT INTO utilisateur (email, hash_mdp, nom, prenom, age, ville)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [email, hashed, nom, prenom, age ?? null, ville ?? null]
    );

    const userId = result.insertId;

    // 4. lui mettre le rôle USER par défaut
    // on suppose que la table role contient déjà 'USER'
    const [roleRows] = await db.query(
      "SELECT id FROM role WHERE code = 'USER'"
    );
    if (roleRows.length > 0) {
      await db.query(
        "INSERT INTO utilisateur_role (utilisateur_id, role_id) VALUES (?, ?)",
        [userId, roleRows[0].id]
      );
    }

    // 5. générer token
    const token = signToken(userId);

    res.status(201).json({
      token,
      user: {
        id: userId,
        email,
        nom,
        prenom,
        age,
        ville,
        roles: ["USER"],
      },
    });
  } catch (err) {
    next(err);
  }
}

async function login(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const { email, password } = req.body;

  try {
    // 1. chercher user
    const [rows] = await db.query(
      "SELECT id, email, hash_mdp, nom, prenom, actif FROM utilisateur WHERE email = ?",
      [email]
    );
    if (rows.length === 0) {
      return res.status(400).json({ message: "Identifiants invalides" });
    }

    const user = rows[0];

    if (!user.actif) {
      return res.status(403).json({ message: "Compte désactivé" });
    }

    // 2. comparer mdp
    const ok = await comparePassword(password, user.hash_mdp);
    if (!ok) {
      return res.status(400).json({ message: "Identifiants invalides" });
    }

    // 3. récupérer les rôles
    const [roleRows] = await db.query(
      `SELECT r.code 
       FROM utilisateur_role ur
       JOIN role r ON r.id = ur.role_id
       WHERE ur.utilisateur_id = ?`,
      [user.id]
    );

    const token = signToken(user.id);

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        nom: user.nom,
        prenom: user.prenom,
        roles: roleRows.map((r) => r.code),
      },
    });
  } catch (err) {
    next(err);
  }
}

async function me(req, res, next) {
  try {
    // req.user est mis par le middleware authRequired
    // on peut aussi renvoyer ses régimes
    const [regimes] = await db.query(
      `SELECT r.id, r.code, r.libelle
       FROM utilisateur_regime ur
       JOIN regime r ON r.id = ur.regime_id
       WHERE ur.utilisateur_id = ?`,
      [req.user.id]
    );

    res.json({
      id: req.user.id,
      email: req.user.email,
      nom: req.user.nom,
      prenom: req.user.prenom,
      roles: req.user.roles,
      regimes,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  register,
  login,
  me,
};
