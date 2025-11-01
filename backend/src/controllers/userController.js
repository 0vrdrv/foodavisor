import { db } from '../../config/db.js';

//Récupérer le profil utilisateur
export const getUserProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await db.query(
      'SELECT id, email, nom, prenom, date_naissance, ville FROM utilisateur WHERE id = ?',
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Utilisateur introuvable.' });
    }

    res.status(200).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// Mettre à jour le profil utilisateur
export const updateUserProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { nom, prenom, date_naissance, ville } = req.body;

    // Construire dynamiquement la requête UPDATE
    const fields = [];
    const values = [];

    if (nom !== undefined) {
      fields.push('nom = ?');
      values.push(nom);
    }
    if (prenom !== undefined) {
      fields.push('prenom = ?');
      values.push(prenom);
    }
    if (date_naissance !== undefined) {
      fields.push('date_naissance = ?');
      values.push(date_naissance);
    }
    if (ville !== undefined) {
      fields.push('ville = ?');
      values.push(ville);
    }

    // Si aucun champ n'est fourni
    if (fields.length === 0) {
      return res.status(400).json({ message: 'Aucun champ à mettre à jour.' });
    }

    // Ajouter l'ID à la fin
    values.push(userId);

    // Construire et exécuter la requête
    const query = `UPDATE utilisateur SET ${fields.join(', ')} WHERE id = ?`;
    await db.query(query, values);

    res.status(200).json({ message: 'Profil mis à jour avec succès.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};
