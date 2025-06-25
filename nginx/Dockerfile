FROM nginx:alpine

# Remove default nginx website
RUN rm /etc/nginx/conf.d/default.conf

# Copy nginx configuration
COPY conf.d/default.conf /etc/nginx/conf.d/

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]