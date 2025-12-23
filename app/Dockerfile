# Базовий образ NGINX
FROM nginx:latest

# Встановлюємо просту сторінку "Hello World"
RUN echo '<!DOCTYPE html><html><head><title>Hello</title></head><body><h1>Hello from ECS!</h1></body></html>' > /usr/share/nginx/html/index.html

# Переконуємося, що NGINX слухає на 0.0.0.0:80
RUN sed -i 's/listen       80;/listen 0.0.0.0:80;/' /etc/nginx/conf.d/default.conf

# Expose порт для ECS
EXPOSE 80

# Запускаємо NGINX у foreground (не background)
CMD ["nginx", "-g", "daemon off;"]
