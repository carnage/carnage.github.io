---
layout: post
title: "Personal project hosting with docker"
date: 2017-08-28 18:00:00 +100
comments: false
---

## Personal project hosting with docker

<!--excerpt-start-->

Docker has become one of the most popular technologies of the past couple
of years, with a lot of companies investing in using it for some or all 
of their development work, with many now using it for their production 
infrastructure as well. 

The convenience provided by docker for deploying applications makes it 
attractive to use for personal projects, but there is a lot of complexity
you need to manage a docker cluster, I've been steadily working on this 
and this post is the first of many documenting my work.

<!--excerpt-end-->

My requirements for this hosting platform are quite demanding and I've not yet 
implemented all of them. In brief, what I am after is the same level of platform
that many of my clients use for their production applications but on a smaller
and cheaper level. Unlike many of their platforms, it also needs to be capable
of hosting multiple different sites, potentially using very different technologies
which is why I initially looked to Docker as the basis for this platform.

A list of my desired features:
- Automated builds including test runs, ideally triggered on git merge/push  
- One click deploy to production or beta environments
- One click rollback
- Multi site hosting ideally with shared infrastructure such as databases
- Automatic SSL setup
- Automated backups of all areas of persistence 
- Automated creation of servers (infrastructure)
- Scaling and fault tolerence over multiple nodes (global distribution is less important here)
- Monitoring and alerts

So far, I've made good progress on about half of the list, in the remainder of 
this post I will describe the setup of the underlying docker swarm instance and
of the multi site configuration with automatic SSL.

### Docker setup

The initial docker setup is straight forward, I used docker machine to provision 
a single Digital Ocean droplet (other cloud providers are available) and then 
manually enabled swarm on the instance, creating a single node swarm (for some reason
docker machine was unable to do this automatically for me). Using swarm on a single 
node allows us to make use of some of the swarm only features and makes it easier to
scale out later once the number of sites or desire for fault tolerance exceeds what
a single node can provide.

Each of my apps would be contained in a single docker image or set of images defined
by a docker compose file. I won't go into detail about how I build my docker images
during this article and will assume you are able to create your own containers for
your applications.

### Multi site setup

In order to allow multiple sites to inhabit a single node, I needed to setup a 
front proxy which could direct traffic to the correct docker container based on
the hostname. My initial attempts at this was a quite complex setup using caddy
and docker-template however I abandoned this once I discovered Traefik. 

