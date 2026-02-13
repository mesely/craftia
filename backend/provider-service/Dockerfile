FROM node:18-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
RUN if [ -f "./prisma/schema.prisma" ]; then npx prisma generate; fi
RUN npm run build
CMD ["npm", "run", "start:prod"]