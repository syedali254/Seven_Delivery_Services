# Use Nginx to serve the Flutter Web build
FROM nginx:stable-alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy the build/web folder from your project to the nginx html folder
# Note: You must run 'flutter build web --release' before building this docker image
COPY build/web /usr/share/nginx/html

# Custom nginx config to handle Flutter routing if needed
# (Optional: for more complex apps you'd add a custom nginx.conf here)

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
