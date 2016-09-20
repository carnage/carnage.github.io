#!/bin/sh

docker run --rm -ti -v $(pwd):/srv/jekyll -p 4000:4000 jekyll/jekyll:pages