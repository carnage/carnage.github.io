---
layout: talk
title: "You Attended Talk: An introduction to event sourcing"
comments: false
slides: 8a63e8f4d9c643d7806ac0bc339ac65d
givenAt:
    - location: "PHP NE"
    - location: "Leeds PHP"
    - location: "PHP Day"
      slides: https://speakerdeck.com/carnage/you-attended-talk-an-introduction-to-event-sourcing-short
    - location: "PHP North West"
      slides: https://speakerdeck.com/carnage/you-attended-talk-an-introduction-to-event-sourcing
---

Imagine for a moment you work for a large online retailer specialising in household goods. One morning, the head of marketing comes to you and says "I've had this great idea we're going to send discount vouchers to anyone who's changed their address in the past 3 months; people who've recently moved are more likely to be buying new furniture. Could you retrieve a list of all these customers?" You explain to him your systems only store a customers current address and doesn't record when it was last changed, a new feature is added to the backlog and the head of marketing leaves a little disappointed. 

What if you could build a system which was able to answer this kind of question without knowing it up front? A possible solution is to use event sourcing, being able to go back to any previous state of your data is just one advantage of using event sourcing in your application. Event sourcing is a total paradigm shift from the more traditional model of storing an application's current state and can appear to be a very unnatural way to think about and build a system. In this talk I'm going to show you examples of why event sourcing can be a superior model and cover some implementation considerations. 
