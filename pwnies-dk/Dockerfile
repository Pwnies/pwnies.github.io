FROM nginx:latest
EXPOSE 80

RUN rm /etc/nginx/conf.d/default.conf

COPY conf.d/* /etc/nginx/conf.d/
