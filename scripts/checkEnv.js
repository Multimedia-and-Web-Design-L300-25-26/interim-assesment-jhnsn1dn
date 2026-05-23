// Lightweight environment validator. Prints clear setup instructions when variables
// are missing or look like placeholders. Exits with code 1 when run as CLI and
// critical vars are missing.
require('dotenv').config();

const checkEnv = () => {
  const missing = [];
  const warnings = [];

  const uri = process.env.MONGODB_URI;
  const jwt = process.env.JWT_SECRET;

  if (!uri) missing.push('MONGODB_URI');
  else if (uri.includes('<') || uri.includes('your_')) {
    warnings.push('MONGODB_URI looks like a placeholder.');
  }

  if (!jwt) missing.push('JWT_SECRET');
  else if (jwt.includes('your_')) warnings.push('JWT_SECRET looks like a placeholder.');

  if (missing.length) {
    console.error(`❌ Missing env var(s): ${missing.join(', ')}`);
  }
  if (warnings.length) {
    console.warn(`⚠️ ${warnings.join(' ')}`);
  }

  if (missing.length || warnings.length) {
    console.log('\nSetup instructions:');
    if (missing.includes('MONGODB_URI')) {
      console.log('- Add a valid MongoDB connection string to MONGODB_URI in .env');
    }
    if (missing.includes('JWT_SECRET')) {
      console.log('- Add JWT_SECRET to .env');
    }
    if (warnings.includes('MONGODB_URI looks like a placeholder.')) {
      console.log('- Replace the placeholder MongoDB URI with a real Atlas or local connection string');
    }
    if (warnings.includes('JWT_SECRET looks like a placeholder.')) {
      console.log('- Replace JWT_SECRET with a long random string before production');
    }
    console.log('- For a quick local DB: `docker run -d -p 27017:27017 --name mongo mongo:6`');
    console.log('- To re-run this check: `npm run check-env`\n');
  } else {
    console.log('✅ .env looks OK.');
  }

  return missing.length === 0;
};

if (require.main === module) {
  const ok = checkEnv();
  process.exit(ok ? 0 : 1);
}

module.exports = checkEnv;
