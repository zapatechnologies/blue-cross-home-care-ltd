FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy backend source
COPY server ./server
COPY shared ./shared
COPY *.json *.js *.ts ./

# Build backend
RUN npx esbuild server/index.ts --platform=node --packages=external --bundle --format=esm --outdir=dist

EXPOSE 5000

CMD ["node", "dist/index.js"]