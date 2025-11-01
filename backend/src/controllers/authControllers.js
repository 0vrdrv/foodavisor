import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { db } from '../../config/db.js';

// INSCRIPTION UTILISATEUR
export const register = async (req, res) => {
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
    console.error('Erreur register:', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// CONNEXION UTILISATEUR
export const login = async (req, res) => {
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

    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET || 'secret_temporaire',
      { expiresIn: '24h' }
    );

    res.status(200).json({
      message: 'Connexion réussie !',
      token,
      user: {
        id: user.id,
        email: user.email,
        nom: user.nom,
        prenom: user.prenom,
        date_naissance: user.date_naissance,
        ville: user.ville,
      },
    });
  } catch (err) {
    console.error('Erreur login:', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};
