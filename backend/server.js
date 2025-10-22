const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());

app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello World from Node.js API!' });
});

const port = process.env.PORT || 3000; # 80, 3000
app.listen(port, () => console.log(`Backend running on port ${port}`));
