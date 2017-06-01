#!/bin/sh
set -ev
docker build -t tls-proxy .
docker run -p 80:80 -p 443:443 -v /etc/letsencrypt:/etc/letsencrypt -d tls-proxy
