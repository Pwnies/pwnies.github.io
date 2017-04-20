---
title: drmless - PlaidCTF 2013
author: br0ns
layout: post
published: true
date: 2013-05-06 22:56:16
---

Challenge description:

><pre> You should check out our cool stories, bros.</pre>

Link: [drmless.tgz](http://dl.ctftime.org/64/382/drmless.tgz-e9f85853ac856d7ed7a5a8c6e807955f07bbfa7a)

Inside the archive are five files:

* .drmlicense
* cool_story.enc
* cooler_story.enc
* drmless
* readme.txt

In readme.txt we find this text:

><pre> Here's a cool story from PPP!
> We wrote an even cooler story, but you need to pay
> us if you want to unlock it. TEN THOUSAND DOLLAR.</pre>

The file `drmless` is a 32bit ELF.  Running it we see that it behaves exactly as
`less` except that it is also able to open `cool_story.enc`.  However we can't
open `cooler_story.enc`.

Looking in the file `.drmlicense` we find the 16 bytes:

    00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff

Flipping one bit in `.drmlicense` and opening `cool_story.enc` again we see that
every 16th byte has the same bit flipped.  So we guess that the 16 bytes in
`.drmless` are xor'ed into the DRM'ed file ECB style.  However the xor
difference between the DRM'ed file and the plaintext is not `.drmlicense`, so
something else is going on.  Our initial guess is that a pseudorandom stream is
xor'ed into the DRM'ed file along with the license.

So we try putting all zeroes in `.drmlicense` in order to extract the
pseudorandom stream.  However `drmless` now says that the file contains binary
data and when prompted to show it anyway shows the DRM'ed file, not the
"plaintext".

The binary is not stripped so running `readelf -s drmless` gives us a lot of
symbols.  Specifically we are interested in these (`readelf -s drmless|grep
drm`):

    1024: 0804eb69   197 FUNC    GLOBAL DEFAULT   14 drmprotected
    1192: 0804eb34    53 FUNC    GLOBAL DEFAULT   14 undrm

Going out on a limb we patch `drmprotected` to always return true:

```objdump
0804eb69 <drmprotected>:
  804eb69:       31 c0                   xor    eax,eax
  804eb6b:       40                      inc    eax
  804eb6c:       c3                      ret
```

Running the program again we see the "plaintext".  Bam.  We see that changing
the license file doesn't change the pseudorandom stream.

So now we do the same trick with `cooler_story.enc` to find it's stream (which
is not the same as the one for `cool_story.enc` by the way).  Now trying each
byte value for each of the 16 bytes in `.drmlicense` we compile a list of
candidates that will produce printable characters everywhere in the plaintext
(script below).

We find two candidates for each of the sixteen bytes, and after some quick
guesswork (chaning "!" to " ", etc.) we arrive at the answer:

```text
TWELFTH NIGHT; OR, WHAT YOU WILL

by PPP
"freeShakespeare_downWithDRM"
```

`doit.py`:

```python
from pwn import *
import os, string

log.waitfor('Generating "plaintext"')
os.system('./drmless cooler_story.enc > cooler_story')
log.succeeded()

ct = read('cooler_story.enc')
pt = read('cooler_story')
lic = read('.drmlicense')

stream = xor(ct, pt, cut='min')
stream = xor(stream, lic, cut='max')

ct = xor(ct, stream, cut='min')

groups = zip(*group(16, ct))

log.waitfor('Finding valid license bytes')
for i in range(len(groups)):
    log.status_append('\n%2d:' % i)
    for x in range(256):
        xs = xor(groups[i], x)
        if all(x in string.printable for x in xs):
            log.status_append(' ' + enhex(x))
log.succeeded()
```
