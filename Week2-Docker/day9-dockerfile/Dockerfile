FROM node:20-alpine
WORKDIR /app
ARG APP_VERSION=1.0
ENV PORT=3000 APP_ENV=dev APP_VERSION=$APP_VERSION
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
EXPOSE 3000
USER node
CMD ["node", "server.js"]
