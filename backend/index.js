const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send({
    message: 'This is the backend for the continuous assessment',
  });
});

app.get('/api/v1/users', (req, res) => {
  res.json({
    message: 'This is the users endpoint',
    data: {
      name: 'John Doe',
      email: 'john.doe@example.com',
    },
  });
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});