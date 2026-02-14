FROM node:18-alpine
RUN apk add --no-cache openssl
RUN npm install -g pm2 @nestjs/cli
WORKDIR /app
COPY . .
RUN cd backend/api-gateway && npm install && npm run build
RUN cd backend/user-service && npm install && npm run build
RUN cd backend/provider-service && npm install && npm run build
RUN cd backend/order-service && npm install && npm run build
RUN cd backend/review-service && npm install && npm run build
RUN cd backend/mistral && npm install && npm run build
RUN cd backend/notification-service && npm install && npm run build
EXPOSE 7860
CMD ["pm2-runtime", "ecosystem.config.js"]