{
  "name": "medusa-starter-default",
  "version": "0.0.1",
  "description": "A starter for Medusa e-commerce server",
  "author": "nXtCyberNet",
  "license": "MIT",
  "scripts": {
    "seed": "medusa seed -f ./data/seed.json",
    "build": "babel src -d dist --extensions \".ts,.js\"",
    "start": "medusa start",
    "dev": "medusa develop",
    "migrate": "medusa migrations run"
  },
  "dependencies": {
    "@medusajs/medusa": "^1.12.0",
    "@medusajs/medusa-cli": "^1.3.11",
    "@medusajs/event-bus-local": "^1.9.4",
    "@medusajs/cache-inmemory": "^1.8.7",
    "@medusajs/cache-redis": "^1.8.7",
    "@medusajs/event-bus-redis": "^1.8.3",
    "medusa-fulfillment-manual": "^1.1.37",
    "medusa-interfaces": "^1.3.7",
    "medusa-payment-manual": "^1.0.23",
    "typeorm": "^0.3.16"
  },
  "devDependencies": {
    "@babel/cli": "^7.20.0",
    "@babel/core": "^7.20.0",
    "@babel/preset-typescript": "^7.18.6",
    "babel-preset-medusa-package": "^1.1.19"
  }
}