[Traefik](https://traefik.io/)
is a front proxy written in go which seems to be purpose made for exactly this
use case. Not only can it interface directly into docker to pick up new containers
and route to them automatically but it will also handle the SSL certificates 
by automatically getting a certificate from let's encrypt.

There are two main parts to getting this all working properly; the first is setting
up traefik itself and the second is ensuring it knows what to do with any container 
you decide to run.

My traefik configuration doesn't deviate too much from the standard config file 
supplied by traefik. The important bits to look at are the docker config, the 
lets encrypt config and the entry points config.

For the docker config I decided it was easiest to mount the unix socket into the
container rather than mess around using TLS certificates on a TCP socket, I may
revisit this option at some point, especially once I start to scale out the cluster.
The docker portion of my config looks like this:

```toml
[docker]

# Docker server endpoint. Can be a tcp or a unix socket endpoint.
#
# Required
#
endpoint = "unix:///var/run/docker.sock"

# Default domain used.
# Can be overridden by setting the "traefik.domain" label on a services.
#
# Required
#
domain = "docker.localhost"

# Enable watch docker changes
#
watch = true

# Ensure you enable swarm mode 
#
swarmmode = true
```

Lets encrypt is also fairly straight forward to enable, my configuration currently 
lacks a volume to store the certificates, this is something I will be resolving as
soon as I have time.

```toml
[acme]

# Email address used for registration
#
# Required
#
email = "Your@email.com"

# File or key used for certificates storage.
# WARNING, if you use Traefik in Docker, you have 2 options:
#  - create a file on your host and mount it as a volume
#      storageFile = "acme.json"
#      $ docker run -v "/my/host/acme.json:acme.json" traefik
#  - mount the folder containing the file as a volume
#      storageFile = "/etc/traefik/acme/acme.json"
#      $ docker run -v "/my/host/acme:/etc/traefik/acme" traefik
#
# Required
#
storage = "acme.json" # or "traefik/acme/account" if using KV store

# Entrypoint to proxy acme challenge/apply certificates to.
# WARNING, must point to an entrypoint on port 443
#
# Required
#
entryPoint = "https"

# Enable certificate generation on frontends Host rules. This will request a certificate from Let's Encrypt for each frontend with a Host rule.
# For example, a rule Host:test1.traefik.io,test2.traefik.io will request a certificate with main domain test1.traefik.io and SAN test2.traefik.io.
#
# Optional
#
OnHostRule = true
```

Finally the entry points part of the config, this is setup to automatically redirect http to https,
you can turn this off and only serve https by removing the relevant lines.

```toml
# this line should be at the top of the file
defaultEntryPoints = ["http", "https"]
# Entrypoints, http and https
[entryPoints]

# http should be redirected to https
[entryPoints.http]
address = ":80"
[entryPoints.http.redirect]
entryPoint = "https"

# https is the default
[entryPoints.https]
address = ":443"
[entryPoints.https.tls]
```

All of the above should be edited into the default config file, leaving the rest as it is. Save it
as `config.toml` I originally had a custom image which descended from the official image and added
this config in the correct place this had the disadvantage of needing to rebuild the image every 
time a config change was needed. My latest strategy now relies upon using the new configs feature
in docker swarm, this allows you to dynamically mount a config file into an image similar to a 
volume but without having to worry about putting the file on each host to be able to mount it.

For more detail on all the configuration options, you can read the the
[traefik documentation](https://docs.traefik.io/configuration/commons/)

To spin it all up I used the following docker compose file with the command
`docker stack deploy -c docker-compose.yml load_balancer` 

```yaml
# version must be > 3.3 to support configs
version: "3.3"
services:
  traefik:
    image: traefik:1.2
    ports:
      - target: 80
        published: 80
        protocol: tcp
        mode: ingress # ingress mode makes a globally available port over all swarm nodes
      - target: 443
        published: 443
        protocol: tcp
        mode: ingress
        # this enables access to the web ui, you may wish to remove it once you've confirmed 
        # everything is working properly
      - target: 8080
        published: 8080
        protocol: tcp
        mode: ingress
    volumes:
      # mount the docker socket into the container, not required if you use a TCP socket
      # note it's read only
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    networks:
      - public
      - frontend
    configs:
      - source: trafek_config
        target: /etc/traefik/traefik.toml
        uid: '1'
        gid: '1'
        mode: 0700

networks:
  # the public network is for any containers which have public mapped ports
  public:
  # the frontend network is for your application containers (or the web facing part of)
  frontend:

configs:
  trafek_config:
    file: ./config.toml
```

Once you've brought it up, you can use standard docker commands to verify it is running and you
should also be able to access the web ui on port 8080. This docker compose file is missing a 
volume for the ssl certificates, you should probably add one for production usage.

### Your first application

So far, we've not got anywhere with actually hosting a project. That is our next step. I suggest
you start with a single container application and get that working properly first - ideally it
should be one without persistence requirements as persistence requires some special handling that
I do not yet have a solution I'm happy with.

You will need to build you application's docker container and host it on a registry, it is easier
if this image is public for the time being until I cover using private registries in a future post.

To deploy an application and have it automatically picked up by Traefik we again use the command
`docker stack deploy -c docker-compose.yml my_app` with a compose file such as:

```yaml
version: "3.3"
services:
  webapp:
    image: my_application_image:latest
    networks:
      - frontend
    deploy:
      labels:
        # tell traefik to route to thie container
        - "traefik.enable=true"
        # a name for this application in traefik, must be unique
        - "traefik.backend=my_app"
        # hostnames to route to this container (and retrieve ssl certs for)
        - "traefik.frontend.rule=Host:myapplication.com, www.myapplication.com"
        # network this container is attached to (global name)
        - "traefik.docker.network=load_balancer_frontend"
        # port this container listens on
        - "traefik.port=80"

networks:
  frontend:
    # import our frontend network from the load balancer service
    external:
      name: load_balancer_frontend
```

Once you have that container up and running, in a few mins traefik should retrieve an SSL 
certificate for it and begin routing to it. If you are running this locally, you'll get a 
certificate error as Let's encrypt won't issue a certificate for you. In this case traefik
will default back to using it's own self signed certificate.

### Conclusion

This post lays out the basics for a multi site hosting platform using docker, there is still
a long way to go to meet the goals I set out for this project but this should be enough to 
get you going if you want to do something similar. 

In the next post on this, I will show an example of how I configured automated builds and 
deployments using gitlab CI and also how you can use gitlab's built in private docker registry
for your application images.

The next step for me in building this infrastructure out is to handle persistence of data and
automatic backups, currently the sites I have deployed on this have no need for persistence as
such no requirement exists however if I want to eventually migrate all of my hosting to this 
platform it is something I need to tackle.