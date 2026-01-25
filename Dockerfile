# Use the official Flutter image as the base
FROM ghcr.io/cirruslabs/flutter:latest

# Set the working directory in the container
WORKDIR /app

# Copy the pubspec files and install dependencies first (to take advantage of Docker caching)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the application files
COPY . .

# Ensure all dependencies are fetched
RUN flutter pub get

# Build the Flutter project for web (can be modified for Android/iOS if needed)
RUN flutter build web

# Use a lightweight web server to serve the app
FROM nginx:alpine

# Copy the built web app to the Nginx web directory
COPY --from=0 /app/build/web /usr/share/nginx/html

# Expose port 80 for web traffic
EXPOSE 80

# Start the Nginx server
CMD ["nginx", "-g", "daemon off;"]