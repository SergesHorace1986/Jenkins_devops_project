# ------------------------- Build stage ------------------------- 
FROM node:20 AS build

WORKDIR /app

COPY package*.json .

RUN npm install

COPY . .

# RUN npm run build

# ------------------------ Runtime stage ------------------------
FROM node:20-bullseye

WORKDIR /app

COPY --from=build /app .

RUN apt-get update && apt-get install -y bash git

EXPOSE 3000

CMD ["node", "src/index.js"]