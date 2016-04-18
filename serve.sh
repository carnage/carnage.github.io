#!/bin/sh

docker run --rm -ti -v $(pwd):/app -p 4000:4000 gekkie/docker-gh-pages