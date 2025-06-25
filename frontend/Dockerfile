# Multi-stage build for React frontend
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY client/package.json ./client/ 2>/dev/null || true

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY client ./client
COPY shared ./shared
COPY *.json *.js *.ts ./

# Remove HQ portal for client deployments
RUN rm -rf client/src/pages/hq 2>/dev/null || true
RUN rm -rf client/src/components/hq 2>/dev/null || true

# Build React application
RUN npm run build

# Production stage - NGINX
FROM nginx:alpine

# Copy built React app to NGINX
COPY --from=builder /app/dist/public /usr/share/nginx/html

# Copy NGINX configuration
COPY nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]