---
layout: post
title: "Password similarity"
date: 2016-10-03 13:00:00 +100
comments: false
---
## Password similarity

<!--excerpt-start-->

Another interesting discussion broke out on [twitter](https://twitter.com/afilina/status/785864310648082433) today about
Yahoo! preventing people from using passwords which are too similar to passwords that they have used in the past. I agree
with the general direction this discussion took - Yahoo is probably storing plain text or encrypted passwords violating
my [6 rules of password storage]({% post_url 2015-12-21-the-6-rules-of-password-storage %}), however it got me thinking:
Is it possible to achieve a similar password filter in a secure way?

<!--excerpt-end-->

## Why would it be insecure?

Several of the replies agreed on the fact that any ability to measure similarity would massively reduce the complexity of
a brute force attack. If that were true there would be no way for a secure system to reject similar passwords. Lets
take a look at why that would prove insecure.

Assume that:

- p is a password
- H is a stored hash of a password
- h() is a strong slow hash function
- v(H, q) is a verify function which returns true iif h(q) === h(p) === H
- X is the set of all possible passwords
- x(p) is a function which returns a set of all passwords considered similar to p
- if x(p) contains q then x(q) contains p
- s(q, H) is an oracle function which returns true iif q is contained in the set x(p)
- s(q, H) is substantially faster than v(H, q)

Without being able to use the similarity function s, an attacker must brute force using the function v; which because it
uses the slow hash function, is also slow and their brute force attack is reduced to a crawl. This is the basis of how
we currently store passwords securely.

Now suppose that the attacker gains access to the function s, instead of attacking the password directly using v they can
instead search for passwords which are similar to p instead of exactly p. Given that s is substantially faster than v
they can quickly narrow their search space from X to x(p), a set which to be useful for it's purpose must be significantly
smaller than X. Once they get a q such that s(s, H) returns true they can call x(q) to get a set of passwords which
contains p. They then have a much smaller space to search with the slower function v and this reduces the cost of the
attack.

This seems to imply that such a system would be less secure than a system not employing the similar password
functionallity.

## Can we improve it?

The weakness of the above system comes from our function s: it is too fast. If we could slow s down we could bring back
much of our previous security. How could this be done?

- t(p) is a transformation function such that t(p) = t(q) for all q in x(p)
- T is h(t(p))

We can now redefine our oracle function s to be similar to v eg

- s(q, T) returns true iif v(T, t(q)) returns true

With the above definition, searching for similar passwords takes as long as searching for an exact match, however now
instead of searching for a single password in X they are searching for one of x(p) in X increasing the chance of success
for a random password from 1/X to size(x(p))/X but they will still have to try each member of x(p) to find the correct
password in the end.

Provided the size of x(p) is fairly small the likely reduction in security will be equivalent to shortening the password
by a character or two. (We could prove this by defining t(p) to be a function which considers passwords similar if they
are the same except the last character; t then returns p truncated by 1 char.)

## Is it worth it?

Probably not. If you saw my unconf talk on passwords at PHP North West you will remember one of my rules being don't
force your users to change passwords unless they have been compromised.

At the point of them changing it you can ask for their previous password and compare the two plain texts don't worry
too much about any previous passwords you should only really care it's not similar to the compromised one.

## Conclusion

All things considered, the trade off in user security here seems to be a bad one, so I would **STRONGLY** recommend
against implementing the system described above for your users.

If you have the requirement to disallow similar passwords:

- Only consider their most recent password
- Ask them for it when changing password
- Compare the plain text versions
