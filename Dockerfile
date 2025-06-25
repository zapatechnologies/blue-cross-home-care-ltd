# Multi-stage Dockerfile optimized for Google Cloud Run
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Remove development dependencies
RUN npm prune --production

# Production stage optimized for Cloud Run
FROM node:18-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S careconnect -u 1001

WORKDIR /app

# Copy built application from builder stage
COPY --from=builder --chown=careconnect:nodejs /app/dist ./dist
COPY --from=builder --chown=careconnect:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=careconnect:nodejs /app/package*.json ./
COPY --from=builder --chown=careconnect:nodejs /app/client/dist ./client/dist

# Remove HQ portal files for client deployments
RUN rm -rf client/dist/pages/hq 2>/dev/null || true
RUN rm -rf client/dist/components/hq 2>/dev/null || true

# Switch to non-root user
USER careconnect

# Expose the port that Cloud Run expects
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "dist/server/index.js"]