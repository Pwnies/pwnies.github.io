FROM debian:jessie

RUN apt-get update && apt-get -y install jekyll
RUN useradd -m blog

USER blog
WORKDIR /home/blog

