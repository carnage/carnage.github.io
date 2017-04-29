---
layout: post
title: "Writing your own Zend Plugin Manager"
comments: false
---

## Writing your own Zend Plugin Manager

<!--excerpt-start-->

The service locator pattern has fallen out of favour, replaced by a preference for direct 
dependency injection via an object's constructor using a factory. However there are times 
when your class may only know the dependency it needs at runtime. In this instance it seems 
that you may have no option but to inject a service locator so that the class can retrieve 
it's own dependency.
 
This is one possible use case for a plugin manager: you can configure it with dependencies 
all of a specific type, based on interface, injecting this constrains the number of services
your class has access to and helps prevent errors. They can also help keep your service config
files under control as you will have less services inside the main service locator.

In this post I'm going to show how easy it is to create your own plugin manager in Zend 
framework.
<!--excerpt-end-->

