import express from 'express';
import {
  getUserProfile,
  updateUserProfile,
} from '../controllers/userController.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/me', verifyToken, getUserProfile);
router.put('/me', verifyToken, updateUserProfile);

export default router;
