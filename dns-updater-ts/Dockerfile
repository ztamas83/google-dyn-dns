# Use an official Node.js runtime as a parent image
FROM node:22-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install any needed packages
RUN npm install

# Bundle app source
COPY . .

# Compile TypeScript
RUN npm run build

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Define environment variables
ENV GCP_PROJECT your-gcp-project
ENV GCP_DNS_ZONE_NAME your-dns-zone-name
ENV GCP_DNS_DOMAIN your-dns-domain.com
ENV USERNAME your-username
ENV PASSWORD your-password

# Run the app when the container launches
CMD ["node", "dist/index.js"]
