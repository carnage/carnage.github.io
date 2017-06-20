---
layout: post
title: "PHP Yorkshire - a Retrospective"
date: 2017-04-10 18:00:00 +100
comments: false
---

## PHP Yorkshire - a Retrospective

<!--excerpt-start-->

Alongside an outstanding team and a selection of excellent speakers, I recently hosted the 
inaugural PHP Yorkshire event. This is a few of my thoughts on how the event went from an 
organisers perspective.

<!--excerpt-end-->

### What went well

This could be a very long section, the event was a huge success so I'll highlight what I think
were the key factors to the event's success. 

#### A focus on content. 

When choosing the talks for the event, we didn't opt for an anonymous
  process but still focused on the quality of the submission as our key deciding factor. I 
  feel this gave us a fairly diverse range of speakers which included people not usually
  seen at PHP conferences, brand new speakers and a few familiar faces. 
  
This diversity in the lineup is a huge factor in what made it so strong but I still feel it 
is something we can do better on. The main improvement to be had here is encouraging a more
diverse set of local submissions giving us an even better selection to choose from.

Taking a lead from the PHP Leeds user group on what they wanted to see at the event was also 
a good idea and helped shape the line up towards one which focused fully on PHP and closely 
aligned topics; skipping over slightly less relevant content such as docker. This will be 
something we do again and could even become part of our unique selling point. 

Every talk was evaluated on the metric "will the attendees learn something they can put to 
use first thing Monday morning?" with every selected talk scoring highly on it. We may even
go as far as to ask this question as part of the CFP next year to help guide even better 
submissions.

#### Open tickets

When confronted with a choice of ticketing system for an event, there are a myriad of hosted 
solutions all of which charge a monthly fee or %age of sales for the service. Researching 
these ahead of the ticket sales launch was a huge problem: the cheaper ones lacked features 
which we knew we would want and the expensive ones would have added up to £5 onto the cost of
a ticket. 

Keeping the price low so that more people could afford to attend was a key priority to me 
(early in my career I had neither the money or the boss to pay for conference tickets, a 
local conference for under £100 would have been great). So paying a high fee for ticketing
was not really an option, neither was paying for a sub standard service or one which would 
cause huge admin overheads.

Given the lack of good open source ticketing solutions I decided to write my own and open
tickets is the result. It is currently very minimal - only the features we needed for PHP 
Yorkshire were built but has a very solid core to expand upon in the future. The system is
event sourced and is an example of what I consider a good Zend framework application: 
decoupled, but still leveraging the power of the framework where appropriate.

You can find the repository here https://github.com/carnage/opentickets if you want to look 
at how I've implemented it or consider it for your own event. As an aside, if there are any 
front end related conferences wanting to use it - the templates (especially email) and css
really need someone who knows what they are doing to tidy up. I'll offer support to your 
usage (setup, debugging, maybe even feature requests) if you are willing to help sort 
these out.

#### Everything else

We invited a number of students to the conference as part of a scholarship program run by 
Mark Baker (of Rainbow elephpant fame) this had a really positive outcome and all of the 
attendees felt they got value out of the day. This is definitely something which we will be
repeating in future years.

Having both dedicated AV support and an MC in both tracks helped to smooth the transfer 
process for both speakers and delegates - this is definitely something we want to do again 
next year and if this years hosts don't want to reprise their roles, I may ask for applicants
in the CFP.

The mad hatters tea party was a late addition to the lineup, I was still hoping for a sponsor 
 to step in and cover the social costs but without one, we had a more limited budget. I think
 what we had rounded off the event perfectly so it will probably return next year in some 
 form, perhaps with a bigger budget we can have even sillier hats or I can implement some of
 my other ideas.
  
### What didn't go so well

If you were there on the day, you may think that this section should be empty: nothing major 
went wrong and even the minor things which occurred were handled by the university staff and 
resolved rapidly. Most of these items were things which are in my opinion low hanging fruit
to make the event even better next year.

#### Marketing 

Whilst I think our team did a really good job of visiting local user groups to spread the 
word about the event, capturing a market which were already interested in attending events 
like PHP Yorkshire, I think we fell down on reaching beyond this. Leeds especially has dozens
of companies who use PHP, for which PHP Yorkshire could have been a really great event for 
them to attend, didn't even know about it.

For next year, I think it's something to focus on: how we can reach out to these companies.
One option might be to have a member of the team dedicated to doing this another might be 
to spend some budget on advertising locally. If anyone has any ideas for this or feels they 
might be able to help out please get in touch.

#### Sponsorships

Firstly: our sponsors were all really great and I think all of them felt they got value out 
of supporting our first event. Where I think we fell down was not getting very many of them,
the space we had was huge and could easily have had more stands setup and there was plenty 
of space in the delegate bags for more sponsor materials.

Sponsorships were completely handled by me and with all the other duties I had for the event
I didn't have as much time to dedicate to them as I would have liked. One improvement might
be to get a dedicated person to look after the sponsors;  
but the main improvement I'm thinking of making here is to move on from the email inbox + 
google spreadsheet approach to managing leads and sponsors.
 
This will mean building a full sponsorship CRM to manage both leads and to give sponsors a 
smoother on boarding flow once a signed contract is in place. Following on from the success 
of the open tickets project, this too will be open source and an example of good practice. 
Additionally, I will be using it as an opportunity to demonstrate some of the theory from my
micro-services talk. There will probably be follow up posts on both this system and open 
tickets as they co-evolve.

#### Videos

Unfortunately, the talks which were videoed did not come out as planned I've yet to recieve
the final cuts but have been told that most of the footage has come out to dark to be used.
I think we will still be able to present something reasonable but the final product probably
won't be of the quality I was hoping for.

To avoid this issue next year, we are exploring several options which include a possible 
change of location, other areas on campus have better lighting and as such would give a 
better output. Another option might be to bring in some lighting from an external supplier 
but that obviously comes with a greater cost.

### Conclusion

For a first event I think PHP Yorkshire 2017 was really good. There are areas we can improve
for 2018 which will make it even better. I have repeatedly mentioned an event in 2018, so I
can confirm it is happening the date for the main event will be the 14th of April, so put it
in your diaries and follow @phpyorkshire for updates.
