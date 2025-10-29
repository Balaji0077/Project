FROM nginx:1.26.0 
RUN rm /usr/share/nginx/html/index.html 
COPY index.html /usr/share/nginx/html/
