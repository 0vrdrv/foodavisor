import express from 'express';
import bcrypt from 'bcrypt';
import { db } from '../../config/db.js';

const router = express.Router();

// Inscription utilisateur
router.post('/register', async (req, res) => {
  try {
    const { email, password, nom, prenom, date_naissance, ville } = req.body;

    const [rows] = await db.query('SELECT * FROM utilisateur WHERE email = ?', [
      email,
    ]);
    if (rows.length > 0) {
      return res
        .status(400)
        .json({ message: 'Cette adresse email existe déjà !' });
    }

    const hash = await bcrypt.hash(password, 10);
    await db.query(
      'INSERT INTO utilisateur (email, hash_mdp, nom, prenom, date_naissance, ville) VALUES (?, ?, ?, ?, ?, ?)',
      [email, hash, nom, prenom, date_naissance, ville]
    );

    res.status(201).json({ message: 'Utilisateur inscrit avec succès.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
});

// Connexion utilisateur
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const [rows] = await db.query('SELECT * FROM utilisateur WHERE email = ?', [
      email,
    ]);
    if (rows.length === 0) {
      return res
        .status(400)
        .json({ message: "Cette adresse email n'existe pas !" });
    }

    const user = rows[0];
    const isPasswordValid = await bcrypt.compare(password, user.hash_mdp);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Mot de passe incorrect !' });
    }

    res.status(200).json({ message: 'Connexion réussie !', user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
});

export default router;
