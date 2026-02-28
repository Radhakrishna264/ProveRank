# ProveRank

## Overview
ProveRank is a Node.js/Express backend API server.

## Project Structure
```
proverank/
├── src/
│   ├── index.js        # Entry point — starts the HTTP server
│   ├── app.js          # Express app configuration (middleware, routes)
│   └── routes/
│       └── index.js    # API route handlers
├── package.json
├── .gitignore
└── README.md
```

## Tech Stack
- **Runtime:** Node.js 20
- **Framework:** Express 5
- **Dev server:** nodemon (via `npm run dev`)
- **Other packages:** cors, morgan, dotenv

## Running the App
- **Development:** `npm run dev` (with nodemon auto-reload)
- **Production:** `npm start` (node directly)

## API Endpoints
- `GET /` — Returns API info (name, status, version)
- `GET /api/health` — Health check endpoint

## Configuration
- Server port: `3000` (set via `PORT` environment variable)
- Server host: `0.0.0.0`

## Workflow
- **Start application** — runs `node src/index.js` on port 3000 (console output)
