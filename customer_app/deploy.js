const { spawn } = require('child_process');

const surge = spawn('npx', ['surge', './build/web', 'boutique-kurdish-app.surge.sh'], { shell: true });

surge.stdout.on('data', (data) => {
  const output = data.toString();
  console.log(output);
  if (output.toLowerCase().includes('email:')) {
    surge.stdin.write('dummy-agent-' + Math.floor(Math.random() * 100000) + '@gmail.com\n');
  }
  if (output.toLowerCase().includes('password:')) {
    surge.stdin.write('dummy123456\n');
  }
});

surge.stderr.on('data', (data) => {
  console.error(data.toString());
});

surge.on('close', (code) => {
  console.log(`child process exited with code ${code}`);
});
