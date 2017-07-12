---
layout: post
title: "Communication patterns in event driven architecture"
date: 2017-07-12 18:00:00 +100
comments: false
---

## Communication patterns in event driven architecture

<!--excerpt-start-->

I am a huge advocate of using events as the primary means of sharing state
between different services in a microservice architecture - an event driven
architecture. In such a setup, each service emits important events and other 
services listen to events which they are interested in. Each services will then 
use the events to build projections and drive process managers, maintaining 
their own world view.
 
This is a good overall pattern for inter service communication, however there 
is a problem with this approach, if applied blindly all the time: you can end 
up leaking domain knowledge between services and inadvertently coupling the 
services together.

<!--excerpt-end-->

I've had several discussions about this in the past, the most recent started 
from this tweet: https://twitter.com/giveupalready/status/882992529007931392
to save you reading the whole thread, I asserted that, whilst events should 
be the primary mechanism for exchanging state, it is also acceptable for one
microservice to call the public API of another in order to issue a command to
that service.

To illustrate an instance in which I considered this acceptable, I used an 
example from my conference tools project. The project currently consists of 
two distinct services, a ticket booking application and a sponsorship CRM. A
feature which I will want to implement at some point in the future is the 
ability to issue free tickets for sponsors, once they have signed a contract
and paid their invoice. At the present time, it would be necessary for a 
user to manually create the tickets in the ticket booking app, we want to
automate this process.

To see how this ends up leaking knowledge and coupling the services lets 
consider some potential solutions to automate this process. Let's assume
there are 3 levels of sponsorship Gold, Silver and Bronze. Gold receives
5 tickets, Silver gets 3 and Bronze gets 1.

### Solution 1
The sponsorship CRM emits an event once a sponsor has completed their 
on boarding, eg once a contract has been signed and all invoices settled.

The ticketing application is interested in this event so it listens for it,
when received it consults the business rules around number of tickets for 
each sponsorship level and creates the tickets. When tickets are created 
an event is emitted.
 
Finally, the sponsorship CRM listens to for this event and updates the
local state to reflect the fact that tickets have been booked for the 
sponsor.

This is a text book implementation of event driven integration and would 
be perfectly acceptable in other contexts so what is wrong here? It all 
comes down to the business rules about which sponsorship level gets how
many tickets. To me it doesn't really feel right putting that information
inside the ticketing application as it has a much higher affinity with 
sponsors. 

It's not a far stretch to imagine requirements to allow variation by more 
complex rules than just the level of sponsorship eg signup date or to 
allow an admin to change the number of tickets. Each of these requirements
will lead to more information leaking into the ticket service and will see
it listening to more and more events from the sponsorship CRM over time. 

The symbiotic relationship we've created between these two services is one
of a shared kernel, there is a level of interdependency forming between 
the two separate domains so much so that some domain language and constructs
will be shared between them. Any changes in this shared kernel will require
changes to both services producing a maintenance burden.


### Solution 2
An improvement on solution 1 could be similar to this suggestion:
https://twitter.com/rawkode/status/882997094226829313 instead of embedding
the business rules for sponsors ticket allocations in the ticketing 
service, we instead leave them in the sponsorship CRM and emit a new event:
SponsorTicketAllocated. Our ticketing service can then listen to this event
and take appropriate action. The rest proceeds as in solution 1.

This is a much better option and might be the solution we proceed with, 
however when we examine the relationship between our two services via
context mapping, we discover that what we have created is a partnership
relationship.
 
We are dependent on the developers in the ticketing microservice to care
about our event and react to it appropriately and whereas it's much better
than expecting them to implement our business rules in their application
I still think this is an inappropriate amount of coupling between the two
services.

### Some more context
Before I present the solution that I will be implementing and the reasoning 
behind that choice lets consider a bit more background of the applications
in question.

First, the two applications are designed to be stand alone, a conference 
organiser could choose to deploy the ticketing service but not the CRM and
vice versa. Ultimately, this means that adding any logic pertaining to 
sponsors into the ticketing system is questionable at best due to adding
feature bloat that many users don't need.

Second, consider the current method of assigning sponsors tickets: an admin
user would, once the contract has been signed and invoice paid log into the
ticketing system and create the tickets manually, this holds equally true if
they are using our ticketing system or a third parties.

Third, the sponsorship CRM is not the only system which may need to create 
tickets, I have future plans to also create a speaker CRM, which will have
a similar requirement to create tickets. If I were to choose solution 1 or 
2 I would also have to replicate this work for the speaker CRM. 

### Chosen solution
The method by which I have chosen to integrate these two services is for 
the ticketing application to expose an open host service: a defined API
which any other application wishing to integrate with it can use. This 
API will allow a client with sufficient privileges to issue a Create 
Ticket Purchase command. 

Published events will be available via an API but also published to a
message bus for internal systems to consume. It would also be possible at
the cost of some latency to provide a synchronous API for clients who need
to get a result back instantly. The key thing here though, is that the 
ticketing application developers define what the API looks like for clients.

This creates only a one way dependency: the sponsorship application knows
about tickets and the rules for allocating them to sponsors, it also knows
how to call the ticketing application to book tickets. The ticketing 
application however never learns anything about what is booking tickets and
remains tightly focused on it's own domain.

### Conclusions
When working with distributed systems eg microservices it is important to 
consider the types of relationship and amounts of coupling you are 
introducing when integrating two services. Using context mapping to 
explore the relationship you are creating can be useful to highlight things
which don't quite fit.

Just using asynchronous messages as an integration pattern doesn't automatically 
mean you have decoupled two services. Coupling comes in many forms and it is 
important to explore the level of coupling an integration pattern causes and
the trade offs involved in the implementation of that pattern. There is no
one size fits all, so it is important to consider each integration on it's 
own to determine the right relationship to create.

