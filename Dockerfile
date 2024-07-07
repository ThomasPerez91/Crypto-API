FROM node:20-alpine3.18 AS base

RUN apk --no-cache add curl
RUN corepack enable

# All deps stage
FROM base AS deps
WORKDIR /app
ADD package.json package-lock.json ./
RUN npm install --ignore-scripts

# Production only deps stage
FROM base AS production-deps
WORKDIR /app
ADD package.json package-lock.json ./
RUN npm install --ignore-scripts

# Build stage
FROM base AS build
WORKDIR /app
COPY --from=deps /app/node_modules /app/node_modules
ADD . .

RUN node ace build

# Production stage
FROM base

ENV NODE_ENV=production
ENV LOG_LEVEL=debug
ENV CACHE_VIEWS=false
ENV SESSION_DRIVER=cookie
ENV PORT=$PORT

WORKDIR /app
COPY --from=production-deps /app/node_modules /app/node_modules
COPY --from=build /app/build /app

# Expose port
EXPOSE $PORT

# Start app
CMD node bin/console.js migration:run --force && node bin/server.js