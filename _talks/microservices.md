---
layout: talk
title: "Microservices vs The Distributed Monolith"
comments: false
slides: cbe30b3bb54a44a39fbd9ea743b49cca
givenAt:
    - location: "PHP Central Europe"
    - location: "PHP North West"
      url: "https://conference.phpnw.org.uk/phpnw17/speakers/chris-riley/"
      date: "01-10-2017"
    - location: "PHP Serbia"
    - location: "PHP Minds"
    - location: "PHP NE"
    - location: "PHP NW"
    - location: "PHP Scotland"
      slides: "https://speakerdeck.com/carnage/microservices-vs-the-distributed-monolith"
---
When faced with a challenging legacy code base, tightly coupled and void of discernible structure: a big ball of mud, it is common to decide to refactor this monolith to a microservice architecture to separate concerns and split the codebase up, however without any clear boundaries you are in danger of creating a distributed big ball of mud. 

You may recognise the symptoms of a distributed ball of mud: a large unfocused 'common' library shared between multiple services; performance issues as your front end makes calls to multiple back end API's to serve a single request; dependency hell on deployments as you have to release multiple code bases simultaneously and uptime issues as a single microservice going down brings down your entire application.

In this talk I'm going to cover some of the common pitfalls you might encounter when building a microservice architecture and show you how to use an event driven architecture to build truly scalable microservices.