
const dotenv = require('dotenv')


try {
  dotenv.config()
} catch (e) {
  console.error("Could not find .env file, using environment variables")
}


const STORE_CORS = process.env.STORE_CORS || "http://localhost:8000,http://localhost:3000"
const ADMIN_CORS = process.env.ADMIN_CORS || "http://localhost:7000,http://localhost:7001"


const DB_HOST = process.env.DB_HOST || "postgres"
const REDIS_HOST = process.env.REDIS_HOST || "redis"

module.exports = {
  projectConfig: {
    
    redis_url: process.env.REDIS_URL || `redis://${REDIS_HOST}:6379`,
    database_url: process.env.DATABASE_URL || `postgres://medusa:medusa_password@${DB_HOST}:5432/medusa`,
    database_type: "postgres",
    store_cors: STORE_CORS,
    admin_cors: ADMIN_CORS,
    jwtSecret: process.env.JWT_SECRET || "your_jwt_secret_here",
    cookieSecret: process.env.COOKIE_SECRET || "your_cookie_secret_here",
    
    upload_dir: process.env.UPLOAD_DIR || "/app/uploads",
  },
  plugins: [
    `medusa-fulfillment-manual`,
    `medusa-payment-manual`,
  ],
}
