const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());

// Connect to MongoDB
// Fixed code (for Mongoose v7+)
mongoose.connect("mongodb://localhost:27017/smart_queue_management_application")
.then(() => console.log("Database connected"))
.catch((err) => console.log("DB connection error:", err));



// Test route
app.get('/', (req, res) => {
    res.send('Server is running on localhost:8000');
});

// Routes
const register = require('./Routers/registerrouter'); // Correct path based on your structure
app.use('/api', register); // All routes start with /api

const login = require('./Routers/loginrouter');
app.use('/api', login);


// Start server
const PORT = 8000;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
