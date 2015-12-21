---
layout: post
title: "The 6 rules of password storage"
date: 2015-12-21 13:00:00 +100
comments: false
---
## The 6 rules of password storage

This post is a quick writeup of the reasons behind password storage techniques, so I can refer to it instead of
explaining a fresh every time. It is intended to be simple and easy so there is no excuse for not reading or
understanding it.

0. We **must** protect passwords not just for our own services security but for the security of all internet services.
Users reuse passwords, in an ever connected internet, the value of a password is ever increasing.
1. We **must not** store plain text passwords because databases have a habit of falling into the wrong hands.
2. We **must not** use reversible encryption because keys are required all the time and have a habit of falling into the
same wrong hands at the same time as the database.
3. We **must not** simply hash the passwords. With a simple hash, every password that is the same hashes to the same
value an attackers work to recover the passwords is therefore greatly reduced.
4. We **must not** use a hash which has been intentionally built for speed such as Md5, Sha1 or Sha2. Dedicated hardware
and GPU's can calculate Billions to **TRILLIONS** of hashes per second. Password recovery by an attacker is inevitable.
5. We **must** use a hashing algorithm designed for password storage such as PBKDF2, Bcrypt or Scrypt with appropriate
cost parameters.


### Warning

The information contained in this post was accurate at the time it was posted. If you are reading this more than 12-18
months after December 2015 you should double check with a more up to date source that the information is
still valid before relying on it.

