---
layout: post
title: Defcon ctf Quals 2013 Babysfirst
category: ctf
author: Unknown
tags: ctf, defcon, sqli
---

Challenge description:
> http://babysfirst.shallweplayaga.me:8041

Upon visiting the page given, one's presented with a barebones login page.

![login page](/public/img/babysfirst-frontpage.png)

This basically screamed SQL injection. Attempting to send a username/password containing a `'` didn't immediately give a reaction. Inspecting the network monitor showed a header displaying the query being run, however.

![x-sql header](/public/img/babysfirst-x-sql.png)

Doing injections along the lines of

    ' UNION SELECT name FROM users WHERE '' = '
    
in the password field, allowed us to extract the following users and passwords through the user name displayed:

    user: root
    pass: barking up the wrong tree

    user: user
    pass: password
    
Logging in as either of those didn't give much, however.

Assuming that the key must be found in some other table, we fared a guess that the key may be located in the table keys. This led us to try

    ' UNION SELECT * FROM keys WHERE '' = '
    
which successfully found the key.

![success](/public/img/babysfirst-success.png)

The key is: literally online lolling on line WucGesJi

