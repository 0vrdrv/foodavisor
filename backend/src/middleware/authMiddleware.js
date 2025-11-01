import jwt from 'jsonwebtoken';

export const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ message: 'Token manquant.' });
  }

  const token = authHeader.split(' ')[1];

  jwt.verify(
    token,
    process.env.JWT_SECRET || 'secret_temporaire',
    (err, decoded) => {
      if (err) {
        return res.status(403).json({ message: 'Token invalide.' });
      }

      req.user = decoded;

      next();
    }
  );
};
