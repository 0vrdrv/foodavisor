import express from 'express';
import cors from 'cors';
import authRoutes from './src/routes/authRoutes.js';
import userRoutes from './src/routes/userRoutes.js';

const app = express();

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
