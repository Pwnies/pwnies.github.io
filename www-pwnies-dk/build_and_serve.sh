#!/bin/sh
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`

. ./build-docker.sh

docker run -ti --rm \
    -v $SCRIPTPATH/blog:/blog \
    -p 4000:4000 \
    jekyll \
    jekyll serve --drafts --watch -s /blog
