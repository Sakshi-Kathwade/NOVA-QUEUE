const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();

//middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());

mongoose.connect("mongodb://localhost:27017/smart_queue_management_application")
.then(() => console.log("Database connected"))
.catch((err) => console.log("DB connection error:", err));

// Test route
app.get('/', (req, res) => {
    res.send('Server is running on localhost:8000');
});
// Routes
const register = require('./Routers/registerrouter');
app.use('/api', register);

const logout = require('./Routers/registerrouter');
app.use('/api',logout);    

const login = require('./Routers/loginrouter');
app.use('/api', login);

const adminLogin= require('./Routers/adminrouter');
app.use('/api', adminLogin);

const createqueue = require('./Routers/create_queue_router');
app.use('/api', createqueue);

const queue = require('./Routers/create_queue_router'); 
app.use('/api', queue);

const queuestatus = require('./Routers/create_queue_router');
app.use('/api', queuestatus);   

const token = require('./Routers/tokenrouter');
app.use('/api', token);

const tokenget= require('./Routers/tokenrouter');
app.use('/api', tokenget);

const tokendelete= require('./Routers/tokenrouter');
app.use('/api', tokendelete);

const changepassword = require('./Routers/registerrouter');
app.use('/api', changepassword);

const studentget = require('./Routers/registerrouter');
app.use('/api', studentget);    

const createAdmin = require('./Routers/adminrouter');
app.use('/api', createAdmin);

const getAlltoken = require('./Routers/tokenrouter');
app.use('/api', getAlltoken);   




// Start server
const PORT = 8000;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
