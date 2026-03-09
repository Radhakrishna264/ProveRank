// ProveRank — Security Middleware (Phase 8.1 Step 2, 4, 7)
// Helmet + NoSQL Sanitize + XSS Clean

const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const xssClean = require('xss-clean');

const applySecurityMiddleware = (app) => {
  // Step 2: Helmet — HTTP security headers
  // XSS, Clickjacking, CSRF, Content-Type sniffing protection
  app.use(helmet({
    contentSecurityPolicy: false, // API server — disable CSP
    crossOriginEmbedderPolicy: false
  }));

  // Step 4: NoSQL Injection prevention
  // Removes $ and . from request body, query, params
  app.use(mongoSanitize({
    replaceWith: '_',
    onSanitize: ({ req, key }) => {
      console.warn(`⚠️  NoSQL Injection attempt blocked: ${key}`);
    }
  }));

  // Step 7: XSS Clean — strips malicious HTML/scripts from inputs
  app.use(xssClean());

  console.log('✅ Security middleware active: Helmet + NoSQL Sanitize + XSS Clean');
};

module.exports = { applySecurityMiddleware };
