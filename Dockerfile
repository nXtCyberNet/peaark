FROM node:18-alpine

WORKDIR /app

COPY medusa-app/package*.json ./
RUN npm install

COPY medusa-app/ ./

EXPOSE 9000
ENV NODE_ENV=production

CMD ["npm", "start"]
