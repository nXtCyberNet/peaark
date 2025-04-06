FROM node:18-alpine

WORKDIR /app

# Copy package.json and other dependency files
COPY medusa-app/package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY medusa-app/ ./

# Build the Medusa application
RUN npm run build

# Expose the default Medusa port
EXPOSE 9000

# Set environment variables
ENV NODE_ENV=production

# Start the Medusa server
CMD ["npm", "start"]
