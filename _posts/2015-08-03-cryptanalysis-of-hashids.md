---
layout: post
title: "Cryptanalysis of hashids"
date: 2015-08-03 10:00:00 +100
comments: false
---

## Introduction

<!--excerpt-start-->

Hashids is a multi language library which converts integers into strings. Although the site http://hashids.org/ makes no
claims of being secure, the language used (words like hash and salt) within the code and documentation implies security.
In this post, I explore just how bad it is from a security perspective in the hope that anyone reading this will avoid
using it in a security context.

<!--excerpt-end-->

Wikipedia defines the ideal hash function as having three main properties:

1. It is extremely easy to calculate a hash for any given data.
2. It is extremely computationally difficult to calculate an alphanumeric text that has a given hash.
3. It is extremely unlikely that two slightly different messages will have the same hash.

Hashids clearly fulfills point 1. The function is also reversible, that is, given it's salt and the function's output 
you can easily calculate the original input. For this to be possible for ALL inputs, ALL outputs must map back to one 
and only one  input. This means it satisfies point 3. It's looking quite good so far.

If this were to be used for security purposes, we would like to be able to display the encoded value publicly without an
attacker being able to 1) determine the real value of the id and 2) be able to manipulate the input to the decoding 
function to produce a desired value. Essentially this means that property 2 of an ideal hash function needs to hold for
decoding a hashid. Clearly if you have access to the salt, it is trivial to calculate the function in either direction 
so the basis for proving or disproving property 2 lies in how easy it is for an attacker to discover the secret salt.




## The algorithm

In pseudo code, from a high level the hashids algorithm works as follows:

```
Given a shuffle function (sf) and a salt (s)

Initialisation: 
For a given alphabet (A') remove a set of separator characters (S') 
Apply S' = sf(S', s)
Apply A' = sf(A', s)
Remove the first 1/12 * length(A') characters of A' to produce a set of guard characters (G')

Encoding:
For each number (n) to be encoded and it's index (i):
    t = t + (n mod (100+i))
t = t mod length(A')
Choose an initial character for the output (o) by taking the character at index t from A' (ic)
For each number (n) to be encoded and it's index (i):
    Apply A' = sf(A', concat(ic, s, A'))
    map n to o using A'
    if this is not the last number:
        add the ordinal of the first character of n's encoding to i (si)
        Choose separator character from S' using si mod length(S') append to o
```
        
After the encoding, if the string is not of the minimum length, it is then padded. I'm going to ignore this part of the 
process for now. It is also possible for a user to specify their own alphabet A' however again, for the purpose of this
I'm going to assume that the default is used.

## Attack setup

As an attacker we want to recover the secret salt, to do this I'm going to use a chosen plain text attack against this 
algorithm to recover extra information about the internal state after certain operations. We already know from the 
implementation the initial alphabet A' and set of separators S' my first attack will give us A'' the alphabet after the
shuffle function has been applied to it once.

A very interesting part of the algorithm is the part where it chooses an initial character, at this point only one
iteration of the shuffle function has occurred which means that with some cleverly chosen plain text's we can get the 
algorithm to divulge some information about it's internal state.

A call to encode with a single number (n) less than 100 will cause the algorithm to output the nth character from A' as 
the first character in the output, by encoding the numbers from 0 to 43 (A' by default is 44 characters after 
initialisation)                       
                                      
The alphabet after initialisation is 'abdegjklmnopqrvwxyzABDEGJKLMNOPQRVWXYZ1234567890' we can then run this code:

```php
<?php
$hashids = new Hashids\Hashids('salt');
$alphabet = '';

for($i=0; $i<44; $i++) {
    $alphabet .= $hashids->encode($i)[0];
}

echo $alphabet;
```

which gives us: 'OXdwnqJxL41r7zAPpbayY290eNv6ZEBVGlgoQjRDMKW5'. Notice that this is 4 characters shorter than the original
alphabet, this is because the first 4 characters are used to create G'. Now that we have both the input and (most of) the
output of the shuffle function, lets take a closer look at how it works.

## Attacking the shuffle function

In pseudo code the algorithm for the shuffle function is as follows:

```
parameters: 
- A' the alphabet to shuffle
- s the salt

alphabetIndex = length(A') - 1
saltIndex = 0
runningTotal = 0

while (alphabetIndex > 0):
    i = the ordinal of s[saltIndex]
    runningTotal = runningTotal + i
    j = (runningTotal + i + saltIndex) mod alphabetIndex
    swap A'[alphabetIndex] with A'[j]
    alphabetIndex = alphabetIndex - 1
    saltIndex = (saltIndex + 1) mod length(s) 

```

