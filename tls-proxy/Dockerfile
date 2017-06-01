FROM nginx:latest
EXPOSE 80
EXPOSE 443

RUN rm /etc/nginx/conf.d/default.conf

COPY conf.d/* /etc/nginx/conf.d/
