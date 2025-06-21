const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(express.json());

const mongoUrl = process.env.MONGO_URL || 'mongodb://localhost:27017/chatapp';
mongoose.connect(mongoUrl, { useNewUrlParser: true, useUnifiedTopology: true });

const userSchema = new mongoose.Schema({
  username: { type: String, unique: true, required: true },
  email:    { type: String, unique: true, required: true },
  passwordHash: { type: String, required: true },
  phone:    String
});
const User = mongoose.model('User', userSchema);

// Signup endpoint
app.post('/signup', async (req, res) => {
  const { username, email, password, phone } = req.body;
  if (!username || !email || !password) return res.status(400).json({ error: 'Missing fields' });
  const passwordHash = await bcrypt.hash(password, 10);
  try {
    const user = await User.create({ username, email, passwordHash, phone });
    res.status(201).json({ message: 'User created', userId: user._id });
  } catch (err) {
    res.status(400).json({ error: 'User already exists or invalid data' });
  }
});

// Login endpoint
app.post('/login', async (req, res) => {
  console.log('Login request body:', req.body); // Debug log
  const { usernameOrEmail, password } = req.body;
  if (!usernameOrEmail || !password) return res.status(400).json({ error: 'Missing fields' });
  const user = await User.findOne({
    $or: [{ username: usernameOrEmail }, { email: usernameOrEmail }]
  });
  if (user && await bcrypt.compare(password, user.passwordHash)) {
    res.json({ message: 'Login successful', userId: user._id, username: user.username, email: user.email, phone: user.phone });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

// Proxy endpoint to connect frontend chat to Ollama API
app.post('/chat', async (req, res) => {
  const { message } = req.body;
  if (!message) return res.status(400).json({ error: 'No message provided' });
  try {
    const ollamaRes = await axios.post('http://host.docker.internal:11434/api/generate', {
      model: 'llama3.2:1b-instruct-q4_K_M',
      prompt: message,
      stream: false
    });
    const aiReply = ollamaRes.data.response || 'No response from model.';
    res.json({ reply: aiReply });
  } catch (err) {
    console.error('Ollama API error:', err.response?.data || err.message);
    res.status(500).json({ error: 'Failed to get response from Ollama model.' });
  }
});

// Health check route
app.get('/', (req, res) => {
  res.send('Backend is running!');
});

app.listen(3001, () => console.log('Server running on http://localhost:3001'));
