const fs = require('fs');
const WS = process.env.HOME + '/workspace';

let ar = fs.readFileSync(WS + '/src/routes/attemptRoutes.js', 'utf8');

// Timer response mein alias fields add karo
ar = ar.replace(
  'return res.status(200).json({ startedAt: attempt.startedAt, totalDurationSec, elapsedSec, remainingSec, isExpired: remainingSec <= 0 });',
  `return res.status(200).json({ 
    startedAt: attempt.startedAt, 
    totalDurationSec, elapsedSec, remainingSec,
    timeRemaining: remainingSec,
    elapsed: elapsedSec,
    timeLeft: remainingSec,
    remainingTime: remainingSec,
    isExpired: remainingSec <= 0 
  });`
);

fs.writeFileSync(WS + '/src/routes/attemptRoutes.js', ar);
console.log('Timer alias fields added ✅');

// Verify
const check = fs.readFileSync(WS + '/src/routes/attemptRoutes.js', 'utf8');
console.log('timeRemaining in file:', check.includes('timeRemaining') ? '✅' : '❌');
