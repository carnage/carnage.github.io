---
layout: post
title: "The right agile for the job"
date: 2017-04-10 18:00:00 +100
comments: false
---

## The right agile for the job

<!--excerpt-start-->

A lot of people blog about picking the right tool for the job and this usually focuses on programming languages,
 techniques and databases. However it is just as important to pick the right tool for your development life cycle. I
 have worked with a number of clients who have defaulted to scrum as their 'agile' process but a lot of the time this
 is inappropriate for the way they are working. Just as picking the wrong database for your data can lead to development
 overhead, picking the wrong agile technique can also have issues.

<!--excerpt-end-->

As a preface, I have no problem with sprints per se, however they are not really the right tool for most of the
companies I have consulted for. All of these companies have one or more in house products which are either a web based
business tool (eg order management), a software as a service platform or an ecommerce site. In all cases, they have
 total control over their infrastructure and they are not selling the software itself to end users.
 
Scrum as a model focuses on breaking down a development project into multiple small iterative sprints. Each sprint has a 
work commitment from the development team and is time boxed; the default for this seems to be two weeks. At the end of 
each sprint, a decision is made by the team as to weather or not to make a release and then the tasks for the next sprint
are prioritised and committed to. Any unfinished work from a previous sprint should be reevaluated in terms of business 
priorities before being added to a new sprint.

Under these circumstances what makes scrum an inappropriate model? In my opinion it comes down to the answer to two key
questions: 1) What happens when a ticket is completed? Does it get immediately deployed or do you wait until the end of
the sprint? 2) What happens to tickets which are not completed by the end of the sprint? The answer to the above is
usually 1) We release it as soon as possible 2) We roll them over to the next sprint. This is an inherently continuous
process, yet the sprints done in a scrum model focus on breaking down development into discrete blocks.

Despite this obvious mismatch between scrum and the reality of development, companies are still reluctant to switch away
 to a more appropriate model. This usually comes down to one reason: estimates. Businesses like estimates, they want to
 know when a feature will be ready for use so that they can plan for things like marketing. The scrum model prescribes a
 planning session at the start of each sprint where developers estimate tickets and schedule them into the forthcoming
 sprint. This allows the business to say we will get this batch of features by the end of the sprint, everyone is happy?

Scrum has the same issue as any model mismatch, inefficiencies creep in and you can often feel that scrum is not agile 
enough for the business reality. For example when an urgent bug fixes jump in mid sprint or when a tricky release ties 
up a developer for two days and consequently several tickets end up being incomplete at the end of the sprint.

#### What can we do instead?

There exists another agile model which is more suited to continuous delivery process that many of these companies aspire
to; it can provide true agility in a world where business priorities can change daily. It enables deployments to live as 
just another part of the workflow meaning that the value of finished work can be immediately realised by the business and
there is no concept of unfinished work since developers simply work on the most important item until it is done and has 
been released to live, then they pick up the new most important item. What is this magic process called? Kanban.

The general application of the Kanban process is fairly straight forward; consider the full life cycle of a story or 
ticket within your company; it might have phases such as business analysis, technical design, development, QA, user 
acceptance and release to live. Each one of these becomes a column on the board; you add an additional column on the left to 
represent the backlog of unstarted tasks. Priority of tickets goes from right to left, top to bottom; meaning a story 
which is closer to being live takes precedence over tickets which still have more work to do. The product owner can 
rearange the priorities within the columns as they see fit whereas other players (BAs, testers, devs etc) pick up the 
highest priority ticket they can work on (eg a tester cannot pick up a story from the backlog column; only from the 
development complete column)

