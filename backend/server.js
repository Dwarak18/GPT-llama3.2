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
  try {
    const userMessage = req.body.message;
    if (!userMessage) {
      return res.status(400).json({ error: 'No message provided.' });
    }

    // Use environment variable for Ollama URL, fallback to localhost
    const ollamaUrl = process.env.OLLAMA_URL || 'http://localhost:11434';
    console.log('Attempting to connect to Ollama at:', ollamaUrl);
    
    // First, check if the model is available
    try {
      const modelsResponse = await axios.get(`${ollamaUrl}/api/tags`);
      console.log('Available models:', modelsResponse.data);
    } catch (error) {
      console.error('Failed to fetch available models:', error.message);
    }
    
    // Call Ollama API without streaming for simpler handling
    const ollamaResponse = await axios.post(`${ollamaUrl}/api/generate`, {
      model: 'llama3.2:1b-instruct-q4_K_M',
      prompt: userMessage,
      stream: false
    }, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 30000 // 30 second timeout
    });

    console.log('Ollama response status:', ollamaResponse.status);

    if (ollamaResponse.status !== 200) {
      return res.status(500).json({ error: 'Ollama API error.' });
    }

    const reply = ollamaResponse.data.response || 'No response from AI model.';
    console.log('AI response:', reply);
    
    res.json({ reply });

  } catch (err) {
    console.error('Error in /chat:', err);
    console.error('Error details:', {
      message: err.message,
      code: err.code,
      type: err.constructor.name,
      stack: err.stack
    });
    
    // More specific error messages
    if (err.code === 'ECONNREFUSED') {
      res.status(503).json({ error: 'Cannot connect to Ollama service. Please ensure Ollama is running.' });
    } else if (err.response && err.response.status === 404) {
      res.status(404).json({ error: 'The specified AI model is not available. Please check if llama3.2:1b-instruct-q4_K_M is installed.' });
    } else if (err.code === 'ENOTFOUND') {
      res.status(503).json({ error: 'Ollama service not found. Please check your network configuration.' });
    } else {
      res.status(500).json({ error: 'Failed to get response from Ollama: ' + err.message });
    }
  }
});

// Return 405 for all non-POST methods on /chat
app.all('/chat', (req, res) => {
  if (req.method !== 'POST') {
    res.set('Allow', 'POST');
    return res.status(405).json({ error: 'Method Not Allowed. Only POST is supported on this endpoint.' });
  }
});

// Health check route
app.get('/', (req, res) => {
  res.send('Backend is running!');
});

// Ollama health check endpoint
app.get('/health/ollama', async (req, res) => {
  try {
    const ollamaUrl = process.env.OLLAMA_URL || 'http://localhost:11434';
    const response = await axios.get(`${ollamaUrl}/api/tags`, { timeout: 5000 });
    const models = response.data.models || [];
    const hasRequiredModel = models.some(model => model.name === 'llama3.2:1b-instruct-q4_K_M');
    
    res.json({
      status: 'healthy',
      ollama_url: ollamaUrl,
      models_available: models.length,
      required_model_available: hasRequiredModel,
      models: models.map(m => m.name)
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: error.message,
      ollama_url: process.env.OLLAMA_URL || 'http://localhost:11434'
    });
  }
});

app.listen(3001, () => console.log('Server running on http://localhost:3001'));
