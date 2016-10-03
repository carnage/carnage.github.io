---
layout: post
title: "3rd Party Credential Management"
date: 2016-10-03 13:00:00 +100
comments: false
---
## 3rd Party Credential Management

<!--excerpt-start-->

An interesting question came up during my PHP North West unconf talk about
[The 6 rules of password storage]({% post_url 2015-12-21-the-6-rules-of-password-storage %}):
"How should you store a password for SMTP login?". This is a slightly different problem to storing a users password for
your own site and requires a different solution. I've decided to expand upon the answer I gave at the time to provide a
reference for anyone else who has this problem.

<!--excerpt-end-->

Generalised, the problem we are trying to solve is how can we protect credentials that we store in our system, which we
later need to use (and thus have the plaintext available) to interact with a 3rd party system? How can we make this as
safe as possible given that we can't use a password hashing function?

### Encrypt all credentials

To store the credentials securely we are going to have to resort to reversible encryption - use a standard implementation
here, don't roll your own (lib-sodium is a good choice here). As I mentioned in the post on password storage, databases
and any encryption key which is stored on a web accessible server have a bad habit of falling into the wrong hands but
unlike a users password the webserver may not need to be able to access the credentials. If we can push the usage of
these credentials into a background process, running on a different server we can use asymetric encryption for the
credentials, giving an extra layer of defence in the event that the web server is compromised.

In this setup, you can put a public key on the webserver, allowing your site to write credentials into your datastore
but keep the private key only on the server running the background process. This means that an attacker who has managed
to compromise your webserver has to also manage to compromise the server running the background processes in order to
recover the stored credentials.

### Use single purpose credentials

Another way we can protect our users against a potential compromise is to encourage the use of single purpose credentials
in an ideal world, this would be some sort of API key or authentication token granted (potentially for a limited time)
for the sole use of your application. In the case from the original question, an email login, if possible encourage
your users to setup an email account/address (with a strong, unique password) specifically for the use of your application.

Following this advice significantly reduces the effects of a leak of the credentials and makes recovery after the fact
much less painful for the user - they can simply deactivate or change the credentials for your app's account.

### Principal of least access

My final piece of advice is to encourage your users to follow the principal of least access. In other words, the
credentials they provide to your app should allow access to the least possible set of functions your app requires to
perform it's function. For example, if your app sends email on behalf of your users, the account credentials provided
should ideally only allow sending of email. They probably shouldn't allow reading of email and the certainly must not
grant admin level access or access to additional systems eg FTP.

Following this advice is good security practice in general as it lowers the damage that can be done should an attacker
obtain the credentials.

### Conclusion

Security should always be considered as a journey and not a destination, there is no such thing as perfect security. In
order to reduce the risks to your users, it is important not just to focus on the technical steps which you can take to
protect them, but also to help educate them in looking after their own security. I would love to see more sites putting
security advice on their pages, to educate their users about simple steps they can take to help themselves.

### Warning

The information contained in this post was accurate at the time it was posted. If you are reading this more than 12-18
months after October 2016 you should double check with a more up to date source that the information is
still valid before relying on it.