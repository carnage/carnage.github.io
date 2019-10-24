---
layout: post
title: "Deploying OpenCFP on Google Kubernetes Engine"
date: 2019-10-23 19:00:00 +100
comments: false
---

## Deploying OpenCFP on Google Kubernetes Engine

<!--excerpt-start-->

We've recently opened up the call for papers for the 2020 edition of [PHP Yorkshire](https://www.phpyorkshire.co.uk) 
last year, I put a fair amount of effort into modifying OpenCFP to get it to run well on Google Kubernetes Engine, in 
this post I'm going to detail what was done to achieve this as it covers a lot of the steps you may need to take with
your own applications to get them to run in a Docker/Kubernetes environment.

<!--excerpt-end-->

### Assumptions

Before I begin, I am going to set out a few of the things I won't be covering (otherwise this blog post would be a book)
that you will need to sort out yourself. The first is I'm going to assume that you have already setup a Kubernetes cluster
and have a user setup which has privileges to create the resources we need in this post, you will also have setup an Ingress
solution which can route traffic from the internet into your containers (I am personally using a kubernetes version of the
[solution](https://carnage.github.io/2017/08/personal-docker-platform) I documented a couple of years ago). The second 
assumption is that you will have created a database using Cloud SQL, a bucket in cloud storage and an email account you 
can sent email from, you will have stored the credentials in Kubernetes secrets. The final assumption is that should you
be using a different platform eg AWS, you will have done similar things for your provider.

### Requirements

To setup and run an application on kubernetes we need to change a few things from when we were running it in a VPS, Kubernetes
is a platform for running docker containers so the first thing we would need to do is build an OpenCFP Docker container
bringing in the application itself and any customisations we wanted for example to the templates or CSS. Since it is running
inside a docker container and Kubernetes could at any time shutdown that container and move it to a different host, we will
also need somewhere else to store state. OpenCFP requires a database to store data and a location (usually the filesystem 
on the host) to store uploaded speaker profile images.

### Building the Docker containers

To try and keep the docker containers lightweight, I based them on the alpine versions of PHP and nginx, the versions 
were tweaked to ensure that they both used the same alpine version allowing us to take advantage of docker layers when
moving the containers around. My Dockerfile is below

```Dockerfile
FROM composer:latest as composer
ENV COMPOSER_ALLOW_SUPERUSER 1

RUN mkdir /scratch
WORKDIR /scratch

RUN apk add rsync

RUN curl -L https://github.com/opencfp/opencfp/archive/v1.7.0.tar.gz --output opencfp.tar.gz
RUN tar -zxvvf opencfp.tar.gz --strip 1
RUN rm opencfp.tar.gz
RUN /usr/bin/composer install
RUN /usr/bin/composer require superbalist/flysystem-google-storage

ADD assets /root/assets
ADD views /root/views
RUN rsync -r /root/views/ /scratch/resources/views/
RUN rsync -r /root/assets/ /scratch/web/assets/

FROM nginx:1.13-alpine as nginx

COPY --from=composer /scratch/web/assets /var/www/html/web/assets
ADD nginx.conf /etc/nginx/nginx.conf

FROM php:7.2-fpm-alpine3.7 as php

RUN docker-php-ext-install pdo_mysql

RUN apk add --no-cache libpng libjpeg freetype
RUN apk add --no-cache --virtual .build-deps freetype-dev libjpeg-turbo-dev libpng-dev 
RUN docker-php-ext-configure gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr 
RUN docker-php-ext-install gd 
RUN apk del .build-deps

COPY --from=composer /scratch /var/www/html
ADD opencfp.cloud.config.yml /var/www/html/resources/config/config_production.yml
RUN chown -R www-data /var/www/html
```

This Dockerfile takes advantage of the multistage build to use a composer container to install the composer dependencies,
add a custom dependency on flysystem's google cloud bucket adaptor which we need for storing profile images, 
and also copy over any customisations we've made to assets and views into the OpenCFP directory before building our 
production containers. The rest of the Dockerfile ensures all the PHP extensions we need are present and copies in 
config files from the Docker repo, not all of the config is here some that is expected to change more frequently is 
placed in a Kubenetes config map and dymaically loaded into the container 

The opencfp.cloud.config.yml file is shown below, it's main purpose is to pull credentials from environment variables
and setup the google cloud bucket flysystem adaptor as an override to the default filesystem one. If you recall, in the
requirements section we set out the need to not store anything in the container so using some sort of cloud storage is
essential. This manages storage of images in google cloud bucket but as OpenCFP generates urls for uploaded images which
assume storage on the filesystem, we will still have a bit of work to do to serve them back to visitors.

```yaml
imports:
  - { resource: config.yml }

services:
    acme.google_storage_client:
        class: Google\Cloud\Storage\StorageClient
        arguments:
            - projectId: "%env(GOOGLE_CLOUD_PROJECT_ID)%"

    acme.google_storage_bucket:
        class: Google\Cloud\Storage\Bucket
        factory: 'acme.google_storage_client:bucket'
        arguments:
            - '%env(GOOGLE_CLOUD_BUCKET)%'

oneup_flysystem:
  adapters:
    uploads:
      googlecloudstorage:
        client: acme.google_storage_client
        bucket: acme.google_storage_bucket
        prefix: "uploads/"

  filesystems:
    uploads:
      adapter: uploads
      alias: upload_filesystem
      visibility: public

parameters:
  database.host: '127.0.0.1'
  database.database: '%env(DB_NAME)%'
  database.user: '%env(DB_USER)%'
  database.password: '%env(DB_PASS)%'
  
  mail.host: '%env(MAIL_HOST)%'
  mail.port: '%env(MAIL_PORT)%'
  mail.username: '%env(MAIL_USER)%'
  mail.password: '%env(MAIL_PASS)%'
  mail.encryption: '%env(MAIL_ENCRYPTION)%'
  mail.auth_mode: '%env(MAIL_AUTH_MODE)%'

```

In the Dockerfile I've labeled the two production containers as nginx and php, we need this when building the containers
as by default docker will build a multistep build and throw away the intermediate containers. To counter this, we need to 
build the docker containers twice telling it the second time to stop after building the nginx container so that we get both
containers tagged. This second build is lightning fast since it uses the cached layers from the previous PHP build.

This snippet of shell script first defines the image tag by using git tags and commits and the builds the php container
followed by the nginx container and pushes both to your registry. This is part of a build pipeline, but you could run
this locally. 

```shell script
    export CI_REGISTRY_IMAGE="<your docker repository>"
    export IMAGE_VERSION=$(git describe --tags)
    docker build -t $CI_REGISTRY_IMAGE"/php:"$IMAGE_VERSION .
    docker push $CI_REGISTRY_IMAGE"/php:"$IMAGE_VERSION
    docker build --target nginx -t $CI_REGISTRY_IMAGE"/nginx:"$IMAGE_VERSION .
    docker push $CI_REGISTRY_IMAGE"/nginx:"$IMAGE_VERSION
```

### Profile Images

Profile images were a bit of a challenge, one option was to add a new feature into OpenCFP to allow customisation of
image paths when rendered into the HTML, however this seemed to be a much bigger job than adding flysystem support as it 
would need to know in advance about the different adaptors and how to render out a URL for different cloud systems or 
have some mechanism for loading the files from the cloud storage and serving them via PHP.

Instead I opted to manage this using nginx. Since OpenCFP in an unmodified configuration saves all images to /uploads
and then uses this path when rendering URLS, I was able to setup a location block in nginx for /uploads and intercept 
it before it got to PHP and redirect it to the location in the cloud that the image was stored at completely transparently.

Taking inspiration from [this blog post](https://zihao.me/post/hosting-static-website-with-kubernetes-and-google-cloud-storage/) 
I created the following nginx config

``` 
user  nginx;
worker_processes  2;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    resolver 8.8.8.8;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;

    keepalive_timeout  65;

    proxy_cache_path           /tmp/ levels=1:2 keys_zone=gcs_cache:10m max_size=500m inactive=60m use_temp_path=off;

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name localhost;

        index index.php index.html;
        error_log  /var/log/nginx/error.log;
        access_log /var/log/nginx/access.log;
        root /var/www/html/web;

        location / {
            try_files $uri /index.php?$args;
        }

        location /uploads/ {
            # contains uri for proxy
            include       /etc/nginx/nginx.upstream.conf;

            proxy_http_version     1.1;
            proxy_set_header       Connection "";
            proxy_set_header       Authorization "";
            proxy_set_header       Host storage.googleapis.com;
            proxy_hide_header      X-GUploader-UploadID;
            proxy_hide_header      x-goog-generation;
            proxy_hide_header      x-goog-metageneration;
            proxy_hide_header      x-goog-stored-content-encoding;
            proxy_hide_header      x-goog-stored-content-length;
            proxy_hide_header      x-goog-meta-goog-reserved-file-mtime;
            proxy_hide_header      x-goog-hash;
            proxy_hide_header      x-goog-storage-class;
            proxy_hide_header      Accept-Ranges;
            proxy_hide_header      Alt-Svc;
            proxy_hide_header      Set-Cookie;
            proxy_ignore_headers   Set-Cookie;
            proxy_intercept_errors on;
            proxy_cache            gcs_cache;
            proxy_cache_lock       on;
            proxy_cache_revalidate on;
            add_header             X-Cache-Status $upstream_cache_status;
            add_header             Cache-Control "max-age=31536000";

            proxy_pass $uploads$uri; 
        }

        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass localhost:9000;
            fastcgi_index index.php;
            include /etc/nginx/fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $fastcgi_path_info;
        }
    }
}

``` 

There are a few areas to draw your attention to, outside the standard setup you would expect for a PHP website the first
is the proxy cache path line, this sets up local caching of the images inside nginx which will speed up requests in the
future, you could tweak the max size, cache time and location if you wanted but I've found these settings to be adequate.

The next part to look at is the `include       /etc/nginx/nginx.upstream.conf;` line, the purpose of this is to allow us
to configure the location of the google cloud bucket via environment variables at build time. You will see this file as 
part of the Kubernetes config map later on.  

The rest of the uploads section is there to rewrite the request coming from the end user into one which google cloud
storage will respond to and to clean up the response that we then send back to the end user; hiding the fact that the
file really came from Google Cloud Bucket. Although this isn't hugely important here, as the bucket is configured with
public access (profile images are submitted to become public, so additional access control over and above the randomly
generated URL seems unnecessary) for other systems you may want to talk to a private bucket and conceal the signed URL
required for this from the user.

This may seem a little complex a solution and you might wonder why I didn't mount a Kubernetes persistent volume into 
the containers in order to store the profile images in. The main reason this didn't really work is that at the time, it
wasn't possible to mount a google provided persistent volume to more than one container if any container could write to
it. As nginx and php containers would both need access to the storage (and additional PHP containers should this be scaled
up to more nodes) this wasn't a viable option.

### Deploying to Kubernetes
Once you have the docker containers, the next step is to get them onto Kubernetes. For this purpose I created a Kubefile
this is nothing specifically fancy it's a kubernetes manifest which contains some environment variables from the build
server which is run through envsubst to create a manifest that can be sent to the kubernetes api. This file looks a bit
like this:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: opencfp-config
data:
  nginx.upstream.conf: | 
    set ${D}uploads $GOOGLE_CLOUD_STORAGE;
  opencfp-config.yml: |
    application:
      title: PHP Yorkshire
      url: https://cfp.phpyorkshire.co.uk
      email: infophp@yorkshire.co.uk
      eventurl: https://www.phpyorkshire.co.uk
      event_location: York, UK
      enddate: Nov. 17th, 2019
      show_submission_count: false
      airport: MAN
      arrival: 2020-04-03
      departure: 2020-04-04
      secure_ssl: true
      online_conference: false
      date_format: d/m/Y
      date_timezone: "UTC"
      coc_link: https://2017.phpyorkshire.co.uk/information/code-of-conduct.html
      show_contrib_banner: false
      venue_image_path: /assets/img/venue.jpg

    log:
      level: error

    talk:
      categories:
        api: APIs (REST, SOAP, etc.)
        architecture: Architecture
        database: Database
        development: General PHP Development
        devops: Devops
        framework: Framework
        javascript: JavaScript/CSS
        personal: Personal Skills
        security: Security
        testing: Testing
        uiux: UI/UX
        other: Other
      levels:
        entry: Entry level
        mid: Mid-level
        advanced: Advanced
      types:
        talk: Talk (50 mins)
        taster: Tutorial (1/2 day)
        deepdive: Tutorial (full day)

    opencfpcentral:
      sso: off
      clientId: 0
      clientSecret: 0
      authorizeUrl: https://www.opencfpcentral.com/oauth/authorize?
      redirectUri: http://localhost/sso/redirect
      resourceUri: https://www.opencfpcentral.com/api/user
      tokenUrl: https://www.opencfpcentral.com/oauth/token
        
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: cfp
spec:
  replicas: 1
  selector:
    matchLabels:
      name: cfp
  template:
    metadata:
       labels:
         name: cfp
    spec:
      volumes:
        - name: config
          configMap:
            name: opencfp-config
        - name: cloudsql-instance-credentials
          secret:
            secretName: cloudsql-instance-credentials
        - name: cfp-cloudstorage-credentials
          secret: 
            secretName: cfp-cloudstorage-credentials
      containers:
        - name: cfp-mysql
          image: gcr.io/cloudsql-docker/gce-proxy:1.11
          imagePullPolicy: Always
          command:
            - /cloud_sql_proxy
            - -instances=$CLOUDSQL_INSTANCE_NAME=tcp:3306
            - -credential_file=/secrets/cloudsql/credentials.json
          volumeMounts:
          - name: cloudsql-instance-credentials
            mountPath: /secrets/cloudsql
            readOnly: true

        - image: $CI_REGISTRY_IMAGE/php:$IMAGE_TAG
          name: cfp
          imagePullPolicy: Always
          volumeMounts:
            - mountPath: /var/www/html/config/production.yml
              name: config
              subPath: opencfp-config.yml
            - mountPath: /var/secrets/gcs 
              name: cfp-cloudstorage-credentials
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/secrets/gcs/cloud-storage.json
            - name: TRUST_PROXIES
              value: "true"
            - name: GOOGLE_CLOUD_PROJECT_ID
              value: "phpyscfp"
            - name: GOOGLE_CLOUD_BUCKET
              value: "profile-images"
            - name: DB_NAME
              valueFrom:
                secretKeyRef:
                  name: mysql-cfp-credentials
                  key: username
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: mysql-cfp-credentials
                  key: username
            - name: DB_PASS
              valueFrom:
                secretKeyRef:
                  name: mysql-cfp-credentials
                  key: password
            - name: MAIL_HOST
              value: "smtp.gmail.com"
            - name: MAIL_USER
              valueFrom:
                secretKeyRef:
                    name: email-credentials
                    key: username
            - name: MAIL_PASS
              valueFrom:
                secretKeyRef:
                    name: email-credentials
                    key: password
            - name: MAIL_PORT
              value: "465"
            - name: MAIL_ENCRYPTION
              value: "ssl"
            - name: MAIL_AUTH_MODE
              value: "plain"

        - image: $CI_REGISTRY_IMAGE/nginx:$IMAGE_TAG
          name: cfp-nginx
          imagePullPolicy: Always
          volumeMounts:
            - mountPath: /etc/nginx/nginx.upstream.conf
              name: config
              subPath: nginx.upstream.conf
      imagePullSecrets:
        - name: deployment-agent
---
apiVersion: v1
kind: Service
metadata:
   name: cfp
spec:
   selector:
     name: cfp
   ports:
     - port: 80
       targetPort: 80
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: cfp
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
    - host: cfp.phpyorkshire.co.uk
      http:
        paths:
          - backend:
              serviceName: cfp
              servicePort: 80
```

Breaking this down, there are four main items in this manifest, the first contains the config maps one for OpenCFP and 
the other for nginx the OpenCFP config map changes the things we may want to alter more frequently eg the cfp end date
(as opposed to the infrastructure setup config we included in the image) where as the nginx file is used to inject the
cloud storage bucket url from a local environment variable. You will also notice the odd ${D} this is a workaround to 
use a literal $ inside the file and not have it replaced by envsubst (The D env var is set to $ in the deployment script)

The next section contains the deployment config, it lists out three containers which will be included in each Kubernetes
pod for this deployment. 

The first is a cloud SQL proxy container, this container creates an encrypted tunnel between your 
kubernetes cluster and Google Cloud SQL allowing you to connect to localhost in your app but be routed to your Cloud SQL 
instance externally. 

The next container is the application container, it has a lot of environment variables passed into it
pulling credentials for email, DB and Cloud Bucket from Kubernetes secrets, some of these variables are hard coded in 
the file others are pulled in from environment variables on the build server. Probably the only one that needs explanation 
is the TRUST_PROXIES variable - this instructs OpenCFP to trust the headers set by traefik and google's load balancer 
when determining client IP address and SSL status (In my setup, Traefik terminates the SSL connection so OpenCFP thinks
you are using plain http and generates URLs to match that)

The final container is our nginx container, probably the simplest definition as it only needs to mount in the config file
containing the google cloud bucket url.

The final two parts of the Kubernetes manifest define a service which points to the deployment and creates an ingress 
rule which will be picked up by Traefik to route traffic for cfp.phpyorkshire.co.uk into this container. 

### Conclusion

This is an outline of how I modified OpenCFP to work on Kubernetes and used various cloud services provided by google to
handle persistent storage. There are still a few minor things to work out; currently I cannot scale the app container to
more than one node since there isn't anything in place to share session data between containers. If I wanted to do this 
I would need to take similar actions as I did for profile images and use a different adapter for session storage pushing 
them into mysql or some other external storage. 

The various issues I solved here are common to many different web applications, including custom ones you may have build
so although this describes a niche project you should be able to adapt this to your own projects and get them running 
on Kubernetes. 