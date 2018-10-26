---
layout: post
title: "Events are forever... until they're not."
date: 2018-10-26 10:00:00 +100
comments: false
---

## Events are forever... until they're not.

<!--excerpt-start-->

One of the founding principals of event sourcing is that events are forever, they
cannot change or be deleted. You need to keep the entirety of history so that you
can derive business value from rebuilding projections or adding new ones to answer
new questions or build new features. 

In a post GDPR world, this comes into conflict with users being able to assert 
control over their personal data you are processing. User requests are not the 
only reason you may need to delete or modify events - a change in requirements may 
lead to drastic changes in your model and a need to rethink the events in your 
system. 

In this post I'll explore some of the ways you can manage these situations.

<!--excerpt-end-->

If it's not obvious from the title, my view on this is that event sourcing does not
mean that you have to keep your events forever. Just like any other computer system
or database, the data contained in events should only be retained as long as they
have value to the business. If you are making major changes to your data model or
risking a huge fine for keeping the events, it is perfectly fine to delete them or
change them in a controlled manner as part of a migration or business process.

There is one rule I advise you to stick to: never delete or modify a single event
only delete/modify whole event streams (eg all the events belonging to a single
aggregate). The reason for this is that it is very difficult to account for all 
the possible outcomes if you delete or modify a single event, however by considering
your change in the context of a whole aggregate should protect you from these 
problems, provided you have ensured that other aggregates have taken copies of 
data they need to work with, keeping the changes within a consistency boundary.

There are a couple of different strategies for managing the lifecycle of 
aggregates (and the events they contain) within your system I'm going to explore
two of them, but first a quick note on the GDPR and how if affects event sourcing.

In the run up to the GDPR there were a lot of people blogging about the incompatibility
between the right to be forgotten and event sourcing such blogs used to go to great
lengths to allow personal information to be "deleted" without effecting the
events, such strategies usually boiled down to storing the personal information 
separately or encrypting it and if need be forgetting the keys. While this 
technically avoids modifying the events, they are in practice different to 
when you stored them and your system will need to cope with this. So neither 
strategy sits well with me.

When it comes to the GDPR, I first remind people that consent is only one of
several different reasons you or your company can hold data on someone and 
that removal of consent doesn't mean you have to instantly remove all their 
data. Imagine if I could phone a bank I have a loan with and ask them to 
delete all my personal information - free money! Except it doesn't work that
way. The bank has a legitimate interest in storing that data, so they are 
under no obligation to remove it just because I ask them to. (They may however
be required to stop sending me marketing information for new loans) 

The bottom line (although IANAL) is that if you have and document a legitimate
interest (or another valid purpose under the GDPR) for retaining the data in 
your events, you will be fine. 

So with that out of the way, what are my preferred ways to deal with deleting
aggregates and events?

### The tombstone event

The tombstone event is a strategy for marking the end of life of an aggregate
the idea is that for whatever reason, you want to delete an aggregate the first
step is to post a suitable event to it's event stream notifying of it's 
eventual demise. 

Your projections, processes and other interested event listeners can subscribe
to this event and use it as a trigger to perform any cleanup operations that
they need to do such as deleting a row from a table or finishing a business
process. You should also have a special purpose subscriber which makes a note
of the aggregate identity for which the tombstone event has been raised on.

Once you've given event consumers a reasonable period to cleanup (this could be
seconds or weeks depending on your use case) the special purpose subscriber will 
then delete every event (or if you have a write once event store forget the 
encryption keys) belonging to the aggregate identity. 

This strategy works quite well in the right to be forgotten case: when a user
contacts you and asks you to stop processing their data, you post a tombstone
event to any aggregates which contain their data; it is then fairly quickly
removed from your active systems and you stop processing it. At some point in
the near future you will finish the purge of their data from your system, but
in the meantime you have events and data which you can use to monitor and 
demonstrate compliance.

This does require a bit of upfront thought about your data model, for it 
to work succesfully you need to ensure that data you hold on a user is 
separated into different aggregates based on your justification for holding
and using that data. This means that you can remove someone from your marketing
system while retaining their data within your loan book. Far from being a 
downside, I'd suggest that in complying with the GDPR, you can actually 
improve the architecture of your domain model.

### Natural cycles in your domain

Another strategy for managing the deletion of aggregates and events is
to use natural (usually yearly or monthly) cycles which occur within 
your domain model. An example of this would be, for my ticketing system
I sell tickets to an event, the event occurs at a fixed point in time
and once the event is over I no longer need most of the data contained
within the system. This makes a good time to delete the data preserving
in different systems or different domain models only the information I
need to keep for legal or reporting purposes.

The scenario outlined above provides a clear cut time you can use to 
delete or archive aggregates there is an obvious point at which the 
data is of far less value to the organisation and the reasons for 
keeping it also diminish but how do you handle situations which are 
less clear cut, return customers who have a purchase history stemming
multiple years for example?

The key here is to introduce a rollup event, that is an event which 
carries over data you still care about into a new aggregate allowing
you to delete the old one and along with it any data which you no 
longer need. 

Sounds a bit convoluted? Greg Young has previous said that everything 
you need to know about event sourcing can be learnt by asking an 
accountant, this holds true here as well. What rollup events do 
accountants use? One good example is that of an account balance; an 
account generally holds inbound and outbound transactions over the
course of a financial or company year. It starts afresh in the next
year and the very first recorded transaction will be "balance brought
forward" - a transaction which copies the important data from the
previous year into the account for the next year.

This process is less useful from a forget me now point of view, but
by having a good data retention strategy in place and understanding
when you will delete data, you go a long way to fulfilling your 
other obligations under the GDPR. 

An interesting side effect of this technique - systems evolve over
time and sometimes you end up in a situation where a feature change
is completely incompatible with your current event model. You can 
make use of the natural cycles within your domain to migrate from
one model to the next, copying the important data from the old 
model into the new one as a rollup event.

### Conclusion

No event will exist for ever and any system which assumes they will
is at some point going to encounter difficulties. By understanding 
the natural points which we can delete data and by modeling 
appropriately - ensuring the boundaries are in place between data
which we want to keep for different time periods or for different
reasons, we can ensure that deleting events is a smooth process.     
 
 