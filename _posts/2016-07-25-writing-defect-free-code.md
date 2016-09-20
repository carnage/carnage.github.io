---
layout: post
title: "Writing defect free code"
date: 2016-07-25 10:00:00 +100
comments: false
---

## Writing defect free code

<!--excerpt-start-->

Defects in software are costly, some more so than others, so it is not surprising
that TDD and BDD are becoming almost a standard part of software development.
TDD and BDD are not the only ways to prevent defects in software - good object
oriented code will also help reduce the rate of defects.

This post is intended as a set of guidelines (not rules) which I have adopted
over the past few years to write code which has a low rate of defects, is easy
for others to peer review and above all tries not to set traps and gotchas for
the next developer who has to work with the code.

<!--excerpt-end-->

#### Use an IDE and Be IDE friendly
The first guideline is more of an over arching theme than anything else, you may
think you are a really pro developer using butterfly wings to deflect cosmic
radiation to flip bits on your disk drive but you are still human and humans
make mistakes (Perhaps todays butterfly's wing was a little bent).

An IDE can catch a lot of these mistakes early on and fix them for you. The sooner
you find a defect the cheaper it is to fix, red squiggly lines in your IDE as you
type are probably the fastest form of feedback and the fastest way to find and
prevent defects.

You should invest time in learning how to use your IDE's features effectively and
write code which your IDE can produce static analysis on to ensure that you are
using it to it's fullest.

#### Write code which reduces the possible number of invalid states
Consider these two functions:

```
function doFoo(bool $isBar, bool $isBaz)
{
    if ($isBar && $isBaz) {
        throw new \Exception('Can only be bar or baz');
    }

    if (!$isBar && !$isBaz) {
        throw new \Exception('Must be bar or baz');
    }

    //... Do foo with bar or baz
}
```

VS

```
define('MODE_BAZ', 'baz');
define('MODE_BAR', 'bar');

function doFoo(string $mode)
{
    if (!in_array($mode, [MODE_BAZ, MODE_BAR])) {
        throw new \Exception('Mode must be bar or baz');
    }

    //... Do foo with bar or baz
}
```

The first function has 4 possible input states 2 of which are invalid. The
second function on the other hand has only 2 input states (assuming you use
the constants as intended) neither of which are invalid. The second function
is much easier to get to grips with, it is far more obvious without reading
the function body what you need to pass into it and which states are valid.

The second function is a clearer way to write the code and will likely need
less documentation to explain how to use it than the first one will. The idea
of removing invalid states from the code is a continued theme in several of
these guidelines.

#### An object should always be in a valid state

A follow up to the previous point, a good way of reducing possible invalid
states is to write your objects in such a way that they can not get into an
invalid state, this means that any dependencies your object requires need to
be passed in via it's constructor and the entire internal object state should
be initialised upon construction. Any time an object's internal state is changed
the changes should be validated by the object and an exception thrown if the state
would become invalid.

Consider:

```
class DateRange
{
    private $start;
    private $end;

    public function setStartDate(\DateTime $datetime)
    {
        $this->start = $datetime;
    }

    public function setEndDate(\DateTime $datetime)
    {
        $this->end = $datetime;
    }

    public function isValid()
    {
        return $this->start < $this->end;
    }
}
```

VS

```
class DateRange
{
    private $start;
    private $end;

    public function __construct(\DateTime $start, \DateTime $end)
    {
        $this->updateDates($start, $end);
    }

    public function updateDates(\DateTime $start, \DateTime $end)
    {
        if ($end < $start) {
            throw new \Exception('Start must be before end');
        }

        $this->start = $start;
        $this->end = $end;
    }
}
```

The second class is always in a valid state so you can trust it's value; the first object could be in
several invalid states, not only could start be before the end date but one or other dates could be
missing entirely giving a large scope for defects to creep into code which consumes the DateRange object.

#### No public properties

If you've gone to all the effort to ensure your class is in a valid state, why would you allow an external
class to be able to mess that up afterwards? This is exactly what you enable if you use public properties.
No consumers of your class can trust it's state as anything else could have messed with it since it was
validated.

You should start by default by making all properties private. Only loosen that visibility to protected
if you absolutely want child classes to be able to access the property directly. I usually only do this
for dependent service classes eg a logger and not for variables which represent class state. This allows
you to create an abstract class which handles injection of common service classes for all children but
still keep tight control over any changes in object state.

To phrase this guideline from a different direction, you should only directly access properties from the
current class. Any property access to other classes should go through accessor methods which protect the
object's internal state. This guideline can be applied less strictly to child classes, which you may decide
it is worth allowing direct access to some properties for the sake of brevity.

#### Don't use setters

This was partially eluded to in the previous two points. Methods which allow one object to mess with the
internal state of another object are a defect waiting to happen. Setter methods, break encapsulation
and cause high degrees of coupling between objects due to the exposure of internal state. Instead pass
all dependencies the object needs via the constructor and perform updates to the internal state through
explicit methods as per the example above.

This guideline becomes very relevant when working with a large application framework such as Symfony,
Zend or Laravel. As control passes between your code and the framework code, eg in event listeners, if
an object's dependencies can be changed via a setter another developers code could be interfering with
yours. You had a logger which was writing to the syslog, but after an event listener was fired
you don't get any more log messages; after some tracking down, you find that buried in an event listener
a developer helpfully changed the log adapter to log to the filesystem instead.

If something shouldn't change once it's been set (eg a log adapter) why would you write code which
allows it to be changed? This guideline applies to a lot of things, the number of doctrine entities I have
seen with a setId() method on them is beyond belief.

There is a school of thought which suggests that in order to avoid the problems above you could simply
set the visibility of setters to private/protected. Whereas this will solve many of the issues, it falls
foul of another one of my guidelines: don't write unnecessary code.

#### Getters should return immutable values.

This guideline is more of a 50/50 use case, as quite often you want a getter to return a value you can
interact with. This is especially true in service classes and factories, but in other situations such as
entities it can be dangerous and lead to hard to diagnose data loss causing defects. Consider:

```
class UserEntity
{
    private $joinDate;

    public function __construct()
    {
        $this->joinDate = new \DateTime();
    }

    public function getJoinDate()
    {
        return $this->joinDate;
    }
}

class SomeService
{
    private $userRepository;

    public function applyJoinBonuses($userId)
    {
        $userEntity = $this->userRepository->fetch($userId);
        if ($userEntity->getJoinDate()->add(new \DateInterval('P1Y')) < new \DateTime()) {
            //...
        }

        $this->userRepositiry->save($userEntity);
    }
}

```

A fictitious scenario where by some service is applying some logic to a user to calculate if they are
eligible for a loyalty bonus and applying it to them. The precise logic doesn't really matter but there
is a very subtle bug in the above code. When we grab the datetime object from the user and then add a
year to it to check our bonus condition we have actually modified the internal state of the user entity
when our repository saves the user complete with bonus applied, it will also save this updated datetime.

There are several ways we could fix this. If the repository class supports it (If you are using doctrine
at the time of writing, it doesn't) we could set the join date to be a DateTimeImmutable object instead,
or we could clone the joinDate before returning it or we could return a DateTimeImmutable using the
createFromMutable (PHP 5.6+) method on it. However an even better way would be not to expose the raw
datetime object at all:

```
class UserEntity
{
    private $joinDate;

    public function __construct()
    {
        $this->joinDate = new \DateTime();
    }

    public function joinedBefore(\DateTime $date)
    {
        return $this->joinDate < $date;
    }
}

class SomeService
{
    private $userRepository;

    public function applyJoinBonuses($userId)
    {
        $userEntity = $this->userRepository->fetch($userId);
        $cutoffDate = (new \DateTime())->sub(new \DateInterval('P1Y'));
        if ($userEntity->joinedBefore($cutoffDate)) {
            //...
        }

        $this->userRepositiry->save($userEntity);
    }
}
```

This has the added bonus of hiding the implementation of the join date from any consuming classes and
makes the logic in the consuming class a bit easier to understand.

#### Change state or return something never both

This guideline is all about avoiding leaving traps in your code for the unfortunate developer who has to
work with your code in six months time. If you think about how you name your methods pn objects, they will
usually be of the form <verb><noun> eg fetchUser or calculateBalance. It would be some what counter
intuitive if calculateBalance also changed the balance of the object it was called upon - you should
probably name it calculateAndUpdateBalance and that is a bit of a mouthful.

As an example consider the PHP iterator interface:

```
interface Iterator
{
    public function key();
    public function current();
    public function valid();
    public function next();

}
```

This interface conforms with this guideline key, current and valid answer questions about the state of
the iterator. Next and rewind change it's state. Imagine if instead, we had the following interface:

```
interface Iterator
{
    public function current();
    public function valid();
    public function rewind();
}
```

Where current returned an array `[$key, $value]` and advanced to the next value. For most use cases,
this would probably still work, but if at any point you needed to read the current value twice, you
can't do so. This technique is referred to as CQS: command query separation and really deserves an article
of it's own, but in terms of making code easier to modify it is a very valuable tool in preventing
unexpected surprises.

#### Don't write unnecessary code
This should go without saying really, but sometimes people just get into bad habits. Just because your
IDE can generate getters for every property in your class doesn't mean you should do so. If a property
is internal and of no use to outside classes, why expose it? Why write code to expose it?

You may wonder what this guideline has to do with reducing defects: if code is auto generated by an IDE, it's
not likely to contain errors or bugs right? You would be right, it isn't likely to cause you any defects
however, each getter takes up 4 lines of code, plus 3 lines of comments and a line of whitespace after.

Any developer trying to review your code or understand it to make modifications has to also read this
code, parse it and ignore it. This reduces their focus on the important code which is doing the work.
Consider the examples below (from a semi real world scenario).

```
class FooCommand extends BaseCommand
{
    private $fooService;

    public function __construct(FooService $fooService)
    {
        $this->setFooService($fooService);
    }

    private function setFooService(FooService $fooService)
    {
        $this->fooService = $fooService;
        return $this;
    }

    private function getFooService()
    {
        return $this->fooService;
    }

    public function handle()
    {
        $this->getFooService()->doFoo($this->getOption('bar'));
    }
}
```

VS

```
class FooCommand extends BaseCommand
{
    private $fooService;

    public function __construct(FooService $fooService)
    {
        $this->fooService = $fooService;
    }

    public function handle()
    {
        $this->fooService->doFoo($this->getOption('bar'));
    }
}
```

Event without comments on the methods, the first example is much longer than the second due to the
extra superfluous methods, now consider adding 2, 3, 4 or more properties and you soon get a whole
screen full of redundant code. Be nice to your fellow developers and don't make them read through
irrelevant stuff to understand your code.

#### Use type hints

An extension of the guideline on IDE's: use type hints. A strong type system inside your code helps
reduce bugs as it reduces error propagation through the code - when something of the wrong type goes
into a type hinted method or function the execution stops. While developing this helps you track down
issues quickly as the source of the problem is usually one step up the stack trace. It also reduces the
amount of error checking code you need to write as the interpreter will do it for you.

Good types help breed understanding of the code for those who come after you, consider:

```
function sendMessage($to, $subject, $text) {
    $to->addMessage($subject, $text);
}
```

VS

```
function sendMessage(User $to, string $subject, string $text): void {
    $to->addMessage($subject, $text);
}

```

The first example could easily cause confusion: should $to be a userId? a user object? an email
address? The error you get (Call to undefined method) if you pass the wrong type doesn't help you as
much as it could do either.

The second example very clearly shows what needs to be passed to this function to have it work correctly
All of this without the developer needing to examine the internal workings of the function to try and
grasp what types need to be passed. For such a simple example, the benefits may not be as apparent, but
if the function was 30 lines long and used several different types the difference in time it takes to
figure out the function is greatly reduced.

As an added bonus, putting type hints into your code allows your IDE to autocomplete much more
effectively - speeding up your development and reducing errors from typos in function names.

#### Encapsulate knowledge inside classes

Probably the best weapon we have in helping developers who interact with our code later on is to reduce
the cognitive burden on them for getting something done. The less of your code they have to read and
understand to complete their task the better.

When you wrote the code, you gained a lot of knowledge about the specific problem you were solving. This
knowledge is not something that another developer who is working on the code necessarily has

#### The 80/20 rule

All the guidelines I've suggested here are intended to apply to the most common use cases there will be
some times where it is appropriate to ignore them to solve specific problems. Blindly applying these
guidelines 100% of the time will probably cause you some pain in certain situations. Just make sure you
have a good reason for it, because if I'm reviewing your code I will ask for it.

