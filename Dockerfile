FROM node:lts-alpine

WORKDIR /app

# Copy only package files first (better caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy only required source code (not entire context)
COPY public ./public
COPY src ./src

EXPOSE 3000

CMD [ "npm", "start" ]
