FROM node:18-alpine
WORKDIR /usr/src/app

# Sistem bağımlılıkları
RUN apk add --no-cache openssl

COPY package*.json ./
RUN npm install

# Önce tüm dosyaları (proto dahil) kopyala
COPY . .

# Klasörün kopyalandığını build loglarında görmek için kontrol (opsiyonel)
RUN ls -d proto && ls proto/

RUN npm run build

# Eğer gRPC kodu dist içinde arıyorsa diye kopyalama garantisi
RUN mkdir -p dist/proto && cp proto/*.proto dist/proto/ || true

CMD ["npm", "run", "start:prod"]