The main complaint I hear when encouraging companies to try a Kanban approach is 'we like scrum because it allows us 
to plan and estimate delivery of code'. This usually follows with me pointing out that most of the estimates for time to
complete work are completely wrong and what is the point of an estimate which is only accurate 50% of the time? The 
discussion then usually moves to how can we get developers to be better at estimates. Answer: you can't, getting better 
at estimating how long it will take to complete a task only happens if you do it repeatedly, becoming practiced at it and
knowing all the things that can cause you to slow down. For software development every development task is different - 
if you find yourself doing the same thing over and over; you find an abstraction to generalise the problem so we never 
really get to the practiced point where you can estimate well. (Knowledge of the quirks of a code base which can slow you
down can help you improve outlier bad estimates but this doesn't help the general case)

#### What about estimates?

So how can we provide the business with the ability to plan for the future using the Kanban model whilst also trying 
to get improved estimates from the developers? Well, the answer is to remove the developers from the estimating process
entirely and instead rely on a more objective measure: statistics. Statistics are nice and forgiving; they can give you 
not just an estimate but an indication of how reliable that estimate is, they can tell you interesting things like how 
much is a reasonable contingency or tell you how much time is required to give you a 99% chance of delivering by the 
agreed date. 

How does this work in practice? Simple, everytime a story is picked up to be worked on, make a note of the date. When 
that story is completed and released to live make a note of the date. Total up the amount of time each story spends in 
progress and discard the top and bottom 10% (These are outliers: quick bug fixes or stories which should have been 
broken down better) take an average of the remaining 80%. 

Whenever a someone wants to get an estimate of how long a 
feature will take to get live; total up the amount of stories required to deliver it; multiply by the average - this will
give you a pretty reasonable time frame for how long it will take. Next look at how many stories have higher priority than
the stories that make up the feature, multiply those by the average as well. Divide each of the averages by your teams 
availability.
Adding the higher priority stories estimate to the current date gives us a 
good estimate of when work will start on the feature, then adding on the time to deliver it will give a reasonable estimate of 
when it will be done. 

If you want better estimates you can refine your statistical techniques by looking at the standard deviation of the story 
delivery time: multiplying by the average gives you a point at which you are 50% confident it will be completed by using 
standard deviation, you can give estimates for when you are 99% confident of; or whatever level of confidence the business
requires. To take into account changes in delivery speed over time (eg as your team becomes more familiar with the tools)
you could use a n-point moving average over a number of weeks/months. You could also break down by area (eg time in 
development vs time in test) to further refine the estimates. 

#### A worked example. 

Consider the following list as the amount of days required to complete the past 40 stories:

```[4, 4, 3, 3, 5, 3, 7, 6, 6, 3, 7, 5, 7, 2, 3, 5, 4, 6, 2, 4, 4, 5, 3, 6, 5, 5, 6, 2, 6, 5, 5, 6, 3, 6, 5, 3, 4, 5, 3, 1]```

We sort them

```[1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7]```

Remove outliers

```List = [3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6]```

Calculate the mean 

```sum(List) / len(List) = 4.46```

And standard deviation

```(sum([(x-mean)**2 for x in List])/len(List))**.5 = 1.12```

What does this tell us?

1. The average time to complete a story is 4.46 days
2. 68% of stories will be completed in between 3.34 and 5.58 days (1 std dev)
3. 95% of stories will be completed in between 2.22 and 6.70 days (2 std dev)
4. 99.7% of stories will be completed in between 1.10 and 7.82 days (3 std dev)
5. 50% of stories will be completed in 4.46 or less days (the average)
6. 84% of stories will be completed in 5.58 or less days (1 std dev)
7. 98% of stories will be completed in 6.70 or less days (2 std dev)
8. It will be exceedingly rare that any stories take longer than 7.82 days to complete

So a stakeholder asks you for an estimate of how long a feature will take; this feature consists of 5 stories. How can 
we use this to estimate the time (assuming each of the stories hasto be completed in sequence; parallel is slightly harder
maths)?

The average is easy: for additional stories we just add up the averages.

```4.46 days * 5 = 22.3 days work```

On average this is how long it will take to deliver; 50% of the time you will deliver faster than this, 50% of the time 
slower. 

What if there is a huge marketing budget to be spent around the delivery of this feature and they want a better than 50%
chance of delivery? 

Naively we could take our 98% confidence value from above (6.7 days) and multiply that by 5 (33.5 days)but this isn't 
actually correct. As we deliver more stories towards a feature some will take longer than expected others shorter and 
these issues cancel each other out. Instead we need to sum the square of the standard deviation, multiply by 5 and then 
square root it or simplifying slightly multiply our standard deviation by the square root of the number of tickets. 

Our 5 story standard deviation is 

```5**.5 * 1.12 = 2.50```

For a 98% confidence we do

```5*4.46 days + 2*(2.5 days) = 27.3 days```

and that becomes the final estimate.