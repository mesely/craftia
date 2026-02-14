FROM node:18-alpine
WORKDIR /usr/src/app
RUN apk add --no-cache openssl
COPY package*.json ./
RUN npm install
COPY . .
RUN if [ -d "./prisma" ]; then npx prisma generate; fi
RUN npm run build
# Proto kopyalama garantisi
RUN mkdir -p dist/proto && find src -name "*.proto" -exec cp {} dist/proto/ \; || true
CMD ["npm", "run", "start:prod"]
