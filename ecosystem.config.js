module.exports = {
  apps: [
    { name: 'api-gateway', script: 'dist/main.js', cwd: './backend/api-gateway', env: { PORT: 7860, NODE_ENV: 'production' } },
    { name: 'user-service', script: 'dist/main.js', cwd: './backend/user-service', env: { PORT: 3001, NODE_ENV: 'production' } },
    { name: 'provider-service', script: 'dist/main.js', cwd: './backend/provider-service', env: { PORT: 3002, NODE_ENV: 'production' } },
    { name: 'order-service', script: 'dist/main.js', cwd: './backend/order-service', env: { PORT: 3003, NODE_ENV: 'production' } },
    { name: 'review-service', script: 'dist/main.js', cwd: './backend/review-service', env: { PORT: 3004, NODE_ENV: 'production' } },
    { name: 'mistral-service', script: 'dist/main.js', cwd: './backend/mistral', env: { PORT: 3005, NODE_ENV: 'production' } },
    { name: 'notification-service', script: 'dist/main.js', cwd: './backend/notification-service', env: { PORT: 3006, NODE_ENV: 'production' } }
  ]
};