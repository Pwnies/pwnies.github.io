---
title: badmedicine - DEFCON CTF quals 2013
author: sebbe
layout: post
published: true
date: 2013-06-19 12:47:41
---

Challenge description:
> http://badmedicine.shallweplayaga.me:8042

This challenge greeted us with a simple username prompt.

![username prompt](/public/img/badmedicine-welcome.png )

Entering a username, it's revealed that the task is to log in as the user `admin`. However, attempting to do so gives a message that admin logins are disabled.

Examining the cookies, we see that a cookie is set upon login. The contents are hexadecimal, and appear to be related to the username.

The hunch was then, that logging in as `admin'` and removing the last byte from the cookie would solve the problem, and it did.

The key is: who wants oatmeal raisin anyways twumpAdby
