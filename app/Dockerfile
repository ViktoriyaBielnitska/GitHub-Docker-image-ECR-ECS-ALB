# Використовуємо легкий офіційний образ NGINX
FROM nginx:alpine

# Копіюємо власну сторінку в стандартну директорію NGINX
COPY index.html /usr/share/nginx/html/index.html

# Декларуємо порт 80
EXPOSE 80

# Тримаємо NGINX у foreground, щоб контейнер не завершувався
CMD ["nginx", "-g", "daemon off;"]