It starts from the end of the alphabet A' and swaps the character at the end with another character from before it in the
alphabet A' Running that backwards from our previous input and output, we see that the last character in the output is 5, 
this was previously at index 26 so we can deduce that the following is true: 
```(ord(s[0]) + ord(s[0]) + 0) mod 47 = 42 ``` This can be rearranged and solved for ord(s[0]). As this is a modular 
system we get a few valid options: 21, 68, 115, 162, 209 (We can stop here assuming single byte characters in the 
salt) In total, there are 5 possible characters here for the first character of the salt.

A similar thing can be done for each swap that was done but as we do not (yet) know the length of the salt we end up with
more equations for each, for the second to last character we have these two:
```(ord(salt[1]) + ord(salt[1]) + ord(salt[0]) + 1) mod 46 = 34``` or
```(ord(salt[0]) + ord(salt[0]) + ord(salt[0]) + 0) mod 46 = 34``` if we plug our previous valid options into the second
equation, we find that none of them match, this means that our salt must be at least 2 characters and we can throw away 
the second equation. Solving the first is a bit harder but we can plugin all of our possible valid options from before 
and get another set of valid options for each: For s[0] = 21 6, 29, 52, 75, 98, 121 etc For s[0] = 68 we find no possible
solutions for the equation so we can rule this out as a possible option for s[0]. This can be done for all possible values
of s[0] leaving us with 3 remaining values for s[0] and 33 possible values for s[1].

The next swap gives us the following equations: (ignoring the equation for salt length 1 as we have ruled this out
already) 
```(ord(salt[2]) + ord(salt[2]) + ord(salt[1]) + ord(salt[0]) + 2) mod 45 = 25``` or 
```(ord(salt[0]) + ord(salt[0]) + ord(salt[1]) + ord(salt[0]) + 0) mod 45 = 25``` When we solve these equations, we find
two possible values for the second equation, this means that it is possible that the salt has a length of 2 and we also
find about 6 solutions for each of the 33 solutions we had for length 2; at this stage we have about 200 candidate salts
for 3 characters; this is many orders of magnitude better than a brute force attack which would have yielded 16 million
possible salts of 3 characters.

## Automating and improving the attack

At this stage, the number of possible salts and equations is going to start getting out of hand so I've written some code
to handle calculating the possible values. The class can be found [here](https://gist.github.com/carnage/dcb3d5846ad80dbfa9a3) 
running it confirms our manual work previously and begins to find possible strings for longer salt lengths, trouble is 
that by the time it reaches 8 characters it has found about 1.5 million possible salts, even if we were to limit 
ourselves to printable ascii characters for the salt, it still grows out of control quite quickly. 

What can we do about this? We have several options to limit the rate that the number of candidate salts grows at: 

* We could for example stop generating new salts at a certain length or we could further limit the character set however in 
doing this we allow the possibility of not being able to calculate the salt to creep in: this is exactly what you would
do for a brute force attack and this attack can be completed far faster. 
* We could improve the algorithm used to search for salts to make it faster or give it a stronger stopping condition: 
currently my code calculates all the possible salts which could produce the output we have considered so far, we could 
change it so that after it has examined all the salts with a length less than n we could test each of these candidates 
against the 44 chosen plain texts we had before and eliminate any which don't produce the same output.
* When we first calculated our chosen plain texts, we discarded some of the output as we were only interested in the first
character, We could use some of the data we previously gathered here to form more equations that must hold true for the
candidate salts, this would stop the number growing quite as fast.
* We could gather the output of more encodings, as in the previous option, more encodings allows for more equations to be
 formed which will put further constraints on the possible salt values. (Hint: take a look at the encoding of sets of numbers)
 
## Conclusion and recommendations
 
 The attack I have described is significantly better than a brute force attack, so from a cryptographic stand point the
 algorithm is considered to be broken, it is quite easy to recover the salt; making it possible for an attacker to run the
 encoding in either direction and invalidates property 2 for an ideal hash function. I will leave it as an exercise for
 the reader to improve upon my attack in order to facilitate full and fast recovery of the salt.
 
 It is likely that the author of hashids may come back with a rebuttal to this attack, perhaps a claim that in a production
 system an attacker is unlikely to be able to get choosen plain texts to be encoded. To this I would agree however the 
 attack I have demonstrated just happens to be one attack which renders the algorithm far weaker than the claim on the
 [website](https://github.com/hashids/hashids.github.io/blob/7ec6505a2070842cdcf3c0537222e624ee81e240/index.html) which 
 states that the only way to reverse the encoding is to know the salt or brute force the salt.
 
 It is my opinion that this algorithm cannot be fixed in such a way that would make the previous claim true so my 
 recommendation to the author is a) Remove claims from documentation and website that it is hard for an attacker to 
 reverse the encoding. b) Ensure users are aware that the encoding provides NO security over their ids. c) removed the
 terms hash and salt from the library as these imply that the algorithm is secure and that it meets the general expectations
 of a hash algorithm. Further, anyone using this library should assume that id's encoded by this library are fully 
 reversible and as such it offers no security over using the raw integer ids.

