---
layout: post
title: "Local package development with composer and docker"
date: 2019-07-28 10:00:00 +100
comments: false
---

## Local package development with composer and docker

<!--excerpt-start-->

Recently, most of my spare development time has gone into building the set of tools I use to
run [PHP Yorkshire](https://www.phpyorkshire.co.uk) focused mostly on the ticketing system.
This application is built using Zend framework, and the goal of the project was to provide
a modular system which other conferences could pick and choose components of to use for 
themselves. 

To this end, the main repository only contains a small amount of bootstrapping for the Zend
application, the rest of the code is contained within modules pulled in as composer 
dependencies, this makes development of the modules themselves slightly awkward this post
describes my new setup for making this work seamlessly.

<!--excerpt-end-->

Composer itself provides a few ways to work on packages locally, one option is to checkout
the source to the vendor directory and work on it from there, however this has some limitations
for example only the top level composer.json can define scripts, dev dependencies and dev 
auto loading. It also gives me that slight worry that I'll accidentally blast away my recent 
work whenever I need to do a composer update. 

The second option is to define repositories that point to the locally checked out source on
your machine. This seems like a perfect option; however also comes with some downsides. Firstly
you need to define the repositories locally but you don't want them committed into git as 
users should be installing the packages from packagist, this means you need to add the repositories
manually upon checkout and remember not to commit them every time you update the composer.json
It also means that if you commit your composer.lock file, you will break the install command
for anyone who doesn't have the same repository config as you.

The second downside is slightly more subtle, when composer uses a local repository it has
two modes of operation, the preferred option is to symlink the package from where it resides
on your machine into the vendor directory the other option is to copy the code into the 
vendor directory, while much less convenient for quick testing, when using docker it's the
first option which will cause you more issues.

Local development using docker containers will usually involve mounting code into a docker
image so that when you change it locally it updates inside the container; you can then 
refresh your browser or rerun your tests to see the effect immediately. However when composer
sym links a library; that sym link is usually invalid once mounted into a docker container
as it resolves according to the container's file system not that of the host.

To get around these issues I wrote a couple of utility scripts.  
  
The first script is built to solve the first issue having to manually edit the composer json
file with your locally checked out repositories. The solution allows you to add local overrides
to any part of the composer file, so in addition to the repositories you could add config
for PHP modules you don't have locally but do have inside your development + production 
environments or you could change a dependency to a dev-branch dependency for testing purposes

```shell
#!/usr/bin/env bash
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required to support local development of composer packages, please install using your OS package manager before continuing"; exit 1; }
jq -s ".[0] * .[1]" composer.json composer.local.json > composer.dev.json
COMPOSER=composer.dev.json php composer.phar "$@"
rm composer.dev.json
[ -e "composer.dev.lock" ] && rm composer.dev.lock
```

The script requires the jq tool to be installed and should be placed in a directory containing
composer.phar (or edit line 4 to point to your composer install) save it as composer.sh and 
then after creating a custom composer.local.json with your overrides you can invoke the script
in the same way you would composer normally eg `./composer.sh install` 

It works by combining a local composer json (composer.local.json) with the project file and 
creating a composer.dev.json file. It then runs composer with your commands using this combined 
file instead. This has the advantage that the lock file created (composer.dev.lock) will 
not overwrite your project lock file with a setup that only works on your machine.

To handle the issue of symlinks in docker, I extended my existing docker script for bringing
up a development environment. It should be noted, that this script doesn't use docker compose
I've tended to avoid it for my projects as it adds a dependency to the project which doesn't
add a great deal of value given I use k8s in prod. 

```shell 
#!/usr/bin/env bash

NETWORK="network"
APP_CONTAINER="app"
WEB_CONTAINER="web"
BASE_DIR="/var/www/html/"

LINK_VOLUMES=`find vendor/ -type l -xtype d -exec bash -c 'for file in "${@:2}"; do echo -n "-v "; readlink -fn $file; echo -n ":$1$file "; done' bash $BASE_DIR {} +`

docker network create $NETWORK
docker container create --network $NETWORK --name $APP_CONTAINER -v `pwd`:$BASE_DIR $LINK_VOLUMES \
    php:7.2-fpm-alpine3.7
docker container create --network $NETWORK --name $WEB_CONTAINER -p 8103:80 -v `pwd`:$BASE_DIR $LINK_VOLUMES \
    nginx:1.13-alpine nginx -c /var/www/html/config/nginx.conf
    
docker container start $APP_CONTAINER
docker container start $WEB_CONTAINER

```

This script contains a fairly straight forward set of docker commands to create a new network
create an app and web container (php and nginx) and start them up. The "magical" bit is on
the LINK_VOLUMES line. This uses find to search the vendor directory for symlinks which point
to directories, it then loops through them and creates a set of docker volume mount parameters
to separately mount each symlinked directory in the vendor directory as a separate volume
in the container, overriding the symlink in the container's filesystem with a mount containing
the files.