# ------------------------- Build stage ------------------------- 
FROM node:20 AS build

WORKDIR /app

COPY package*.json .

RUN npm install

COPY . .

# RUN npm run build

# ------------------------ Runtime stage ------------------------
FROM node:20-alpine

WORKDIR /app

COPY --from=build /app .

RUN apk add --no-cache bash git

EXPOSE 3000

CMD ["node", "src/index.js"]