---
layout: post
title: "This is a story all about how I learned to stop returning $this"
date: 2016-07-22 21:00:00 +100
comments: false
---
## This is a story all about how I learned to stop returning $this

<!--excerpt-start-->

For a long time, I like many other developers was in the habit of returning
this from any method that didn't need to return anything eg setters. I have
stopped doing this and this is why.

<!--excerpt-end-->

I had already read [Fluent interfaces are evil](http://ocramius.github.io/blog/fluent-interfaces-are-evil/)
and although I agreed with many of the points, I found that returning $this from
methods was useful, reduced the amount of typing I needed to do in some instances
and didn't really cause any of the issues raised in the article for my code bases.
I decided it was perfectly fine to keep going the way I was going.

Then one day, I decided to see how good the test suite of one of my 100% unit test
covered was by letting [Humbug](https://github.com/padraic/humbug) loose on the code.
For those of you that haven't encountered humbug, it is a mutation testing
library; for testing your tests. It works by introducing subtle changes in your
code and running your tests to see if the "mutations" it creates are caught.

To my dismay (I had considered the test suite to be pretty good) a large number
of escaped mutants were found by humbug. I started to investigate what the issues
were that caused such a large number of failures, hoping that the fact the library
was fairly new meant that it had found a large number of false positives.

This turned out not to be the case; humbug had correctly discovered that changing
return $this; to return null; was not being caught by my test suite. For the few
dozen fluent methods in my code base, not a single one had it's return value tested
by my tests.

I was left with a choice: either go through and write several dozen tests for methods
to ensure that they correctly returned $this OR remove the return $this entirely. Given
that these tests would have provided no value and been a pointless waste of CPU cycles,
I opted for the later option and have not added a return $this; since.

Upshot of this - if you are not willing to write tests for your fluent interface: don't
write it as one.
