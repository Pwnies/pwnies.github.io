#!/bin/sh
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`
URL=gs://www.pwnies.dk

. ./build-docker.sh

mkdir -p $SCRIPTPATH/site

docker run -ti --rm \
    -v $SCRIPTPATH/blog:/blog \
    -v $SCRIPTPATH/site:/site \
    jekyll \
    jekyll build -s /blog -d /site

gsutil -m rsync -dr site $URL
gsutil -m acl ch -R -u AllUsers:R $URL
gsutil web set -m index.html -e 404.html $URL
