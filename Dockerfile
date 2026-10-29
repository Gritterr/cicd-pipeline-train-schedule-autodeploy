# Train Schedule app (Node.js + Express), listening on port 8080.

# Stage 1: install all dependencies and run the unit tests. If a test fails,
# the build fails and Jenkins never pushes or deploys the image.
FROM node:20-alpine AS build
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm test && npm prune --omit=dev

# Stage 2: the image that runs, with production dependencies only.
FROM node:20-alpine
WORKDIR /usr/src/app
ENV NODE_ENV=production
COPY --from=build /usr/src/app ./
USER node
EXPOSE 8080
CMD ["node", "./bin/www"]
