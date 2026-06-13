const fs = require('fs'); const logs = fs.readFileSync('C:\\\\Users\\\\riads\\\\.pm2\\\\logs\\\\backend-out.log', 'utf8'); console.log(logs.slice(-2000));
