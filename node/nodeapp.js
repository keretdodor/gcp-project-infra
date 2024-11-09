const express = require('express');
const mongoose = require('mongoose');

const app = express();

app.set('view engine', 'ejs');

app.use(express.urlencoded({ extended: false }));

const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/mydb'; 
 
mongoose.connect(mongoUri, {
  useNewUrlParser: true, 
  useUnifiedTopology: true 
})
.then(() => console.log('MongoDB connected'))
.catch((err) => console.log('MongoDB connection error:', err));

const Item = require('./models/item.js');

app.get('/healthy', (req, res) => {
  res.status(200).send('OK'); 
});

app.get('/ready', (req, res) => {
  const dbState = mongoose.connection.readyState;
  if (dbState === 1) { 
    res.status(200).send('Ready');
  } else {
    res.status(500).send('Not ready');
  }
});
app.get('/', (req, res) => {
  Item.find()
    .then(items => res.render('index', { items }))
    .catch(err => res.status(404).json({ msg: 'No items found' }));
});

app.post('/item/add', (req, res) => {
  const newItem = new Item({
    name: req.body.name
  });

  newItem.save().then(item => res.redirect('/'));
});

const port = 3000;

app.listen(port, () => console.log('Server running...'));
